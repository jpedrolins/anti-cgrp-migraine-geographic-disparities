#!/usr/bin/env Rscript
# Figure 4 (v3): socioeconomic gradients in burden-adjusted participation,
# one 2 x 2 figure with identical panel styling:
#   a, Human Development Index; b, GDP per capita (PPP); c, HAQ Index;
#   d, R&D expenditure. (v2 had split c-d into a supplementary figure; the
#   investigator reverted to a single four-panel figure on 17 November 2026.)
#
# Graphical refinement of the four-panel build_figure_4panel.R (kept unchanged).
# The negative binomial models are refitted with the identical specification
# (outcome: country-trial participations; offset: log expected participations
# from GBD 2023 YLDs; HC3 covariance; Wald 95% CIs) and must reproduce the
# validated estimates before anything is drawn.
#
# Requires the reviewed external inputs (see DATA_ACCESS.md). Run inside a full
# reproduction directory, e.g. the output of
#   run_analysis.py --output <dir> --external-inputs <inputs> --figures
# or:
#   Rscript figure4_socioeconomic.R <full_reproduction_dir> [output_dir]

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(ggplot2); library(ggrepel); library(patchwork)
  library(MASS); library(sandwich); library(jsonlite)
})
select <- dplyr::select

script_dir <- local({
  f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
  if (length(f)) dirname(normalizePath(f)) else getwd()
})
source(file.path(script_dir, "figure_theme.R"))

args <- commandArgs(trailingOnly = TRUE)
src <- normalizePath(if (length(args) >= 1) args[1] else ".", mustWork = TRUE)
out <- if (length(args) >= 2) args[2] else src
dir.create(out, recursive = TRUE, showWarnings = FALSE)
out <- normalizePath(out)

fail <- function(msg) stop("Validation failed: ", msg, call. = FALSE)

# ---------------------------------------------------------------------------
# 1. Inputs
# ---------------------------------------------------------------------------
d <- read.csv(file.path(src, "results/country_analytic_with_yld_bounds_v1.csv"), check.names = FALSE)
cv <- read.csv(file.path(src, "covariates_haq_rd.csv"))
who_regions <- read.csv(file.path(src, "source_data/who_regions.csv"))
oe_public <- read_csv(file.path(src, "results/country_expected_oe_all_scenarios.csv"),
                      show_col_types = FALSE) |> filter(scenario == "Point")
ref_nb <- read.csv(file.path(src, "results/negative_binomial_models_all_scenarios.csv"))
ref_haq_rd <- read.csv(file.path(src, "results/bounding_haq_rd.csv"))
table3 <- read_csv(file.path(src, "results/native_document_tables/manuscript_table_06.csv"),
                   show_col_types = FALSE)

checks <- list()

# (1)(5)(6) O/E values, identifiers and exact zeros
if (nrow(d) != 194 || anyDuplicated(d$ISO3)) fail("country universe")
if (!all(grepl("^[A-Z]{3}$", d$ISO3))) fail("ISO3 identifiers")
m <- match(d$ISO3, oe_public$ISO3)
if (anyNA(m)) fail("countries missing from the public O/E file")
if (max(abs(d$oe_point - oe_public$oe[m])) > 1e-12 ||
    any(d$observed != oe_public$observed[m]) ||
    max(abs(d$expected_point - oe_public$expected[m])) > 1e-9) fail("O/E differs from public results")
if (max(abs(d$oe_point - d$observed / d$expected_point)) > 1e-12) fail("O/E != observed/expected")
if (any((d$observed == 0) != (d$oe_point == 0))) fail("zero participations not exactly O/E = 0")
checks$oe_matches_public_results <- TRUE
checks$exact_zero_countries <- sum(d$oe_point == 0)

# WHO region (the analysis file's who_region, cross-checked against the
# official membership list in source_data/who_regions.csv).
d$region <- d$who_region
if (anyNA(d$region) || !all(d$region %in% names(fig_who_region)) ||
    any(d$region != who_regions$who_region[match(d$ISO3, who_regions$country_iso3)]))
  fail("WHO region")

d$hdi <- d[["HDI, period mean"]]
d$gdp <- d[["GDP per capita, PPP-adjusted, period mean"]]
d$haq <- cv$haq_2019[match(d$ISO3, cv$country_iso3)]
d$rd  <- cv$rd_value[match(d$ISO3, cv$country_iso3)]

# ---------------------------------------------------------------------------
# 2. Model specifications (identical to build_figure_4panel.R / analysis.R)
# ---------------------------------------------------------------------------
specs <- list(
  HDI = list(col = "hdi", logx = FALSE, center = 0.8, step = 0.1,
             ref = "HDI per 0.1", ref_file = "nb", t3 = "HDI",
             heading = "Human Development Index",
             xlab = "Human Development Index, period mean",
             irr_text = "IRR per 0.1-unit increase", breaks = seq(0.4, 1, 0.1),
             labels = waiver()),
  GDP = list(col = "gdp", logx = TRUE, center = 20000,
             ref = "GDP per doubling", ref_file = "nb", t3 = "GDP per capita",
             heading = "GDP per capita, PPP",
             xlab = "GDP per capita, PPP (constant 2021 int. $), period mean",
             irr_text = "IRR per doubling",
             breaks = c(1000, 2000, 5000, 10000, 20000, 50000, 100000),
             labels = c("$1k", "$2k", "$5k", "$10k", "$20k", "$50k", "$100k")),
  HAQ = list(col = "haq", logx = FALSE, center = 80, step = 10,
             ref = "HAQ per 10 points", ref_file = "haq_rd", t3 = "HAQ Index",
             heading = "Healthcare Access and Quality Index",
             xlab = "HAQ Index, 2019 (age-standardized)",
             irr_text = "IRR per 10-point increase", breaks = seq(20, 100, 10),
             labels = waiver()),
  RD = list(col = "rd", logx = TRUE, center = 1,
            ref = "R&D per doubling", ref_file = "haq_rd", t3 = "R&D expenditure",
            heading = "Research and development expenditure",
            xlab = "R&D expenditure, % of GDP (year closest to 2019)",
            irr_text = "IRR per doubling",
            breaks = c(0.01, 0.03, 0.1, 0.3, 1, 3),
            labels = c("0.01%", "0.03%", "0.1%", "0.3%", "1%", "3%"))
)

fit_model <- function(s) {
  p <- d[is.finite(d[[s$col]]), ]
  p$xvar <- p[[s$col]]
  scl <- function(x) if (s$logx) log2(x / s$center) else (x - s$center) / s$step
  p$predictor <- scl(p$xvar)
  fit <- glm.nb(observed ~ predictor + offset(log(expected_point)), data = p,
                control = glm.control(maxit = 1000))
  vc <- vcovHC(fit, type = "HC3")
  z <- qnorm(0.975)
  b <- coef(fit)[[2]]; se <- sqrt(vc[2, 2])
  est <- c(IRR = exp(b), lower = exp(b - z * se), upper = exp(b + z * se))
  pval <- 2 * pnorm(-abs(b / se))

  # Reference estimates (point-YLD scenario only)
  r <- if (s$ref_file == "nb") {
    x <- ref_nb[ref_nb$scenario == "Point" & ref_nb$model == s$ref, ]
    c(x$IRR, x$wald_lower_95, x$wald_upper_95, x$n_countries)
  } else {
    x <- ref_haq_rd[ref_haq_rd$scenario == "point" & ref_haq_rd$model == s$ref, ]
    c(x$IRR, x$wald_lower_95, x$wald_upper_95, x$n_countries)
  }
  if (length(r) != 4) fail(paste("reference row for", s$ref))
  # (2)(3)(4) IRR, CI and n reproduce the validated outputs
  if (max(abs(est - r[1:3])) > 1e-6 || nrow(p) != r[4]) fail(paste("model", s$ref))

  # (7) the curve is the model's fitted mean on the O/E scale:
  # E[count]/expected = exp(b0 + b1 * predictor), so fitted / expected must
  # equal exp(linear predictor without the offset) at every country.
  eta_x <- drop(cbind(1, p$predictor) %*% coef(fit))
  if (max(abs(fitted(fit) / p$expected_point - exp(eta_x))) > 1e-8)
    fail(paste("curve/model correspondence", s$ref))

  # Curve and 95% confidence band for the fitted mean (HC3, Wald, log link)
  g <- if (s$logx) 2^seq(log2(min(p$xvar)), log2(max(p$xvar)), length.out = 300) else
    seq(min(p$xvar), max(p$xvar), length.out = 300)
  X <- cbind(1, scl(g))
  eta <- drop(X %*% coef(fit))
  se_eta <- sqrt(rowSums((X %*% vc) * X))
  curve <- data.frame(xvar = g, fit = exp(eta), lo = exp(eta - z * se_eta),
                      hi = exp(eta + z * se_eta))
  # (8) band uses the same HC3 matrix as the reported CI: at predictor = 0 its
  # half-width on the log scale equals z * sqrt(vc[1, 1]).
  se0 <- sqrt(drop(c(1, 0) %*% vc %*% c(1, 0)))
  if (abs(se0 - sqrt(vc[1, 1])) > 1e-12) fail("band covariance")

  list(spec = s, data = p, fit = fit, est = est, p = pval, n = nrow(p),
       n_with_trial = sum(p$observed > 0), participations = sum(p$observed),
       theta = fit$theta, curve = curve)
}
M <- lapply(specs, fit_model)

# (2) reconciliation with the published indicator table (rounded values): file manuscript_table_06.csv,
#     formerly manuscript Table 4, now Supplementary Table S11
for (k in names(M)) {
  row <- table3[grepl(M[[k]]$spec$t3, table3[[1]], fixed = TRUE), ]
  if (nrow(row) != 1) fail(paste("Table 3 row for", k))
  irr_txt <- row[[ncol(row)]]
  want <- sprintf("%.2f (%.2f–%.2f)", M[[k]]$est[1], M[[k]]$est[2], M[[k]]$est[3])
  n_txt <- as.integer(sub(" .*", "", row[[3]]))
  if (irr_txt != want || n_txt != M[[k]]$n) fail(paste("Table 3 mismatch for", k))
}
checks$table3_reconciled <- TRUE

# ---------------------------------------------------------------------------
# 3. Display scale: log10 O/E for positive values, separate strip for zeros
# ---------------------------------------------------------------------------
# Positive O/E ratios are drawn on a log10 axis. O/E = 0 cannot be placed on a
# log axis, so zero-participation countries are drawn in a separate strip below
# a visible gap. Their vertical position inside the strip is a deterministic
# display offset only (it reduces overplotting and has no value); the data and
# models use the exact zeros.
pos_all <- unlist(lapply(M, function(x) x$data$oe_point[x$data$oe_point > 0]))
y_lo <- log10(0.035); y_hi <- log10(100)
if (min(pos_all) < 10^y_lo || max(pos_all) > 10^y_hi) fail("positive O/E outside axis range")
gap <- 0.24; half <- 0.17
y_zero <- y_lo - gap - half
y_breaks <- c(y_zero, log10(c(0.05, 0.1, 0.5, 1, 5, 10, 50)))
y_labels <- c("0", "0.05", "0.1", "0.5", "1", "5", "10", "50")

set.seed(20261117)
zero_offset <- setNames(runif(nrow(d), -0.75 * half, 0.75 * half), sort(d$ISO3))

size_limits <- range(d$expected_point)
size_range <- c(0.9, 3.8)   # mm, sqrt scale; shared by points and label repulsion
# Countries labelled per criterion (default 5, chosen by the investigator on
# 17 November 2026; FIG4_LABELS_PER_GROUP overrides).
n_lab <- as.integer(Sys.getenv("FIG4_LABELS_PER_GROUP", "5"))
label_rule <- function(p) {
  bind_rows(
    p |> filter(oe_point > 0) |> arrange(desc(oe_point), ISO3) |> slice_head(n = n_lab) |>
      mutate(label_reason = sprintf("%d highest O/E", n_lab)),
    p |> filter(oe_point > 0) |> arrange(oe_point, ISO3) |> slice_head(n = n_lab) |>
      mutate(label_reason = sprintf("%d lowest positive O/E", n_lab)),
    p |> filter(oe_point == 0) |> arrange(desc(expected_point), ISO3) |> slice_head(n = n_lab) |>
      mutate(label_reason = sprintf("%d highest expected counts with O/E = 0", n_lab))
  ) |> distinct(ISO3, .keep_all = TRUE) |> select(ISO3, label_reason)
}

fmt_ci <- function(e) sprintf("%.2f (95%% CI %.2f–%.2f)", e[1], e[2], e[3])
fmt_p <- function(p) if (p < 0.001) "P < 0.001" else sprintf("P = %.3f", p)

draw <- function(mod, tag, show_y = TRUE) {
  s <- mod$spec
  p <- mod$data |>
    mutate(y = ifelse(oe_point > 0, log10(oe_point), y_zero + zero_offset[ISO3]),
           region = factor(region, levels = names(fig_who_region)))
  labs_d <- label_rule(p)
  p$label_reason <- labs_d$label_reason[match(p$ISO3, labs_d$ISO3)]
  # Positive-scale label layer: every positive point is included (unlabelled
  # ones with an empty label) so labels are pushed off all points, plus an
  # invisible grid over the model annotation so labels avoid that text.
  # point.size mirrors the plotted bubble size (same sqrt scale and range) so
  # labels clear the full outline of large points.
  psize <- function(e) scales::rescale(sqrt(e), to = size_range, from = sqrt(size_limits))
  lab_pos <- p |> filter(oe_point > 0) |>
    mutate(lab = ifelse(is.na(label_reason), "", ISO3), psize = psize(expected_point))
  lab_zero <- p |> filter(!is.na(label_reason), oe_point == 0)

  # Curve and band, restricted to the positive part of the axis so they never
  # enter the zero strip; the clipped segments are stated in the caption.
  cv <- mod$curve |>
    mutate(f = log10(fit), l = pmax(log10(lo), y_lo), h = pmin(log10(hi), y_hi))
  band <- cv |> filter(h > y_lo, l < y_hi)
  line <- cv |> filter(f >= y_lo, f <= y_hi)

  # Exact x limits (no -Inf on log scales).
  xr <- range(p$xvar)
  xlim <- if (s$logx) xr * c(0.8, 1.2) else xr + c(-1, 1) * 0.04 * diff(xr)
  ann_x <- if (s$logx) xlim[1] * 1.12 else xlim[1] + 0.02 * diff(xlim)
  xscale <- if (s$logx) scale_x_log10(breaks = s$breaks, labels = s$labels) else
    scale_x_continuous(breaks = s$breaks, labels = s$labels)
  ann_frac <- 0.46                        # annotation block: share of panel width
  ann_xs <- if (s$logx) exp(seq(log(xlim[1]), log(xlim[1]) + ann_frac * diff(log(xlim)),
                                length.out = 7)) else
    seq(xlim[1], xlim[1] + ann_frac * diff(xlim), length.out = 7)
  ann_block <- expand.grid(xvar = ann_xs, y = seq(y_hi - 0.62, y_hi - 0.02, length.out = 5)) |>
    mutate(lab = "", psize = 0.4)
  curve_pts <- line[seq(1, nrow(line), by = 8), ] |> transmute(xvar, y = f, lab = "", psize = 0.4)
  lab_pos <- bind_rows(lab_pos |> select(xvar, y, lab, psize), ann_block, curve_pts)
  lab_zero <- lab_zero |> mutate(psize = psize(expected_point))
  # Labels: bold ISO3 codes with a white halo and darker, slightly heavier
  # leader lines, so they read clearly against points, band and gridlines.
  repel <- list(family = fig_font, fontface = "bold", size = fig_size$note / .pt,
                colour = fig_col$ink, seed = 20261117, min.segment.length = 0,
                segment.size = 0.28, segment.colour = "#4A5462", max.overlaps = Inf,
                bg.color = "white", bg.r = 0.16)

  ggplot(p, aes(xvar, y)) +
    # zero strip, gridlines on the positive scale only, O/E = 1 reference
    annotate("rect", xmin = xlim[1], xmax = xlim[2], ymin = y_zero - half,
             ymax = y_zero + half, fill = "#F1F2F4", colour = NA) +
    geom_hline(yintercept = log10(c(0.05, 0.1, 0.5, 5, 10, 50)), colour = fig_col$grid,
               linewidth = 0.2) +
    geom_hline(yintercept = 0, linetype = "22", colour = fig_col$muted,
               linewidth = fig_lwd$ref) +
    geom_ribbon(data = band, aes(x = xvar, ymin = l, ymax = h), inherit.aes = FALSE,
                fill = fig_navy[1], alpha = 0.75) +
    geom_point(aes(fill = region, size = expected_point), shape = 21,
               colour = "white", stroke = 0.2, alpha = 0.9) +
    # labelled countries get a thin dark ring so they can be found among others
    geom_point(data = p |> filter(!is.na(label_reason)), aes(size = expected_point),
               shape = 21, fill = NA, colour = fig_col$ink, stroke = 0.4) +
    geom_line(data = line, aes(x = xvar, y = f), inherit.aes = FALSE,
              colour = fig_pair[["observed"]], linewidth = 0.55) +
    do.call(geom_text_repel, c(list(data = lab_pos, mapping = aes(label = lab, point.size = psize),
                                    ylim = c(y_lo + 0.05, y_hi - 0.02), box.padding = 0.4,
                                    point.padding = 0.25, force = 3, force_pull = 0.5,
                                    max.time = 3, max.iter = 50000), repel)) +
    do.call(geom_text_repel, c(list(data = lab_zero, mapping = aes(label = ISO3, point.size = psize),
                                    # labels sit in the gap above the zero strip
                                    ylim = c(y_zero + half + 0.02, y_lo - 0.02), direction = "x",
                                    box.padding = 0.15, point.padding = 0.05), repel)) +
    # broken y axis: one segment for the positive log scale, one for the strip
    annotate("segment", x = xlim[1], xend = xlim[1], y = y_lo, yend = y_hi,
             colour = fig_col$rule, linewidth = fig_lwd$axis) +
    annotate("segment", x = xlim[1], xend = xlim[1], y = y_zero - half, yend = y_zero + half,
             colour = fig_col$rule, linewidth = fig_lwd$axis) +
    # compact model annotation in the empty upper-left corner
    annotate("text", x = ann_x, y = y_hi - 0.05, hjust = 0, vjust = 1, lineheight = 1.1,
             family = fig_font, size = fig_size$text / .pt, colour = fig_col$ink,
             label = sprintf("%s\n%s\nn = %d countries", s$irr_text, fmt_ci(mod$est), mod$n)) +
    scale_fill_manual(values = fig_who_region, name = "WHO region", drop = FALSE) +
    scale_size_continuous(trans = "sqrt", range = size_range, limits = size_limits,
                          breaks = c(1, 2, 5, 10, 20, 50), name = "Expected participations") +
    scale_y_continuous(breaks = y_breaks, labels = y_labels, expand = c(0, 0)) +
    xscale +
    coord_cartesian(xlim = xlim, ylim = c(y_zero - half, y_hi), expand = FALSE, clip = "on") +
    labs(x = s$xlab, y = if (show_y) "Observed-to-expected ratio" else NULL) +
    fig_heading(tag, s$heading) +
    theme_fig() +
    theme(axis.line = element_blank(),
          axis.line.x = element_line(colour = fig_col$rule, linewidth = fig_lwd$axis),
          axis.ticks.y = element_line(colour = fig_col$rule, linewidth = fig_lwd$axis),
          axis.title.x = element_text(size = fig_size$title, margin = margin(t = 1.5, unit = "mm")),
          axis.title.y = element_text(size = fig_size$title, angle = 90,
                                      margin = margin(r = 1.5, unit = "mm")),
          legend.title = element_text(size = fig_size$text, colour = fig_col$muted),
          legend.text = element_text(size = fig_size$text),
          legend.key.size = unit(3.2, "mm"), legend.spacing.x = unit(1, "mm"),
          plot.margin = margin(1, 3, 1, 0, "mm")) +
    fig_heading_theme() +
    guides(fill = guide_legend(order = 1, nrow = 1,
                               override.aes = list(size = 2.6, alpha = 1, colour = "white")),
           size = guide_legend(order = 2, nrow = 1,
                               override.aes = list(fill = "#9AA3AE", colour = "white", alpha = 1)))
}

# Shared legend below all panels (two rows: region colours, point size).
compose <- function(a, b, c, d) {
  ((a | b) / (c | d)) + plot_layout(guides = "collect") +
    plot_annotation(theme = theme(plot.margin = margin(2, 1.5, 1.5, 1.5, "mm"))) &
    theme(legend.position = "bottom", legend.justification = "left",
          legend.box = "vertical", legend.box.just = "left",
          legend.spacing.y = unit(0.5, "mm"), legend.margin = margin(0, 0, 0, 0),
          plot.background = element_rect(fill = fig_col$paper, colour = NA))
}

width_mm <- fig_width[["double"]]
height_mm <- 190
fig4 <- compose(draw(M$HDI, "a"), draw(M$GDP, "b", show_y = FALSE),
                draw(M$HAQ, "c"), draw(M$RD, "d", show_y = FALSE))

# (9)(10) conventions identical across panels and figures: same y transform,
# limits, breaks, zero strip, size limits and colour map (single draw()).
checks$shared_display <- list(y_positive_range = 10^c(y_lo, y_hi), zero_strip_centre = y_zero,
                              y_breaks = y_labels, size_limits = size_limits)

stem4 <- file.path(out, "figure4", "Figure_4_socioeconomic_v3")
files4 <- fig_save(fig4, stem4, width_mm, height_mm)

# ---------------------------------------------------------------------------
# 4. Plot data and validation (no third-party covariate values are written;
#    see DATA_ACCESS.md)
# ---------------------------------------------------------------------------
sha256 <- function(f) sub(" .*", "", system2("shasum", c("-a", "256", shQuote(f)), stdout = TRUE))
model_summary <- function(k) {
  x <- M[[k]]
  list(model = x$spec$ref, n_countries = x$n, countries_with_participation = x$n_with_trial,
       participations = x$participations, IRR = unname(x$est[1]),
       wald_lower_95 = unname(x$est[2]), wald_upper_95 = unname(x$est[3]), p = x$p,
       theta = x$theta, labelled = label_rule(x$data)$ISO3)
}
write_out <- function(stem, keys, files, figure) {
  pd <- bind_rows(lapply(keys, function(k) {
    x <- M[[k]]
    lr <- label_rule(x$data)
    x$data |>
      transmute(model = x$spec$ref, ISO3, country = Country, who_region = region, observed,
                expected = expected_point, oe = oe_point,
                zero_strip_display_offset = ifelse(oe_point == 0, zero_offset[ISO3], NA),
                label_reason = lr$label_reason[match(ISO3, lr$ISO3)])
  }))
  write_csv(pd, paste0(stem, "_plot_data.csv"), na = "")
  write_json(list(
    figure = figure, generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    scope = "Graphical refinement; models refitted with the validated specification and checked against reference outputs.",
    models = lapply(setNames(keys, keys), model_summary),
    validation = checks,
    export = list(width_mm = width_mm, height_mm = height_mm, png_dpi = fig_dpi, font = fig_font),
    input_sha256 = list(
      country_analytic = sha256(file.path(src, "results/country_analytic_with_yld_bounds_v1.csv")),
      covariates_haq_rd = sha256(file.path(src, "covariates_haq_rd.csv")),
      who_regions = sha256(file.path(src, "source_data/who_regions.csv")),
      nb_reference = sha256(file.path(src, "results/negative_binomial_models_all_scenarios.csv")),
      haq_rd_reference = sha256(file.path(src, "results/bounding_haq_rd.csv"))),
    output_sha256 = as.list(setNames(vapply(files, sha256, ""), basename(files)))
  ), paste0(stem, "_validation.json"), auto_unbox = TRUE, pretty = TRUE, digits = NA)
}
write_out(stem4, c("HDI", "GDP", "HAQ", "RD"), files4, "Figure 4 v3")

for (k in names(M)) cat(sprintf("%-3s IRR %s; n = %d\n", k, fmt_ci(M[[k]]$est), M[[k]]$n))
cat("Wrote:", files4, sep = "\n  ")
