# Table 3 and exploratory adjusted model: country-level indicators and anti-CGRP trial participation.
# Run from the analysis release root:  LC_ALL=C.UTF-8 Rscript table3_covariates.R
# Inputs : results/country_analytic_with_yld_bounds_v1.csv (194 WHO Member States, GBD 2023 YLDs for 2023)
#          covariates_haq_rd.csv (HAQ Index 2019; R&D expenditure, year closest to 2019 within 2015-2023)
# Outputs: table3_covariates.csv, adjusted_hdi_rd.csv, table3_covariates_audit.json
suppressPackageStartupMessages({ library(MASS); library(sandwich); library(jsonlite) })
d  <- read.csv("results/country_analytic_with_yld_bounds_v1.csv", check.names = FALSE)
cv <- read.csv("covariates_haq_rd.csv")
stopifnot(nrow(d) == 194, sum(d$observed) == 453, sum(d$observed > 0) == 47, nrow(cv) == 194)
d$any    <- as.integer(d$observed > 0)
d$hdi_raw <- d[["HDI, period mean"]]
d$gdp_raw <- d[["GDP per capita, PPP-adjusted, period mean"]]
d$haq_raw <- cv$haq_2019[match(d$ISO3, cv$country_iso3)]
d$rd_raw  <- cv$rd_value[match(d$ISO3, cv$country_iso3)]
# Regression contrasts (centering does not change slopes)
d$hdi <- (d$hdi_raw - 0.8) / 0.1          # per 0.1 HDI
d$gdp <- log2(d$gdp_raw / 20000)          # per doubling
d$haq <- (d$haq_raw - 80) / 10            # per 10 points
d$rd  <- log2(d$rd_raw / 1)               # per doubling
labels <- c(hdi = "HDI (per 0.1)", gdp = "GDP per capita, PPP (per doubling)",
            haq = "HAQ Index (per 10 points)", rd = "R&D expenditure, % of GDP (per doubling)")
fmt <- function(e, lo, hi) sprintf("%.2f (%.2f–%.2f)", e, lo, hi)
# Bootstrap CIs for Spearman rho (2000 resamples of countries). The random-number stream follows the
# original exploratory script (cor_part.R), which drew, for each indicator in turn, bootstrap samples for
# rho with participation counts, rho with O/E, the AUC, rho with O/E among participating countries, and
# rho with O/E in the common sample; the same sequence is consumed here so the published CIs are reproduced.
set.seed(20261113)
boot_spearman <- function(x, y, B = 2000) {
  n <- length(x)
  quantile(replicate(B, { i <- sample.int(n, n, TRUE); suppressWarnings(cor(x[i], y[i], method = "spearman")) }),
           c(.025, .975), na.rm = TRUE)
}
auc <- function(x, y) { r <- rank(x); n1 <- sum(y == 1); n0 <- sum(y == 0); (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0) }
auc_boot <- function(x, y, B = 2000) { n <- length(x)
  invisible(replicate(B, { i <- sample.int(n, n, TRUE); if (length(unique(y[i])) < 2) NA else auc(x[i], y[i]) })) }
cm_all <- complete.cases(d[, c("hdi", "gdp", "haq", "rd")])
spearman_ci <- list()
for (v in c("hdi", "gdp", "haq", "rd")) {
  w <- is.finite(d[[v]]); x <- d[[v]][w]
  invisible(boot_spearman(x, d$observed[w]))
  spearman_ci[[v]] <- boot_spearman(x, d$oe_point[w])
  auc_boot(x, d$any[w])
  wp <- w & d$any == 1; invisible(boot_spearman(d[[v]][wp], d$oe_point[wp]))
  invisible(boot_spearman(d[[v]][cm_all], d$oe_point[cm_all]))
}
rows <- lapply(names(labels), function(v) {
  z <- d[is.finite(d[[v]]), ]
  s  <- cor.test(z[[paste0(v, "_raw")]], z$oe_point, method = "spearman", exact = FALSE)
  sc <- spearman_ci[[v]]
  lg <- glm(as.formula(paste("any ~", v)), family = binomial, data = z)
  bl <- coef(lg)[[2]]; sl <- sqrt(vcov(lg)[2, 2])
  nb <- glm.nb(as.formula(paste("observed ~", v, "+ offset(log(expected_point))")), data = z,
               control = glm.control(maxit = 1000))
  bn <- coef(nb)[[2]]; sn <- sqrt(vcovHC(nb, type = "HC3")[2, 2])
  data.frame(indicator = labels[[v]], countries = nrow(z), with_trials = sum(z$any),
             participations = sum(z$observed),
             spearman = fmt(s$estimate, sc[1], sc[2]), p_spearman = s$p.value,
             OR = fmt(exp(bl), exp(bl - 1.96 * sl), exp(bl + 1.96 * sl)), p_OR = 2 * pnorm(-abs(bl / sl)),
             IRR = fmt(exp(bn), exp(bn - 1.96 * sn), exp(bn + 1.96 * sn)), p_IRR = 2 * pnorm(-abs(bn / sn)),
             theta = nb$theta, check.names = FALSE)
})
tab <- do.call(rbind, rows)
write.csv(tab, "table3_covariates.csv", row.names = FALSE)
print(tab[, c("indicator", "countries", "with_trials", "spearman", "OR", "IRR")], row.names = FALSE)

# Exploratory mutual adjustment: HDI and log2 R&D, both per 1 SD, in countries with all four indicators
cm <- d[complete.cases(d[, c("hdi", "gdp", "haq", "rd")]), ]
cm$z_hdi <- as.numeric(scale(cm$hdi_raw)); cm$z_rd <- as.numeric(scale(cm$rd))
lg2 <- glm(any ~ z_hdi + z_rd, family = binomial, data = cm); sl2 <- summary(lg2)$coefficients
nb2 <- glm.nb(observed ~ z_hdi + z_rd + offset(log(expected_point)), data = cm, control = glm.control(maxit = 1000))
vc2 <- vcovHC(nb2, type = "HC3")
adj <- data.frame(term = c("HDI (per SD)", "R&D expenditure, log2 (per SD)"),
  OR  = fmt(exp(sl2[-1, 1]), exp(sl2[-1, 1] - 1.96 * sl2[-1, 2]), exp(sl2[-1, 1] + 1.96 * sl2[-1, 2])),
  p_OR = sl2[-1, 4],
  IRR = fmt(exp(coef(nb2)[-1]), exp(coef(nb2)[-1] - 1.96 * sqrt(diag(vc2))[-1]), exp(coef(nb2)[-1] + 1.96 * sqrt(diag(vc2))[-1])),
  p_IRR = 2 * pnorm(-abs(coef(nb2)[-1] / sqrt(diag(vc2))[-1])))
write.csv(adj, "adjusted_hdi_rd.csv", row.names = FALSE)
cat("\nCommon sample: n =", nrow(cm), "countries,", sum(cm$any), "with trials,", sum(cm$observed), "participations\n")
print(adj, row.names = FALSE)
z4 <- c("hdi", "gdp", "haq", "rd")
vif4 <- sapply(z4, function(v) 1 / (1 - summary(lm(as.formula(paste(v, "~", paste(setdiff(z4, v), collapse = "+"))), data = cm))$r.squared))
rho <- cor(d[, c("hdi_raw", "gdp_raw", "haq_raw", "rd_raw")], method = "spearman", use = "pairwise.complete.obs")
cat("\nVIF, four indicators together:\n"); print(round(vif4, 1))
cat("VIF, HDI + R&D:", round(1 / (1 - cor(cm$z_hdi, cm$z_rd)^2), 2), "\n")
cat("\nSpearman correlations among indicators (pairwise):\n"); print(round(rho, 2))
write_json(list(common_sample = list(n = nrow(cm), with_trials = sum(cm$any), participations = sum(cm$observed)),
                vif_all4 = as.list(round(vif4, 2)), vif_hdi_rd = round(1 / (1 - cor(cm$z_hdi, cm$z_rd)^2), 2),
                spearman_indicators = round(rho, 3), bootstrap = list(B = 2000, seed = 20261113)),
           "table3_covariates_audit.json", auto_unbox = TRUE, pretty = TRUE)
