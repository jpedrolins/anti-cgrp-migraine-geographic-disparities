#!/usr/bin/env Rscript
# Figure 5: exploratory income-group distribution of anti-CGRP
# trial participations compared with WHO ICTRP clinical trial benchmarks.
#
# Status (18 November 2026): final layout; Supplementary Figure S3 is the
# "record_sets" variant.
#   - WHO migraine, neuropsychiatric and all-trial benchmarks are rebuilt here
#     from the WHO Global Observatory "trials by country" exports.
#   - The anti-CGRP column is every record that passed deduplication (132
#     records, 477 country-trial participations), before eligibility
#     assessment; pairs from figure5_build_anti_cgrp_set.py.
# Descriptive only: no tests, no adjustment.
#
# Usage:
#   Rscript figure5_who_benchmark.R <data_dir> <who_export_dir> [output_dir] [variant]
#   variant:        "main" (default): one anti-CGRP bar, the 132 deduplicated
#                   records; "record_sets": three anti-CGRP bars (all 167
#                   identified records, 132 deduplicated records, 108 eligible
#                   trials), each compared with the three WHO benchmarks
#   data_dir:       extracted public_data_and_reference_results.zip (for the
#                   194 WHO Member States and their FY2019 income groups)
#   who_export_dir: folder with the three WHO exports (UTF-16, tab-separated):
#                   "Trials by country.csv" (migraine),
#                   "Neuropsy - Trials by country (1).csv" (neuropsychiatric),
#                   "Trials per country.csv" (all clinical trials)

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(ggplot2); library(patchwork); library(jsonlite)
})

script_dir <- local({
  f <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
  if (length(f)) dirname(normalizePath(f)) else getwd()
})
source(file.path(script_dir, "figure_theme.R"))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: figure5_who_benchmark.R <data_dir> <who_export_dir> [output_dir]")
src <- normalizePath(args[1], mustWork = TRUE)
who_dir <- normalizePath(args[2], mustWork = TRUE)
out <- if (length(args) >= 3) args[3] else file.path(script_dir, "figures")
variant <- if (length(args) >= 4) args[4] else "main"
if (!variant %in% c("main", "record_sets")) stop("variant must be main or record_sets")
dir.create(file.path(out, "figure5"), recursive = TRUE, showWarnings = FALSE)
fail <- function(msg) stop("Validation failed: ", msg, call. = FALSE)

income_levels <- names(fig_income)

# ---------------------------------------------------------------------------
# 1. Reference: 194 WHO Member States with World Bank FY2019 income groups
# ---------------------------------------------------------------------------
ref <- read_csv(file.path(src, "results/country_expected_oe_all_scenarios.csv"),
                show_col_types = FALSE) |>
  filter(scenario == "Point") |> select(ISO3, Country, income)
if (nrow(ref) != 194 || !all(ref$income %in% income_levels)) fail("reference universe")

norm <- function(x) {
  x <- iconv(x, "UTF-8", "ASCII//TRANSLIT")
  x <- tolower(gsub("[’'`^\"~]| \\*$", "", x))
  trimws(gsub("\\s+", " ", x))
}
ref$key <- norm(ref$Country)
# Names in the WHO exports that differ from the reference spelling.
alias <- c("nauru" = "NRU")

# ---------------------------------------------------------------------------
# 2. WHO exports -> country-trial participations by FY2019 income group
# ---------------------------------------------------------------------------
read_who <- function(file) {
  raw <- read.delim(file.path(who_dir, file), fileEncoding = "UTF-16", check.names = FALSE,
                    stringsAsFactors = FALSE, quote = "")
  name_col <- 1
  n_col <- which(names(raw) %in% c("N Trial", "Number of trials"))[1]
  if (is.na(n_col)) fail(paste("count column in", file))
  d <- data.frame(name = raw[[name_col]], n = as.numeric(gsub(",", "", raw[[n_col]])))
  d <- d[nzchar(trimws(d$name)), ]
  d <- unique(d)                                  # Tableau exports repeat every row
  if (anyDuplicated(d$name)) fail(paste("conflicting duplicate rows in", file))
  k <- norm(d$name)
  d$ISO3 <- ref$ISO3[match(k, ref$key)]
  d$ISO3[is.na(d$ISO3) & k %in% names(alias)] <- alias[k[is.na(d$ISO3) & k %in% names(alias)]]
  d
}
who_files <- c(who_migraine = "Trials by country.csv",
           who_neuropsychiatric = "Neuropsy - Trials by country (1).csv",
           who_all_trials = "Trials per country.csv")
who <- lapply(who_files, read_who)

# Areas that do not match a Member State must be non-members: the all-trials
# export lists every Member State, so anything it leaves unmatched is a
# territory, "Unknown" or "NA".
nonmember <- who$who_all_trials$name[is.na(who$who_all_trials$ISO3)]
if (sum(!is.na(who$who_all_trials$ISO3)) != 194) fail("all-trials export does not cover 194 Member States")
for (k in names(who)) {
  um <- who[[k]]$name[is.na(who[[k]]$ISO3)]
  if (!all(um %in% nonmember)) fail(paste("unmatched Member State in", k, ":", paste(setdiff(um, nonmember), collapse = ", ")))
}

who_counts <- bind_rows(lapply(names(who), function(k) {
  who[[k]] |> filter(!is.na(ISO3)) |>
    left_join(ref |> select(ISO3, income), by = "ISO3") |>
    count(income_group = income, wt = n, name = "n") |> mutate(dataset = k)
}))
excluded_nonmember <- vapply(who, function(d) sum(d$n[is.na(d$ISO3)]), 0)

# ---------------------------------------------------------------------------
# 3. Anti-CGRP set: all 132 records that passed deduplication, before
#    full-record eligibility assessment (PRISMA), as country-trial pairs built
#    by figure5_build_anti_cgrp_set.py from the 5 August 2026 snapshot.
# ---------------------------------------------------------------------------
s9 <- read_csv(file.path(script_dir, "figures/figure5/S9_transcribed_20261117.csv"),
               show_col_types = FALSE) |>
  mutate(dataset = sub("^anti_cgrp_467$", "anti_cgrp", dataset))
primary <- read_csv(file.path(src, "country_record_453.csv"), show_col_types = FALSE)
if (nrow(primary) != 453 || anyDuplicated(primary[c("study_id", "country_iso3")])) fail("primary cohort")
sets <- read_csv(file.path(script_dir, "figures/figure5/anti_cgrp_record_sets_pairs.csv"),
                 show_col_types = FALSE, na = "")
if (anyDuplicated(sets[c("set", "record_key", "country_iso3")])) fail("duplicate country-trial pairs")
if (!all(sets$country_iso3 %in% ref$ISO3)) fail("non-member country in anti-CGRP sets")
# FY2019 income from the reference universe; must agree with the stored column.
sets$income_group <- ref$income[match(sets$country_iso3, ref$ISO3)]
if (any(sets$income_group != sets$income_fy2019)) fail("anti-CGRP income groups")
set_n <- c(pre_dedup_167 = 747, post_dedup_132 = 477, eligible_108 = 453)
if (!isTRUE(all(c(table(sets$set))[names(set_n)] == set_n))) fail("anti-CGRP set sizes")
pairs <- sets |> filter(set == "post_dedup_132")
inc <- pairs |> filter(final_decision == "include")
el <- sets |> filter(set == "eligible_108")
for (x in list(inc, el))
  if (!setequal(paste(x$study_id, x$country_iso3), paste(primary$study_id, primary$country_iso3)))
    fail("eligible records do not reproduce the 453 primary pairs")
set_key <- c(pre_dedup_167 = "anti_pre", post_dedup_132 = "anti_cgrp", eligible_108 = "anti_eligible")
anti <- (if (variant == "main") pairs else sets) |>
  count(set, income_group, name = "n") |> mutate(dataset = unname(set_key[set]))

counts <- bind_rows(anti |> select(dataset, income_group, n), who_counts) |>
  mutate(income_group = factor(income_group, levels = income_levels)) |>
  tidyr::complete(dataset, income_group, fill = list(n = 0)) |>
  group_by(dataset) |> mutate(total = sum(n), share = n / total) |> ungroup()

# ---------------------------------------------------------------------------
# 4. Validation
# ---------------------------------------------------------------------------
tot <- counts |> distinct(dataset, total)
chk <- list(
  totals = setNames(as.list(tot$total), tot$dataset),
  shares_sum_to_one = all(abs(tapply(counts$share, counts$dataset, sum) - 1) < 1e-12),
  unclassified_retained = setNames(as.list(counts$n[counts$income_group == "Income group unavailable"]),
                                   counts$dataset[counts$income_group == "Income group unavailable"]),
  non_member_areas_excluded = as.list(excluded_nonmember),
  anti_cgrp_source = "All 132 deduplicated records before eligibility assessment (5 Aug 2026 snapshot)",
  anti_cgrp_pairs = as.list(table(pairs$final_decision)),
  anti_cgrp_sets = as.list(table(sets$set)),
  primary_cohort_total = nrow(primary)
)
if (!chk$shares_sum_to_one) fail("shares")
# Agreement with S9, reported (not enforced).
cmp <- counts |> select(dataset, income_group, n) |>
  left_join(s9 |> rename(n_s9 = n) |> mutate(income_group = factor(income_group, levels = income_levels)),
            by = c("dataset", "income_group")) |>
  mutate(diff = n - n_s9)
chk$difference_vs_S9 <- lapply(split(cmp, cmp$dataset), function(x)
  setNames(as.list(x$diff), as.character(x$income_group)))

# ---------------------------------------------------------------------------
# 5. Figure: 100% stacked horizontal bars, Figure 3 conventions
# ---------------------------------------------------------------------------
if (variant == "main") {
ds <- c(anti_cgrp = "Anti-CGRP mAb records", who_migraine = "Migraine trials",
        who_neuropsychiatric = "Neuropsychiatric trials", who_all_trials = "All clinical trials")
# One row per dataset (same row pitch as Figure 3); a thin rule separates the
# anti-CGRP set from the three WHO benchmarks.
ypos <- c(anti_cgrp = 4.4, who_migraine = 3, who_neuropsychiatric = 2, who_all_trials = 1)
bar_h <- 0.56
rule_y <- 3.7

seg <- counts |>
  arrange(dataset, income_group) |>
  group_by(dataset) |>
  mutate(xmax = 100 * cumsum(share), xmin = xmax - 100 * share) |> ungroup() |>
  mutate(y = ypos[dataset])

# Percentages (one decimal) inside segments wide enough to hold them.
lab <- seg |> filter(100 * share >= 3.4) |>
  mutate(txt = formatC(100 * share, format = "f", digits = 1),
         col = ifelse(income_group %in% c("High income", "Upper-middle income"), "white", fig_col$ink))

hic <- counts |> filter(income_group == "High income") |> select(dataset, hic = share)
d_hic <- hic |> mutate(pp = 100 * (hic[dataset == "anti_cgrp"] - hic))
fmt_n <- function(x) formatC(x, format = "d", big.mark = ",")
col_n <- 114; col_d <- 134
top <- max(ypos)

g <- ggplot() +
  geom_rect(data = seg, aes(xmin = xmin, xmax = xmax, ymin = y - bar_h / 2, ymax = y + bar_h / 2,
                            fill = income_group), colour = "white", linewidth = 0.2) +
  geom_text(data = lab, aes(x = (xmin + xmax) / 2, y = y, label = txt), colour = lab$col,
            family = fig_font, size = fig_size$text / .pt) +
  geom_vline(xintercept = 0, colour = fig_col$ink, linewidth = fig_lwd$axis) +
  annotate("segment", x = 0, xend = col_d, y = rule_y, yend = rule_y,
           colour = fig_col$rule, linewidth = fig_lwd$axis) +
  # right-hand columns (as the O/E column in Figure 3)
  annotate("text", x = c(col_n, col_d), y = top + 0.62, label = c("n", "Difference, pp"),
           hjust = 1, vjust = 0, family = fig_font, fontface = "bold",
           size = fig_size$title / .pt, colour = fig_col$ink) +
  annotate("text", x = col_n, y = ypos, label = fmt_n(tot$total[match(names(ypos), tot$dataset)]),
           hjust = 1, family = fig_font, size = fig_size$text / .pt, colour = fig_col$ink) +
  annotate("text", x = col_d, y = ypos,
           label = ifelse(names(ypos) == "anti_cgrp", "Reference",
                          sprintf("+%.1f", d_hic$pp[match(names(ypos), d_hic$dataset)])),
           hjust = 1, family = fig_font, size = fig_size$text / .pt,
           colour = ifelse(names(ypos) == "anti_cgrp", fig_col$muted, fig_col$ink)) +
  scale_fill_manual(values = fig_income, guide = "none") +
  scale_y_continuous(breaks = ypos, labels = ds[names(ypos)], expand = c(0, 0)) +
  scale_x_continuous(breaks = seq(0, 100, 25), labels = function(x) paste0(x, "%"),
                     expand = c(0, 0)) +
  coord_cartesian(xlim = c(0, 100), ylim = c(0.5, top + 0.5), clip = "off") +
  labs(x = "Share of country\u2013trial participations", y = NULL) +
  theme_fig() +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(),
        axis.text.y = element_text(size = fig_size$text, colour = fig_col$ink, hjust = 1,
                                   margin = margin(r = 2, unit = "mm")),
        axis.line.x = element_line(colour = fig_col$rule, linewidth = fig_lwd$axis),
        axis.title.x = element_text(size = fig_size$title, margin = margin(t = 1.5, unit = "mm")),
        plot.margin = margin(0, 40, 0, 0, "mm"))

} else {
# Variant: three anti-CGRP record sets (a-c), each compared with every WHO
# benchmark. Group headings name the two blocks; differences are given per set.
ds <- c(anti_pre = "Before deduplication\n167 records",
        anti_cgrp = "After deduplication\n132 records",
        anti_eligible = "Eligible trials\n108 trials",
        who_migraine = "Migraine trials", who_neuropsychiatric = "Neuropsychiatric trials",
        who_all_trials = "All clinical trials")
ypos <- c(anti_pre = 6.6, anti_cgrp = 5.6, anti_eligible = 4.6,
          who_migraine = 3, who_neuropsychiatric = 2, who_all_trials = 1)
set_letter <- c(anti_pre = "a", anti_cgrp = "b", anti_eligible = "c")
ds[names(set_letter)] <- paste0(sub("\n.*", "", ds[names(set_letter)]), " (", set_letter, ")\n",
                                sub(".*\n", "", ds[names(set_letter)]))
bar_h <- 0.56
rule_y <- 3.95

seg <- counts |>
  arrange(dataset, income_group) |>
  group_by(dataset) |>
  mutate(xmax = 100 * cumsum(share), xmin = xmax - 100 * share) |> ungroup() |>
  mutate(y = ypos[dataset])
lab <- seg |> filter(100 * share >= 4.5) |>
  mutate(txt = formatC(100 * share, format = "f", digits = 1),
         col = ifelse(income_group %in% c("High income", "Upper-middle income"), "white", fig_col$ink))

hic <- counts |> filter(income_group == "High income") |> select(dataset, hic = share)
who_keys <- c("who_migraine", "who_neuropsychiatric", "who_all_trials")
d_hic <- expand.grid(anti = names(set_letter), dataset = who_keys, stringsAsFactors = FALSE) |>
  mutate(pp = 100 * (hic$hic[match(anti, hic$dataset)] - hic$hic[match(dataset, hic$dataset)]))
fmt_n <- function(x) formatC(x, format = "d", big.mark = ",")
col_n <- 116; col_d <- c(a = 129, b = 141, c = 153)
hdr_y <- 7.3
dtxt <- d_hic |> mutate(x = col_d[set_letter[anti]], y = ypos[dataset], label = sprintf("+%.1f", pp))

txt <- function(...) annotate("text", family = fig_font, size = fig_size$text / .pt, ...)
g <- ggplot() +
  geom_rect(data = seg, aes(xmin = xmin, xmax = xmax, ymin = y - bar_h / 2, ymax = y + bar_h / 2,
                            fill = income_group), colour = "white", linewidth = 0.2) +
  geom_text(data = lab, aes(x = (xmin + xmax) / 2, y = y, label = txt), colour = lab$col,
            family = fig_font, size = fig_size$text / .pt) +
  geom_segment(aes(x = 0, xend = 0, y = 0.5, yend = 7), colour = fig_col$ink, linewidth = fig_lwd$axis) +
  annotate("segment", x = 0, xend = max(col_d), y = rule_y, yend = rule_y,
           colour = fig_col$rule, linewidth = fig_lwd$axis) +
  # group headings
  annotate("text", x = 0.8, y = c(hdr_y, 3.62), label = c("Anti-CGRP mAb registry records", "WHO ICTRP benchmarks"),
           hjust = 0, family = fig_font, fontface = "bold", size = fig_size$title / .pt, colour = fig_col$ink) +
  # column headers: n, and differences against sets a-c
  annotate("text", x = c(col_n, col_d), y = hdr_y, label = c("n", paste("vs", names(col_d))),
           hjust = 1, family = fig_font, fontface = "bold", size = fig_size$title / .pt, colour = fig_col$ink) +
  annotate("text", x = mean(range(col_d)) - 4, y = hdr_y + 0.6, label = "Difference, pp",
           hjust = 0.5, family = fig_font, fontface = "bold", size = fig_size$title / .pt, colour = fig_col$ink) +
  annotate("segment", x = min(col_d) - 8, xend = max(col_d), y = hdr_y + 0.35, yend = hdr_y + 0.35,
           colour = fig_col$rule, linewidth = fig_lwd$axis) +
  txt(x = col_n, y = ypos, label = fmt_n(tot$total[match(names(ypos), tot$dataset)]), hjust = 1,
      colour = fig_col$ink) +
  geom_text(data = dtxt, aes(x = x, y = y, label = label), hjust = 1, family = fig_font,
            size = fig_size$text / .pt, colour = fig_col$ink) +
  scale_fill_manual(values = fig_income, guide = "none") +
  scale_y_continuous(breaks = ypos, labels = ds[names(ypos)], expand = c(0, 0)) +
  scale_x_continuous(breaks = seq(0, 100, 25), labels = function(x) paste0(x, "%"),
                     expand = c(0, 0)) +
  coord_cartesian(xlim = c(0, 100), ylim = c(0.5, hdr_y + 0.8), clip = "off") +
  labs(x = "Share of country\u2013trial participations", y = NULL) +
  theme_fig() +
  theme(axis.line.y = element_blank(), axis.ticks.y = element_blank(),
        axis.text.y = element_text(size = fig_size$text, colour = fig_col$ink, hjust = 1,
                                   lineheight = 0.95, margin = margin(r = 2, unit = "mm")),
        axis.line.x = element_line(colour = fig_col$rule, linewidth = fig_lwd$axis),
        axis.title.x = element_text(size = fig_size$title, margin = margin(t = 1.5, unit = "mm")),
        plot.margin = margin(0, 56, 0, 0, "mm"))
top <- hdr_y + 0.35
}

# Key row as in Figure 3.
key <- wrap_elements(full = grid::gTree(children = grid::gList(
  fig_key_row(income_levels[1:4], unname(fig_income[1:4]), x0_mm = 2)))) +
  theme(plot.margin = margin(0, 0, 0, 0))

row_mm <- 7.2
panel_mm <- (top + 0.5 - 0.5) * row_mm
fig <- (key / plot_spacer() / g) +
  plot_layout(heights = unit(c(4, 3, panel_mm), "mm")) +
  plot_annotation(theme = theme(plot.margin = margin(2, 1.5, 1.5, 1.5, "mm"),
                                plot.background = element_rect(fill = fig_col$paper, colour = NA)))

stem <- file.path(out, "figure5", if (variant == "main") "Figure_5_who_benchmark"
                  else "Figure_S3_record_selection_stages")
out_files <- fig_save(fig, stem, fig_width[["double"]], ceiling(4 + 3 + panel_mm + 18))

# ---------------------------------------------------------------------------
# 6. Outputs
# ---------------------------------------------------------------------------
write_csv(counts |> mutate(share_pct_2dp = round(100 * share, 2)), paste0(stem, "_data.csv"))
sha256 <- function(f) sub(" .*", "", system2("shasum", c("-a", "256", shQuote(f)), stdout = TRUE))
write_json(list(
  figure = if (variant == "main") "Figure 5" else "Supplementary Figure S3", generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  status = "Anti-CGRP column: 132 deduplicated records (477); WHO columns rebuilt from the Global Observatory exports.",
  validation = chk,
  variant = variant,
  hic_difference_pp = if (variant == "main") setNames(as.list(round(d_hic$pp, 2)), d_hic$dataset)
                      else setNames(as.list(round(d_hic$pp, 2)), paste(d_hic$anti, "minus", d_hic$dataset)),
  who_input_files = lapply(as.list(who_files), function(f) list(file = f, sha256 = sha256(file.path(who_dir, f)))),
  output_sha256 = as.list(setNames(vapply(out_files, sha256, ""), basename(out_files)))
), paste0(stem, "_validation.json"), auto_unbox = TRUE, pretty = TRUE, digits = NA)

print(as.data.frame(counts |> mutate(pct = round(100 * share, 2)) |> select(dataset, income_group, n, total, pct)))
cat("HIC difference (pp):", paste(if (variant == "main") d_hic$dataset else paste(d_hic$anti, d_hic$dataset),
                                   round(d_hic$pp, 2), collapse = "; "), "\n")
