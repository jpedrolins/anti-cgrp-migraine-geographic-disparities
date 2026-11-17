# Four-panel figure: HDI, GDP per capita, HAQ Index and R&D expenditure; same models and plot code as Figure 4.
# Reuses the original S3 (linear x) and S4 (log2 x) plot expressions with only the
# x variable, axis title/breaks and annotation offset substituted.
suppressPackageStartupMessages({
  library(ggplot2); library(ggrepel); library(dplyr); library(MASS)
  library(sandwich); library(patchwork); library(jsonlite)
})
out <- normalizePath(".", mustWork = TRUE)
d <- read.csv(file.path(out, "results/country_analytic_with_yld_bounds_v1.csv"), check.names = FALSE)
mapping <- read.csv(file.path(out, "source/region_plot_mapping.csv"))
cv <- read.csv(file.path(out, "covariates_haq_rd.csv"))
stopifnot(nrow(d) == 194, sum(d$observed) == 453, sum(d$observed > 0) == 47)
d$world_region <- mapping$world_region[match(d$ISO3, mapping$country_iso3)]
# Four Member States lack HDI and are absent from the Figure 4 region map; assign them here.
extra <- c(COK = "Oceania", NIU = "Oceania", MCO = "Europe", PRK = "Asia")
d$world_region[d$ISO3 %in% names(extra)] <- extra[d$ISO3[d$ISO3 %in% names(extra)]]
d$country_iso3 <- d$ISO3
d$trial_country_participations <- d$observed
d$expected_participations <- d$expected_point
d$observed_to_expected_ratio <- d$oe_point
d$oe_plot_scale <- log10(1 + d$oe_point)
d$haq <- cv$haq_2019[match(d$ISO3, cv$country_iso3)]
d$rd <- cv$rd_value[match(d$ISO3, cv$country_iso3)]
d$hdi <- d[["HDI, period mean"]]
d$gdp <- d[["GDP per capita, PPP-adjusted, period mean"]]

src_s3 <- readLines(file.path(out, "source/figureS3_hdi_disproportionality.R"), warn = FALSE)
src_s4 <- readLines(file.path(out, "source/figureS4_gdp_disproportionality.R"), warn = FALSE)
grab <- function(lines, pat) {
  s <- grep(pat, lines); e <- grep("^png_file <-", lines); stopifnot(length(s) == 1, length(e) == 1)
  lines[s:(e - 1)]
}
fmt_p <- function(p) if (p < 0.001) "P < .001" else sprintf("P = %s", sub("^0", "", sprintf("%.3f", p)))

make_panel <- function(kind) {
  spec <- list(
    HDI = list(col = "hdi", logx = FALSE, center = 0.8, step = 0.1, src = "s3", descriptor = "per 0.1-unit HDI increase",
               title = "Human Development Index, period mean", breaks = NULL),
    GDP = list(col = "gdp", logx = TRUE, center = 20000, src = "s4", descriptor = "per doubling of GDP per capita",
               title = "GDP per capita, PPP (constant 2021 int. $), period mean", breaks = NULL),
    HAQ = list(col = "haq", logx = FALSE, center = 80, step = 10, src = "s3", descriptor = "per 10-point HAQ Index increase",
               title = "HAQ Index, 2019 (age-standardized)", breaks = "seq(10, 100, by = 10)"),
    RD  = list(col = "rd", logx = TRUE, center = 1, src = "s4", descriptor = "per doubling of R&D expenditure",
               title = "R&D expenditure, % of GDP (year closest to 2019)", breaks = "c(0.01, 0.03, 0.1, 0.3, 1, 3)",
               labels = 'c("0.01%", "0.03%", "0.1%", "0.3%", "1%", "3%")'))[[kind]]
  p <- d[is.finite(d[[spec$col]]), ]
  p$xvar <- p[[spec$col]]
  p$world_region <- factor(p$world_region, levels = c("Africa", "Asia", "Europe", "North America",
                                                      "Latin America and the Caribbean", "Oceania"))
  stopifnot(!anyNA(p$world_region))
  scl <- function(x) if (spec$logx) log2(x / spec$center) else (x - spec$center) / spec$step
  p$predictor <- scl(p$xvar)
  fit <- glm.nb(trial_country_participations ~ predictor + offset(log(expected_participations)),
                data = p, control = glm.control(maxit = 1000))
  vc <- vcovHC(fit, type = "HC3")
  beta <- coef(fit)[[2]]; se <- sqrt(vc[2, 2]); z <- qnorm(.975)
  vals <- exp(c(beta, beta - z * se, beta + z * se)); pval <- 2 * pnorm(-abs(beta / se))
  g <- if (spec$logx) 2^seq(log2(min(p$xvar)), log2(max(p$xvar)), length.out = 250) else seq(min(p$xvar), max(p$xvar), length.out = 250)
  design <- cbind(1, scl(g)); lin <- drop(design %*% coef(fit))
  predse <- sqrt(rowSums((design %*% vc) * design))
  predictions <- data.frame(xvar = g, predicted_plot = log10(1 + exp(lin)),
                            predicted_plot_lower = log10(1 + exp(lin - z * predse)),
                            predicted_plot_upper = log10(1 + exp(lin + z * predse)))
  select <- bind_rows(
    p %>% filter(observed_to_expected_ratio > 0) %>% arrange(desc(observed_to_expected_ratio), country_iso3) %>% slice_head(n = 5) %>% mutate(label_reason = "Five highest O/E ratios"),
    p %>% filter(observed_to_expected_ratio > 0) %>% arrange(observed_to_expected_ratio, country_iso3) %>% slice_head(n = 5) %>% mutate(label_reason = "Five lowest positive O/E ratios"),
    p %>% filter(observed_to_expected_ratio == 0) %>% arrange(desc(expected_participations), country_iso3) %>% slice_head(n = 5) %>% mutate(label_reason = "Five highest expected counts among O/E = 0 countries")
  ) %>% distinct(country_iso3, .keep_all = TRUE)
  p$label_reason <- select$label_reason[match(p$country_iso3, select$country_iso3)]
  p$iso3_label <- ifelse(is.na(p$label_reason), NA, p$country_iso3)
  env <- new.env(parent = globalenv())
  env$plot_data <- p; env$prediction_data <- predictions
  env$label_seed <- 20260815; env$base_font <- "Liberation Sans"
  env$region_colors <- c("Africa" = "#332288", "Asia" = "#DDCC77", "Europe" = "#117733", "North America" = "#88CCEE",
                         "Latin America and the Caribbean" = "#CC6677", "Oceania" = "#AA4499")
  breaks <- c(0, .1, .25, .5, 1, 2, 5, 10, 20, 50)
  env$oe_break_positions <- log10(1 + breaks)
  env$oe_break_labels <- c("0", "0.1", "0.25", "0.5", "1", "2", "5", "10", "20", "50")
  env$model_annotation <- ""   # estimate moved to the panel subtitle to avoid label collisions
  subtitle <- sprintf("Burden-adjusted IRR %s:\n%.2f (95%% CI, %.2f\u2013%.2f); %s; n = %d countries", spec$descriptor, vals[1], vals[2], vals[3], fmt_p(pval), nrow(p))
  if (spec$src == "s3") {
    L <- grab(src_s3, "^figure_s3 <- ggplot\\(")
    L <- gsub("hdi_period_mean", "xvar", L, fixed = TRUE)
    L <- sub('name = "Human Development Index, period mean"', sprintf('name = "%s"', spec$title), L, fixed = TRUE)
    if (!is.null(spec$breaks)) L <- sub("breaks = seq(0.4, 1.0, by = 0.1)", paste0("breaks = ", spec$breaks), L, fixed = TRUE)
    L <- gsub("min(plot_data$xvar) + 0.005", "min(plot_data$xvar) + 0.005 * diff(range(plot_data$xvar)) / 0.6", L, fixed = TRUE)
    obj <- "figure_s3"
  } else {
    L <- grab(src_s4, "^figure_s4 <- ggplot\\(")
    L <- gsub("gdp_pc_ppp_constant_2021_intl_usd_period_mean", "xvar", L, fixed = TRUE)
    L <- gsub("aes(x = gdp,", "aes(x = xvar,", L, fixed = TRUE)
    L <- sub('name = "GDP per capita, PPP, period mean (constant 2021 international $)"', sprintf('name = "%s"', spec$title), L, fixed = TRUE)
    if (!is.null(spec$breaks)) {
      L <- sub("breaks = c(1000, 2000, 5000, 10000, 20000, 50000, 100000),", paste0("breaks = ", spec$breaks, ","), L, fixed = TRUE)
      L <- sub('labels = c("$1k", "$2k", "$5k", "$10k", "$20k", "$50k", "$100k"),', paste0("labels = ", spec$labels, ","), L, fixed = TRUE)
    }
    obj <- "figure_s4"
  }
  L <- sub('direction = "y",', 'direction = "both",', L, fixed = TRUE)
  # Half-width panels: smaller label text and wider spacing so bottom labels do not overlap.
  L <- gsub("size = 2.55,", "size = 2.1,", L, fixed = TRUE)
  L <- gsub("box.padding = 0.24,", "box.padding = 0.32, force = 2,", L, fixed = TRUE)
  L <- gsub("ylim = c(-0.125, -0.035),", "ylim = c(-0.2, -0.03),", L, fixed = TRUE)
  L <- gsub('direction = "x",', 'direction = "both",', L, fixed = TRUE)
  L <- gsub("ylim = c(0.07, 0.24),", "ylim = c(0.06, 0.3),", L, fixed = TRUE)
  L <- gsub("limits = c(-0.14, log10(66)),", "limits = c(-0.21, log10(66)),", L, fixed = TRUE)
  L <- gsub("coord_cartesian(ylim = c(-0.14, log10(66))", "coord_cartesian(ylim = c(-0.21, log10(66))", L, fixed = TRUE)
  stopifnot(!any(grepl("hdi_period_mean|gdp_pc_ppp|aes\\(x = gdp", L)), any(grepl(spec$title, L, fixed = TRUE)))
  eval(parse(text = L), envir = env)
  plot <- get(obj, envir = env) + labs(subtitle = subtitle) +
    theme(plot.subtitle = element_text(size = 7.2, color = "#1F1F1F", margin = margin(b = 3)))
  write.csv(p[, c("country_iso3", "Country", "world_region", "income", "observed", "expected_participations",
                  "observed_to_expected_ratio", "xvar", "label_reason")],
            file.path(out, paste0("panel4_", kind, "_country_data.csv")), row.names = FALSE, na = "")
  list(plot = plot, n = nrow(p), n_with_trial = sum(p$observed > 0), participations = sum(p$observed),
       irr = unname(vals), p = pval, theta = fit$theta, labels = select$country_iso3)
}
P <- lapply(c(HDI = "HDI", GDP = "GDP", HAQ = "HAQ", RD = "RD"), make_panel)
ref <- read.csv(file.path(out, "results/negative_binomial_models_all_scenarios.csv"))
r <- ref[ref$scenario == "Point", ]
stopifnot(max(abs(P$HDI$irr - unlist(r[r$model == "HDI per 0.1", c("IRR", "wald_lower_95", "wald_upper_95")]))) < 1e-6,
          max(abs(P$GDP$irr - unlist(r[r$model == "GDP per doubling", c("IRR", "wald_lower_95", "wald_upper_95")]))) < 1e-6)
size_limits <- range(d$expected_participations)
same_size <- scale_size_continuous(trans = "sqrt", range = c(1.2, 4.2), breaks = c(1, 10, 50),
                                   limits = size_limits, name = "Expected participations")
no_y <- theme(axis.title.y = element_blank())
pa <- P$HDI$plot + same_size + labs(tag = "A"); pb <- P$GDP$plot + same_size + no_y + labs(tag = "B")
pc <- P$HAQ$plot + same_size + labs(tag = "C"); pd <- P$RD$plot + same_size + no_y + labs(tag = "D")
figure <- ((pa | pb) / (pc | pd)) + plot_layout(guides = "collect") &
  theme(legend.position = "bottom", legend.box = "vertical", legend.box.just = "center",
        plot.tag = element_text(face = "bold", size = 13), plot.margin = margin(3, 3, 2, 3, unit = "mm"),
        axis.title = element_text(size = 7.8), axis.text = element_text(size = 7))
ggsave(file.path(out, "Figure_4panel_HDI_GDP_HAQ_RD_draft.png"), figure, width = 170, height = 200, units = "mm", dpi = 300, bg = "white", limitsize = FALSE)
ggsave(file.path(out, "Figure_4panel_HDI_GDP_HAQ_RD_draft.pdf"), figure, width = 170, height = 200, units = "mm", bg = "white", device = cairo_pdf)
audit <- lapply(P, function(x) x[c("n", "n_with_trial", "participations", "irr", "p", "theta", "labels")])
write_json(audit, file.path(out, "figure_4panel_audit.json"), auto_unbox = TRUE, pretty = TRUE, digits = 8)
cat(toJSON(lapply(audit, function(x) x[c("n", "irr")]), auto_unbox = TRUE, digits = 4))
