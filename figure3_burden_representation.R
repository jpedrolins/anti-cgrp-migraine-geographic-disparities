#!/usr/bin/env Rscript
# Figure 3 (v2): representation of anti-CGRP monoclonal antibody trials relative
# to global migraine burden, by WHO region (a) and World Bank income group (b).
#
# Descriptive comparison of each group's share of country-trial participations
# with its share of global migraine YLDs (GBD 2023, year 2023), and the
# observed-to-expected (O/E) ratio. Replaces the income-only build_figure3.R
# (v1, kept unchanged) and adds the WHO-region panel. Reuses the validated
# country-level release; nothing is re-estimated.
#
# Usage (from a directory where public_data_and_reference_results.zip has been
# extracted, e.g. the output of `run_analysis.py --validate-only`):
#   Rscript figure3_burden_representation.R [data_dir] [output_dir]

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(ggplot2); library(patchwork); library(jsonlite)
})

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

# ---------------------------------------------------------------------------
# 1. Inputs (adopted 108-record release; primary cohort only)
# ---------------------------------------------------------------------------
country <- read_csv(file.path(src, "results/country_expected_oe_all_scenarios.csv"),
                    show_col_types = FALSE) |> filter(scenario == "Point")
pairs <- read_csv(file.path(src, "country_record_453.csv"), show_col_types = FALSE)
groups_ref <- read_csv(file.path(src, "results/who_income_expected_oe_all_scenarios.csv"),
                       show_col_types = FALSE) |> filter(scenario == "Point")
table2 <- read_csv(file.path(src, "results/native_document_tables/manuscript_table_04.csv"),
                   show_col_types = FALSE)
income_v1 <- read_csv(file.path(src, "results/figure3_income_data.csv"), show_col_types = FALSE)

region_order <- c("Europe", "Americas", "Western Pacific", "South-East Asia",
                  "Eastern Mediterranean", "Africa")
income_order <- c("High income", "Upper-middle income", "Lower-middle income", "Low income")
income_exception <- "Income group unavailable"
tol <- 1e-9
checks <- list()
fail <- function(msg) stop("Validation failed: ", msg, call. = FALSE)

# ---------------------------------------------------------------------------
# 2. Aggregate from the country level (unrounded)
# ---------------------------------------------------------------------------
# expected_i = total observed x (YLD_i / sum YLD) in the release, so a group's
# YLD share is sum(expected_i) / sum(expected). Absolute YLDs are not
# redistributed in the public repository and are not needed here.
total_obs <- sum(country$observed)
total_exp <- sum(country$expected)

aggregate_by <- function(var) {
  country |>
    group_by(group = .data[[var]]) |>
    summarise(n_countries = n(), observed = sum(observed), expected = sum(expected),
              .groups = "drop") |>
    mutate(observed_share = observed / total_obs,
           yld_share = expected / total_exp,
           oe = observed / expected)
}
region <- aggregate_by("who_region")
income <- aggregate_by("income")

# ---------------------------------------------------------------------------
# 3. Automated quality control
# ---------------------------------------------------------------------------
release_file <- c(file.path(src, "CURRENT_RELEASE.json"), file.path(script_dir, "CURRENT_RELEASE.json"))
release_file <- release_file[file.exists(release_file)][1]

# (1) group counts sum to the primary analytical total; (9) not the 467 dataset
if (sum(region$observed) != total_obs || sum(income$observed) != total_obs) fail("group totals")
if (total_obs != nrow(pairs) || anyDuplicated(pairs[c("study_id", "country_iso3")]))
  fail("observed total differs from the unique pair file")
if (!is.na(release_file)) {
  rel <- fromJSON(release_file)
  if (total_obs != rel$WHO_country_record_pairs) fail("total differs from CURRENT_RELEASE.json")
  checks$release_metadata_agreement <- basename(release_file)
}
checks$primary_total <- total_obs
checks$not_exploratory_benchmark_dataset <- total_obs != 467 && nrow(pairs) == total_obs

# (2) WHO regions: complete, non-overlapping partition of the 194 Member States
if (anyDuplicated(country$ISO3) || nrow(country) != 194) fail("country universe")
if (!setequal(region$group, region_order) || anyNA(country$who_region)) fail("WHO regions")
if (sum(region$n_countries) != nrow(country)) fail("region partition")

# (3) income: complete partition; the only exception is documented
extra_income <- setdiff(income$group, income_order)
if (!identical(extra_income, income_exception) || anyNA(country$income)) fail("income groups")
if (sum(income$n_countries) != nrow(country)) fail("income partition")
exc <- income |> filter(group == income_exception)
exc_countries <- country |> filter(income == income_exception)
if (exc$observed != 0) fail("participations in countries without an income group")
checks$income_exception <- list(group = income_exception,
                                countries = paste(exc_countries$Country, collapse = "; "),
                                observed = exc$observed, yld_share = exc$yld_share)

# (4) YLD aggregation: group expected counts sum to the total; country and
#     group result files agree
if (abs(sum(region$expected) - total_obs) > tol || abs(sum(income$expected) - total_obs) > tol)
  fail("expected counts do not sum to the observed total")

# (5)(6) shares sum to 1 before rounding
checks$observed_share_sum <- c(region = sum(region$observed_share), income = sum(income$observed_share))
checks$yld_share_sum <- c(region = sum(region$yld_share), income = sum(income$yld_share))
if (any(abs(c(checks$observed_share_sum, checks$yld_share_sum) - 1) > tol)) fail("shares")

# (7) O/E agrees with the validated group outputs
compare_ref <- function(agg, dim) {
  m <- inner_join(agg, groups_ref |> filter(dimension == dim), by = "group")
  if (nrow(m) != nrow(agg)) fail(paste("missing reference rows for", dim))
  d <- c(max(abs(m$observed.x - m$observed.y)), max(abs(m$expected.x - m$expected.y)),
         max(abs(m$oe.x - m$oe.y)), max(abs(m$yld_share - m$burden_share)))
  if (any(d > 1e-9) || any(m$n_countries.x != m$n_countries.y)) fail(paste("reference", dim))
  max(d)
}
checks$max_abs_diff_vs_group_results <- c(region = compare_ref(region, "who_region"),
                                          income = compare_ref(income, "income"))

# Observed counts also agree with the pair file's own classification
pair_region <- count(pairs, who_region)
if (!all(region$observed[match(pair_region$who_region, region$group)] == pair_region$n))
  fail("region counts differ from the pair file")

# (8) reconciliation with manuscript Table 2 (regions) and the v1 income data
t2 <- table2 |> filter(`WHO region` %in% region_order) |>
  transmute(group = `WHO region`,
            n = as.integer(sub(" .*", "", `Country-trial participations, n (%)`)),
            pct = as.numeric(sub(".*\\(([0-9.]+)\\).*", "\\1", `Country-trial participations, n (%)`)),
            yld_pct = as.numeric(`Migraine YLDs, %`), expected = as.numeric(`Expected participations, n`),
            oe = as.numeric(`O/E ratio`)) |>
  inner_join(region, by = "group")
if (nrow(t2) != 6 || any(t2$n != t2$observed) ||
    any(t2$pct != round(100 * t2$observed_share, 1)) ||
    any(t2$yld_pct != round(100 * t2$yld_share, 1)) ||
    any(t2$expected.x != round(t2$expected.y, 1)) || any(t2$oe.x != round(t2$oe.y, 2)))
  fail("manuscript Table 2 does not reconcile")
inc1 <- income_v1 |> inner_join(income, by = c(income_group = "group"))
if (nrow(inc1) != 4 ||
    max(abs(inc1$trial_country_participations - 100 * inc1$observed_share)) > 1e-9 ||
    max(abs(inc1$migraine_burden_ylds - 100 * inc1$yld_share)) > 1e-9)
  fail("income shares differ from the v1 Figure 3 data")
checks$manuscript_table2_reconciled <- TRUE
checks$income_v1_figure_data_reconciled <- TRUE

# ---------------------------------------------------------------------------
# 4. Display values (rounding for display only)
# ---------------------------------------------------------------------------
pct_label <- function(x, obs) {
  # One decimal for every nonzero share (smallest displayed: 0.4%); an exact
  # zero is written out as "0 (none)" so it cannot be read as a rounded value.
  ifelse(rep_len(obs == 0, length(x)), "0 (none)",
         paste0(formatC(100 * x, format = "f", digits = 1), "%"))
}
oe_label <- function(oe) formatC(oe, format = "f", digits = 2)

plot_rows <- function(agg, order) {
  agg |> filter(group %in% order) |>
    mutate(group = factor(group, levels = order)) |> arrange(group) |>
    mutate(y = rev(seq_along(group)),
           obs_lab = pct_label(observed_share, observed),
           yld_lab = pct_label(yld_share, 1),
           oe_lab = oe_label(oe))
}
reg_d <- plot_rows(region, region_order)
inc_d <- plot_rows(income, income_order)
x_max <- 100   # same 0-100% scale in both panels; no truncation

# ---------------------------------------------------------------------------
# 5. Drawing
# ---------------------------------------------------------------------------
bar_h <- 0.34   # each bar; the pair occupies 0.68 of the row
gap   <- 0.02
lab_dx <- 1.2
oe_x <- x_max + 13          # right-hand O/E column (outside the data area)

draw_panel <- function(d, show_key = FALSE) {
  obs <- d |> mutate(ymin = y + gap / 2, ymax = y + gap / 2 + bar_h, v = 100 * observed_share)
  ref <- d |> mutate(ymin = y - gap / 2 - bar_h, ymax = y - gap / 2, v = 100 * yld_share)
  n <- nrow(d)
  p <- ggplot() +
    geom_rect(data = ref, aes(xmin = 0, xmax = v, ymin = ymin, ymax = ymax),
              fill = fig_pair[["reference"]]) +
    geom_rect(data = obs, aes(xmin = 0, xmax = v, ymin = ymin, ymax = ymax),
              fill = fig_pair[["observed"]]) +
    # Exact zeros keep a visible hairline at the baseline.
    geom_segment(data = obs[obs$observed == 0, ], aes(x = 0, xend = 0.6, y = (ymin + ymax) / 2,
                 yend = (ymin + ymax) / 2), colour = fig_pair[["observed"]],
                 linewidth = fig_lwd$data) +
    geom_text(data = obs, aes(x = v + lab_dx, y = (ymin + ymax) / 2, label = obs_lab),
              hjust = 0, family = fig_font, size = fig_size$text / .pt,
              fontface = "bold", colour = fig_col$ink) +
    geom_text(data = ref, aes(x = v + lab_dx, y = (ymin + ymax) / 2, label = yld_lab),
              hjust = 0, family = fig_font, size = fig_size$text / .pt,
              colour = fig_col$muted) +
    geom_text(data = d, aes(x = oe_x, y = y, label = oe_lab), hjust = 1,
              family = fig_font, size = fig_size$text / .pt, colour = fig_col$ink) +
    annotate("text", x = oe_x, y = n + 0.62, label = "O/E ratio", hjust = 1, vjust = 0,
             family = fig_font, fontface = "bold", size = fig_size$title / .pt,
             colour = fig_col$ink) +
    geom_vline(xintercept = 0, colour = fig_col$ink, linewidth = fig_lwd$axis) +
    scale_y_continuous(breaks = d$y, labels = as.character(d$group), expand = c(0, 0)) +
    scale_x_continuous(breaks = seq(0, 100, 25), labels = function(x) paste0(x, "%"),
                       expand = c(0, 0)) +
    coord_cartesian(xlim = c(0, x_max), ylim = c(0.45, n + 0.55), clip = "off") +
    labs(x = NULL, y = NULL) +
    theme_fig() +
    theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(),
          axis.text.y = element_text(size = fig_size$text, colour = fig_col$ink, hjust = 1,
                                     margin = margin(r = 2, unit = "mm")),
          axis.line.x = element_line(colour = fig_col$rule, linewidth = fig_lwd$axis),
          plot.margin = margin(0, 21, 0, 0, "mm")) +
    fig_heading_theme()
  p
}

# Shared key: drawn once above both panels (it applies to a and b alike).
key <- wrap_elements(full = fig_key_row(
  c("Share of country\u2013trial participations (observed)",
    "Share of global migraine YLDs (burden-proportional expectation)"),
  unname(fig_pair[c("observed", "reference")]), x0_mm = 2)) +
  theme(plot.margin = margin(0, 0, 0, 0))   # aligned with the panel letters

pa <- draw_panel(reg_d) + fig_heading("a", "WHO region")
pb <- draw_panel(inc_d) + fig_heading("b", "World Bank income group (FY2019)") +
  labs(x = "Share of global total") +
  theme(axis.title.x = element_text(size = fig_size$title, colour = fig_col$ink,
                                    margin = margin(t = 1.5, unit = "mm")))

width_mm <- fig_width[["double"]]
row_mm <- 7.2                     # vertical space per group
heading_mm <- 7
axis_mm <- 6
key_mm <- 4          # key row
key_gap_mm <- 0.5    # panel a heading supplies the rest of the separation
h_a <- nrow(reg_d) * row_mm
h_b <- nrow(inc_d) * row_mm
height_mm <- ceiling(key_mm + key_gap_mm + 2 * heading_mm + h_a + h_b + 2 * axis_mm + 4 + 7.5)

fig <- (key / plot_spacer() / pa / plot_spacer() / pb) +
  plot_layout(heights = unit(c(key_mm, key_gap_mm, h_a, 4, h_b), "mm")) +
  plot_annotation(theme = theme(plot.margin = margin(2, 1.5, 1.5, 1.5, "mm"))) &
  theme(plot.background = element_rect(fill = fig_col$paper, colour = NA))

stem <- file.path(out, "Figure_3_burden_representation_v2")
files <- fig_save(fig, stem, width_mm, height_mm)

# ---------------------------------------------------------------------------
# 6. Plot data and validation record (no absolute YLDs are written)
# ---------------------------------------------------------------------------
plot_data <- bind_rows(
  region |> mutate(panel = "a", classification = "WHO region"),
  income |> mutate(panel = "b", classification = "World Bank income group, FY2019")) |>
  mutate(displayed = group %in% c(region_order, income_order)) |>
  select(panel, classification, group, displayed, n_countries, observed, observed_share,
         yld_share, expected, oe)
write_csv(plot_data, paste0(stem, "_plot_data.csv"))

sha256 <- function(f) sub(" .*", "", system2("shasum", c("-a", "256", shQuote(f)), stdout = TRUE))
write_json(list(
  figure = "Figure 3", version = "v2", generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  scope = "Descriptive observed vs burden-proportional shares; values reused from the adopted release.",
  validation = checks,
  displayed_values = lapply(split(plot_data[plot_data$displayed, ], seq_len(sum(plot_data$displayed))),
                            function(r) list(panel = r$panel, group = r$group, observed = r$observed,
                                             observed_pct = round(100 * r$observed_share, 1),
                                             yld_pct = round(100 * r$yld_share, 1),
                                             oe = round(r$oe, 2))) |> unname(),
  export = list(width_mm = width_mm, height_mm = height_mm, png_dpi = fig_dpi, font = fig_font),
  input_sha256 = list(
    country_results = sha256(file.path(src, "results/country_expected_oe_all_scenarios.csv")),
    group_results = sha256(file.path(src, "results/who_income_expected_oe_all_scenarios.csv")),
    country_record = sha256(file.path(src, "country_record_453.csv")),
    manuscript_table_04 = sha256(file.path(src, "results/native_document_tables/manuscript_table_04.csv")),
    income_v1_data = sha256(file.path(src, "results/figure3_income_data.csv"))),
  output_sha256 = as.list(setNames(vapply(files, sha256, ""), basename(files)))
), paste0(stem, "_validation.json"), auto_unbox = TRUE, pretty = TRUE, digits = NA)

cat(sprintf("Validated: %d participations; regions %d; income groups %d (+1 documented exception)\n",
            total_obs, nrow(reg_d), nrow(inc_d)))
cat("Wrote:", files, sep = "\n  ")
