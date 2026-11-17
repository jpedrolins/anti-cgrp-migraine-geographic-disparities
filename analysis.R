# Reproduce the approved country-record analysis without changing observed counts.
suppressPackageStartupMessages({library(MASS); library(sandwich); library(jsonlite)})
args <- commandArgs(trailingOnly = TRUE)
root <- normalizePath(if (length(args)) args[1] else ".")
cfg <- fromJSON(file.path(root, "config.json"))
input <- function(name) read.csv(file.path(root, "source_data", name), check.names = FALSE)
base <- input("country_dataset.csv")
raw <- read.csv(file.path(root, "source", "IHME-GBD_2023_DATA-96e7c249-1.csv"), check.names = FALSE)
crosswalk <- input("gbd_crosswalk.csv")
regions <- input("who_regions.csv")

# Select number of YLDs, not rates or percentages: both sexes, all ages, migraine.
selected <- rep(TRUE, nrow(raw))
for (field in names(cfg$gbd_filters)) selected <- selected & raw[[field]] == cfg$gbd_filters[[field]]
gbd <- raw[selected, c("location_id", "val", "lower", "upper")]
stopifnot(!anyDuplicated(gbd$location_id), !anyDuplicated(base$ISO3))
map <- crosswalk[crosswalk$country_iso3 %in% base$ISO3, c("gbd_location_id", "country_iso3")]
stopifnot(!anyDuplicated(map$country_iso3), !anyDuplicated(map$gbd_location_id))
gbd <- merge(map, gbd, by.x = "gbd_location_id", by.y = "location_id", all.x = TRUE)
d <- merge(base, gbd, by.x = "ISO3", by.y = "country_iso3", all.x = TRUE, sort = FALSE)
d <- merge(d, regions[, c("country_iso3", "who_region")], by.x = "ISO3", by.y = "country_iso3", all.x = TRUE, sort = FALSE)
d <- d[order(d$ISO3), ]
rownames(d) <- NULL
d$observed <- d[["Country-record participations, n"]]
d$income <- d[["Income group (FY2019)"]]
d$hdi01 <- d[["HDI, period mean"]] * 10
d$gdp2 <- log2(d[["GDP per capita, PPP-adjusted, period mean"]])
stopifnot(nrow(d) == cfg$who_member_states,
          sum(d$observed) == cfg$country_record_participations,
          !anyNA(d[c("val", "lower", "upper", "who_region")]),
          all(d$lower > 0 & d$lower <= d$val & d$val <= d$upper))

# Preserve the 2019 estimate for transparent comparison, not as an equality test.
point_error <- max(abs(d$val - d[["Migraine YLD number, 2019"]]))
stopifnot(is.finite(point_error))

scenarios <- c(Point = "val", Lower = "lower", Upper = "upper")
models <- list(); groups <- list(); countries <- list(); warnings <- character()
model_exclusions <- list()
fit <- function(z, predictor, label, scenario) {
    keep <- is.finite(z[[predictor]]) & is.finite(z$burden) & z$burden > 0
    model_exclusions[[paste(scenario, label)]] <<- z$ISO3[!keep]
    z <- z[keep, ]
    m <- withCallingHandlers(
        glm.nb(as.formula(paste("observed ~", predictor, "+ offset(log(burden))")), data = z,
               control = glm.control(maxit = 1000)),
        warning = function(w) {
            warnings <<- c(warnings, paste(scenario, label, conditionMessage(w)))
            invokeRestart("muffleWarning")
        })
    b <- unname(coef(m)[2])
    se <- unname(sqrt(diag(vcovHC(m, type = cfg$robust_covariance)))[2])
    critical <- qnorm(1 - cfg$alpha / 2)
    data.frame(scenario = scenario, model = label, n_countries = nrow(z),
               IRR = exp(b), wald_lower_95 = exp(b - critical * se),
               wald_upper_95 = exp(b + critical * se), p = 2 * pnorm(-abs(b / se)),
               theta = m$theta, converged = m$converged, status = "Estimated")
}
spec <- list(c("HIC vs UMIC/LMIC/LIC", "Upper-middle income", "Lower-middle income", "Low income"),
             c("HIC vs LMIC/LIC", "Lower-middle income", "Low income"),
             c("HIC vs UMIC", "Upper-middle income"),
             c("HIC vs LMIC", "Lower-middle income"))
for (scenario in names(scenarios)) {
    d$burden <- d[[scenarios[[scenario]]]]
    for (s in spec) {
        z <- d[d$income %in% c("High income", s[-1]), ]
        z$hic <- as.integer(z$income == "High income")
        models[[length(models) + 1]] <- fit(z, "hic", s[1], scenario)
    }
    # No finite HIC-vs-LIC IRR is identifiable when all LIC outcomes are zero.
    z <- d[d$income %in% c("High income", "Low income"), ]
    stopifnot(all(z$observed[z$income == "Low income"] == 0))
    models[[length(models) + 1]] <- data.frame(
        scenario = scenario, model = "HIC vs LIC", n_countries = nrow(z),
        IRR = NA_real_, wald_lower_95 = NA_real_, wald_upper_95 = NA_real_,
        p = NA_real_, theta = NA_real_, converged = NA,
        status = "Not estimable: all LIC outcomes are zero")
    models[[length(models) + 1]] <- fit(d, "hdi01", "HDI per 0.1", scenario)
    models[[length(models) + 1]] <- fit(d, "gdp2", "GDP per doubling", scenario)
    expected <- sum(d$observed) * d$burden / sum(d$burden)
    countries[[scenario]] <- data.frame(
        ISO3 = d$ISO3, Country = d$Country, income = d$income,
        who_region = d$who_region, observed = d$observed,
        yld = d$burden, expected = expected, oe = d$observed / expected,
        scenario = scenario)
    for (dimension in c("income", "who_region")) {
        for (group in unique(d[[dimension]])) {
            z <- d[d[[dimension]] == group, ]
            observed <- sum(z$observed)
            expected <- sum(d$observed) * sum(z$burden) / sum(d$burden)
            groups[[length(groups) + 1]] <- data.frame(
                scenario = scenario, dimension = dimension, group = group,
                n_countries = nrow(z), observed = observed, yld = sum(z$burden),
                expected = expected, oe = observed / expected,
                burden_share = sum(z$burden) / sum(d$burden))
        }
    }
}
models <- do.call(rbind, models)
groups <- do.call(rbind, groups)
country_long <- do.call(rbind, countries)
point <- countries$Point
changes <- list()
for (scenario in c("Lower", "Upper")) {
    z <- countries[[scenario]]
    relative <- abs(z$oe / point$oe - 1)
    relative[point$observed == 0] <- 0
    changes[[scenario]] <- list(
        max_relative_oe_change = max(relative),
        max_abs_expected_change = max(abs(z$expected - point$expected)),
        classification_flips = z$ISO3[(z$oe > 1) != (point$oe > 1)],
        above_one = sum(z$oe > 1), below_one_nonzero = sum(z$oe > 0 & z$oe < 1),
        zero = sum(z$oe == 0), rank_spearman = cor(z$oe, point$oe, method = "spearman"))
}
comparison <- models[models$scenario != "Point", ]
baseline <- models[models$scenario == "Point", ]
j <- match(comparison$model, baseline$model)
comparison$point_IRR <- baseline$IRR[j]
comparison$relative_IRR_change <- comparison$IRR / comparison$point_IRR - 1
comparison$effect_direction_unchanged <- sign(log(comparison$IRR)) == sign(log(comparison$point_IRR))
comparison$significance_unchanged <- (comparison$p < cfg$alpha) == (baseline$p[j] < cfg$alpha)

# Preserve all three estimates and the unchanged observed outcome in a new wide dataset.
analytic <- d[, setdiff(names(d), c("burden", "val", "lower", "upper"))]
analytic$migraine_yld_point_2023 <- d$val
analytic$migraine_yld_lower_2023 <- d$lower
analytic$migraine_yld_upper_2023 <- d$upper
analytic$gbd_release <- cfg$gbd_release
analytic$reference_year <- cfg$reference_year
for (scenario in names(scenarios)) {
    analytic[[paste0("expected_", tolower(scenario))]] <- countries[[scenario]]$expected
    analytic[[paste0("oe_", tolower(scenario))]] <- countries[[scenario]]$oe
}
out <- file.path(root, "results")
dir.create(out, showWarnings = FALSE)
write.csv(analytic, file.path(out, "country_analytic_with_yld_bounds_v1.csv"), row.names = FALSE, na = "")
write.csv(country_long, file.path(out, "country_expected_oe_all_scenarios.csv"), row.names = FALSE)
write.csv(groups, file.path(out, "who_income_expected_oe_all_scenarios.csv"), row.names = FALSE)
write.csv(models, file.path(out, "negative_binomial_models_all_scenarios.csv"), row.names = FALSE, na = "")
write.csv(comparison, file.path(out, "model_comparison_with_point.csv"), row.names = FALSE, na = "")
validation <- list(
    eligible_records = cfg$eligible_records, country_record_participations = sum(d$observed),
    countries = nrow(d), participating_countries = sum(d$observed > 0),
    missing_yld = sum(!is.finite(d$val) | !is.finite(d$lower) | !is.finite(d$upper)),
    max_absolute_change_yld_2019_to_2023 = point_error,
    warnings = warnings, country_changes = changes,
    max_relative_IRR_change = max(abs(comparison$relative_IRR_change), na.rm = TRUE),
    effect_directions_unchanged = all(comparison$effect_direction_unchanged, na.rm = TRUE),
    significance_unchanged = all(comparison$significance_unchanged, na.rm = TRUE),
    all_estimable_models_converged = all(models$converged[models$status == "Estimated"]),
    country_exclusions_by_model = model_exclusions)
write_json(validation, file.path(out, "validation.json"), pretty = TRUE, auto_unbox = TRUE, digits = 15)
capture.output(sessionInfo(), file = file.path(out, "R_session_info.txt"))
stopifnot(validation$all_estimable_models_converged, length(warnings) == 0)
cat(toJSON(validation, pretty = TRUE, auto_unbox = TRUE, digits = 8))
