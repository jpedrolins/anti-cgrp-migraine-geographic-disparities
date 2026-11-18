#!/usr/bin/env Rscript
# Supplementary Figure S1: income-group distribution of country-trial
# participations by anti-CGRP monoclonal antibody, with the number of trials,
# WHO Member States reached and participations for each antibody.
#
# Replaces the two-panel layout of build_supplementary_drug_figure.R with one
# chart in the shared design system (figure_theme.R), drawn like Figure 5:
# 100% stacked bars by World Bank FY2019 income group and right-hand columns.
# Data and classification are unchanged: the same record-country pairs and the
# same two reviewed agent corrections; the script stops unless it reproduces
# results/figure_s1_mab_data.csv.
#
# Usage:
#   Rscript figureS1_mab_income.R <data_dir> [output_dir]
#   data_dir: extracted public_data_and_reference_results.zip

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(ggplot2); library(patchwork); library(jsonlite)
})

script_dir <- local({
  f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
  if (length(f)) dirname(normalizePath(f)) else getwd()
})
source(file.path(script_dir, "figure_theme.R"))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("Usage: figureS1_mab_income.R <data_dir> [output_dir]")
src <- normalizePath(args[1], mustWork = TRUE)
out <- if (length(args) >= 2) args[2] else file.path(script_dir, "figures")
dir.create(file.path(out, "figureS1"), recursive = TRUE, showWarnings = FALSE)
fail <- function(msg) stop("Validation failed: ", msg, call. = FALSE)

# ---------------------------------------------------------------------------
# 1. Data: as in build_supplementary_drug_figure.R
# ---------------------------------------------------------------------------
records <- fromJSON(file.path(src, "source/study_agent_records.json"))
pairs <- read_csv(file.path(src, "source/country_record_pairs.csv"), show_col_types = FALSE)
# The two reviewed agent corrections.
records$agent[records$id == "NCT04659226"] <- "erenumab"
records$agent[records$id == "NCT07071506"] <- "fremanezumab"
approved <- c("erenumab", "fremanezumab", "galcanezumab", "eptinezumab")
category <- function(x) {
  s <- intersect(trimws(tolower(unlist(strsplit(x, ";", fixed = TRUE)))), approved)
  if (length(s) > 1) "Multiple anti-CGRP mAbs"
  else if (length(s) == 0) "Unspecified anti-CGRP mAb"
  else paste0(toupper(substr(s, 1, 1)), substring(s, 2))
}
records$drug <- vapply(records$agent, category, character(1))
if (nrow(records) != 108 || anyDuplicated(records$id) || nrow(pairs) != 453) fail("input sizes")
pairs$drug <- records$drug[match(pairs$study_id, records$id)]
if (anyNA(pairs$drug)) fail("pairs without an antibody category")

drug_order <- c("Erenumab", "Eptinezumab", "Fremanezumab", "Galcanezumab", "Multiple anti-CGRP mAbs")
inc_code <- c(HIC = "High income", UMIC = "Upper-middle income",
              LMIC = "Lower-middle income", LIC = "Low income")
income_levels <- unname(inc_code)
if (!all(pairs$income %in% names(inc_code))) fail("income codes")

shown <- pairs |> filter(drug %in% drug_order)
summary_tab <- tibble(drug = drug_order) |>
  mutate(trials = vapply(drug, function(g) sum(records$drug == g), 0),
         countries = vapply(drug, function(g) n_distinct(shown$country_iso3[shown$drug == g]), 0),
         n = vapply(drug, function(g) sum(shown$drug == g), 0))
counts <- shown |>
  mutate(income_group = factor(unname(inc_code[income]), levels = income_levels),
         drug = factor(drug, levels = drug_order)) |>
  count(drug, income_group, .drop = FALSE) |>
  group_by(drug) |> mutate(share = n / sum(n)) |> ungroup()

# ---------------------------------------------------------------------------
# 2. Validation against the reference output
# ---------------------------------------------------------------------------
ref <- read_csv(file.path(src, "results/figure_s1_mab_data.csv"), show_col_types = FALSE)
wide <- counts |> select(drug, income_group, share) |>
  tidyr::pivot_wider(names_from = income_group, values_from = share)
chk <- ref |> mutate(drug = factor(drug, levels = drug_order)) |>
  left_join(summary_tab |> mutate(drug = factor(drug, levels = drug_order)), by = "drug") |>
  left_join(wide, by = "drug")
ok <- with(chk, all(trials.x == trials.y) && all(countries_reached == countries) &&
             all(trial_country_participations == n) &&
             all(abs(HIC - 100 * `High income`) < 1e-9) &&
             all(abs(UMIC - 100 * `Upper-middle income`) < 1e-9) &&
             all(abs(LMIC - 100 * `Lower-middle income`) < 1e-9) &&
             all(abs(LIC - 100 * `Low income`) < 1e-9))
if (!isTRUE(ok)) fail("does not reproduce results/figure_s1_mab_data.csv")
if (sum(summary_tab$n) != 452) fail("displayed participations are not 452")
unspecified <- list(trials = sum(records$drug == "Unspecified anti-CGRP mAb"),
                    participations = sum(pairs$drug == "Unspecified anti-CGRP mAb"))
no_pairs <- records |> filter(drug %in% drug_order, !id %in% pairs$study_id) |> count(drug)

# ---------------------------------------------------------------------------
# 3. Figure: 100% stacked bars and right-hand columns (Figure 5 conventions)
# ---------------------------------------------------------------------------
ypos <- c(Erenumab = 6, Eptinezumab = 5, Fremanezumab = 4, Galcanezumab = 3,
          `Multiple anti-CGRP mAbs` = 1.6)
bar_h <- 0.56
rule_y <- 2.3
top <- max(ypos)

seg <- counts |>
  arrange(drug, income_group) |>
  group_by(drug) |>
  mutate(xmax = 100 * cumsum(share), xmin = xmax - 100 * share) |> ungroup() |>
  mutate(y = ypos[as.character(drug)])
lab <- seg |> filter(100 * share >= 3.6) |>
  mutate(txt = formatC(100 * share, format = "f", digits = 1),
         col = ifelse(income_group %in% c("High income", "Upper-middle income"), "white", fig_col$ink))

cols <- c(trials = 109, countries = 130, n = 156)
hdr <- c(trials = "Trials", countries = "Countries", n = "Participations")
fmt <- function(x) formatC(x, format = "d", big.mark = ",")
txt <- function(...) annotate("text", family = fig_font, size = fig_size$text / .pt,
                              colour = fig_col$ink, hjust = 1, ...)

g <- ggplot() +
  geom_rect(data = seg, aes(xmin = xmin, xmax = xmax, ymin = y - bar_h / 2, ymax = y + bar_h / 2,
                            fill = income_group), colour = "white", linewidth = 0.2) +
  geom_text(data = lab, aes(x = (xmin + xmax) / 2, y = y, label = txt), colour = lab$col,
            family = fig_font, size = fig_size$text / .pt) +
  geom_vline(xintercept = 0, colour = fig_col$ink, linewidth = fig_lwd$axis) +
  annotate("segment", x = 0, xend = max(cols), y = rule_y, yend = rule_y,
           colour = fig_col$rule, linewidth = fig_lwd$axis) +
  annotate("text", x = cols, y = top + 0.62, label = hdr[names(cols)], hjust = 1, vjust = 0,
           family = fig_font, fontface = "bold", size = fig_size$title / .pt, colour = fig_col$ink) +
  txt(x = cols[["trials"]], y = ypos, label = fmt(summary_tab$trials[match(names(ypos), summary_tab$drug)])) +
  txt(x = cols[["countries"]], y = ypos, label = fmt(summary_tab$countries[match(names(ypos), summary_tab$drug)])) +
  txt(x = cols[["n"]], y = ypos, label = fmt(summary_tab$n[match(names(ypos), summary_tab$drug)])) +
  scale_fill_manual(values = fig_income, guide = "none") +
  scale_y_continuous(breaks = ypos, labels = names(ypos), expand = c(0, 0)) +
  scale_x_continuous(breaks = seq(0, 100, 25), labels = function(x) paste0(x, "%"),
                     expand = c(0, 0)) +
  coord_cartesian(xlim = c(0, 100), ylim = c(1, top + 0.5), clip = "off") +
  labs(x = "Share of country–trial participations", y = NULL) +
  theme_fig() +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(),
        axis.text.y = element_text(size = fig_size$text, colour = fig_col$ink, hjust = 1,
                                   margin = margin(r = 2, unit = "mm")),
        axis.line.x = element_line(colour = fig_col$rule, linewidth = fig_lwd$axis),
        axis.title.x = element_text(size = fig_size$title, margin = margin(t = 1.5, unit = "mm")),
        plot.margin = margin(0, 56, 0, 0, "mm"))

key <- wrap_elements(full = grid::gTree(children = grid::gList(
  fig_key_row(income_levels, unname(fig_income[income_levels]), x0_mm = 2)))) +
  theme(plot.margin = margin(0, 0, 0, 0))

row_mm <- 7.2
panel_mm <- (top + 0.5 - 1) * row_mm
fig <- (key / plot_spacer() / g) +
  plot_layout(heights = unit(c(4, 3, panel_mm), "mm")) +
  plot_annotation(theme = theme(plot.margin = margin(2, 1.5, 1.5, 1.5, "mm"),
                                plot.background = element_rect(fill = fig_col$paper, colour = NA)))

stem <- file.path(out, "figureS1", "Figure_S1_mab_income")
out_files <- fig_save(fig, stem, fig_width[["double"]], ceiling(4 + 3 + panel_mm + 18))

# ---------------------------------------------------------------------------
# 4. Outputs
# ---------------------------------------------------------------------------
write_csv(counts |> left_join(summary_tab |> rename(n_participations = n), by = c("drug")) |>
            mutate(share_pct_2dp = round(100 * share, 2)),
          paste0(stem, "_data.csv"))
sha256 <- function(f) sub(" .*", "", system2("shasum", c("-a", "256", shQuote(f)), stdout = TRUE))
write_json(list(
  figure = "Supplementary Figure S1", generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  reproduces = "results/figure_s1_mab_data.csv",
  displayed_participations = sum(summary_tab$n),
  unspecified_not_displayed = unspecified,
  trials_without_participation = setNames(as.list(no_pairs$n), no_pairs$drug),
  output_sha256 = as.list(setNames(vapply(out_files, sha256, ""), basename(out_files)))
), paste0(stem, "_validation.json"), auto_unbox = TRUE, pretty = TRUE, digits = NA)

print(as.data.frame(summary_tab))
cat("Unspecified mAb (not shown):", unspecified$trials, "trial,", unspecified$participations, "participations\n")
cat("Trials without any participation:", paste(no_pairs$drug, no_pairs$n, collapse = "; "), "\n")
