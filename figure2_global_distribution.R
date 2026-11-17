#!/usr/bin/env Rscript
# Figure 2 (v2): global distribution of country-trial participations and
# burden-adjusted representation across the 194 WHO Member States.
#
# Presentation refinement of the two-panel map in figure2_vertical.R (v1, kept
# unchanged). Same data, same participation classes and categories. The only
# change in visual encoding is that panel b uses reciprocal-symmetric O/E
# classes (4 below 1, 4 above 1) instead of 2 below / 4 above; O/E values are
# not recalculated. No analytical change.
#
# Usage (from a directory where public_data_and_reference_results.zip has been
# extracted, e.g. the output of `run_analysis.py --validate-only`):
#   Rscript figure2_global_distribution.R [data_dir] [output_dir]
# data_dir defaults to ".", output_dir defaults to data_dir.

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(sf); library(ggplot2); library(patchwork)
  library(jsonlite)
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
# 1. Data (authoritative adopted release; no derivation beyond counting)
# ---------------------------------------------------------------------------
pairs <- read_csv(file.path(src, "country_record_453.csv"), show_col_types = FALSE)
universe <- read_csv(file.path(src, "source_data/who_regions.csv"), show_col_types = FALSE)
oe_file <- read_csv(file.path(src, "results/country_expected_oe_all_scenarios.csv"),
                    show_col_types = FALSE) |>
  filter(scenario == "Point")

# One participation = one unique (study_id, country_iso3) pair among WHO Member
# States; removed registry locations are already absent from the pair file.
stopifnot(!anyDuplicated(pairs[c("study_id", "country_iso3")]),
          !anyDuplicated(universe$country_iso3),
          all(pairs$country_iso3 %in% universe$country_iso3))

d <- universe |>
  select(country_iso3) |>
  left_join(count(pairs, country_iso3, name = "participations"), by = "country_iso3") |>
  mutate(participations = coalesce(participations, 0L)) |>
  left_join(oe_file |> transmute(country_iso3 = ISO3, observed, oe), by = "country_iso3")

# Cross-check the two independent result files against each other.
stopifnot(!anyNA(d$observed), all(d$participations == d$observed),
          nrow(oe_file) == nrow(universe))

checks <- list(
  who_member_states = nrow(d),
  country_trial_participations = sum(d$participations),
  participating_member_states = sum(d$participations > 0),
  member_states_without_participation = sum(d$participations == 0),
  records_contributing = n_distinct(pairs$study_id)
)

# Compare with the release metadata when the launcher's copy is available.
release_file <- c(file.path(src, "CURRENT_RELEASE.json"), file.path(script_dir, "CURRENT_RELEASE.json"))
release_file <- release_file[file.exists(release_file)][1]
if (!is.na(release_file)) {
  rel <- fromJSON(release_file)
  stopifnot(checks$country_trial_participations == rel$WHO_country_record_pairs,
            checks$participating_member_states == rel$participating_countries,
            checks$who_member_states == rel$WHO_members)
  checks$release_metadata_agreement <- basename(release_file)
}

# ---------------------------------------------------------------------------
# 2. Classes (panel a identical to v1; panel b reciprocal-symmetric around 1)
# ---------------------------------------------------------------------------
levels_a <- c("1–2", "3–5", "6–14", "15–29", "≥30")
levels_b <- c("<0.1", "0.1–<0.2", "0.2–<0.5", "0.5–<1", "1–<2", "2–<5", "5–<10", "≥10")
colours_a <- setNames(fig_navy, levels_a)
colours_b <- setNames(fig_diverging, levels_b)
ZERO <- "No participation (0)"
OUT  <- "Not a WHO Member State"

d <- d |> mutate(
  class_a = case_when(participations == 0 ~ ZERO,
                      TRUE ~ as.character(cut(participations, c(0, 2, 5, 14, 29, Inf),
                                              labels = levels_a, right = TRUE))),
  class_b = case_when(participations == 0 ~ ZERO,
                      oe < 0.1 ~ levels_b[1], oe < 0.2 ~ levels_b[2], oe < 0.5 ~ levels_b[3],
                      oe < 1 ~ levels_b[4], oe < 2 ~ levels_b[5], oe < 5 ~ levels_b[6],
                      oe < 10 ~ levels_b[7], TRUE ~ levels_b[8]))

# ---------------------------------------------------------------------------
# 3. Geometry (Natural Earth 1:50m, Robinson; Antarctica omitted)
# ---------------------------------------------------------------------------
world <- st_read(file.path(src, "source/natural_earth/ne_50m_admin_0_countries.shp"),
                 quiet = TRUE) |>
  filter(ADMIN != "Antarctica") |>
  mutate(country_iso3 = if_else(ISO_A3 != "-99" & nchar(ISO_A3) == 3, ISO_A3, ADM0_A3)) |>
  select(country_iso3, geometry)
stopifnot(all(d$country_iso3 %in% world$country_iso3), !anyDuplicated(world$country_iso3))

world <- world |>
  left_join(d, by = "country_iso3") |>
  mutate(in_universe = !is.na(participations),
         class_a = coalesce(class_a, OUT), class_b = coalesce(class_b, OUT)) |>
  st_transform("ESRI:54030")

fill_a <- c(colours_a, setNames(fig_col$zero, ZERO), setNames(fig_col$not_in_universe, OUT))
fill_b <- c(colours_b, setNames(fig_col$zero, ZERO), setNames(fig_col$not_in_universe, OUT))

bb <- st_bbox(world)
width_mm <- fig_width[["double"]]
side_mm <- 1.5                                         # left/right page margin
map_w <- width_mm - 2 * side_mm
# Extra open space on the left (in printed mm) so the colour keys clear the
# American continents; the map itself is unchanged, only its frame is wider.
key_margin_mm <- 6
x_ext <- key_margin_mm * unname(bb["xmax"] - bb["xmin"]) / (map_w - key_margin_mm)
x_lim <- c(unname(bb["xmin"]) - x_ext, unname(bb["xmax"]))

draw_map <- function(var, fills) {
  inside <- world[world$in_universe, ]
  outside <- world[!world$in_universe, ]
  ggplot() +
    # Outside the analytical universe: hollow, thin neutral outline.
    geom_sf(data = outside, fill = fig_col$not_in_universe, colour = fig_col$rule,
            linewidth = fig_lwd$outline) +
    geom_sf(data = inside, aes(fill = .data[[var]]), colour = fig_col$border,
            linewidth = fig_lwd$border) +
    scale_fill_manual(values = fills, guide = "none") +
    coord_sf(crs = "ESRI:54030", datum = NA, expand = FALSE,
             xlim = x_lim, ylim = c(bb["ymin"], bb["ymax"])) +
    theme_fig_map()
}

mm <- diff(x_lim) / map_w                           # projected metres per printed mm
map_h <- unname(bb["ymax"] - bb["ymin"]) / mm
heading_mm <- 6.5
gap_mm <- 5
outer_mm <- c(top = 2, bottom = 1.5)                  # breathing room at the page edges
height_mm <- ceiling(2 * (map_h + heading_mm) + gap_mm + sum(outer_mm))

specials <- data.frame(
  label = c("No participation (0)", "Not a WHO Member State"),
  fill = c(fig_col$zero, fig_col$not_in_universe),
  outline = c(fig_col$zero, fig_col$rule)
)
# Keys sit in the open South Pacific, west of South America.
key_x0 <- x_lim[1] + 1.5 * mm
key_top <- unname(bb["ymin"]) + 18 * mm

map_a <- draw_map("class_a", fill_a) +
  fig_binned_key(key_x0, key_top, mm, levels_a, unname(colours_a),
                 "Country–trial participations, n", specials, swatch_w = 7.5) +
  fig_heading("a", "Country–trial participations")
# Same classes as levels_b (<0.1, ..., >=10), labelled at their
# lower-inclusive boundaries.
map_b <- draw_map("class_b", fill_b) +
  fig_binned_key(key_x0, key_top, mm, levels_b, unname(colours_b),
                 "Observed-to-expected ratio", specials,
                 breaks = c("0.1", "0.2", "0.5", "1", "2", "5", "10"), swatch_w = 5.5) +
  fig_heading("b", "Participation relative to migraine burden")

fig <- (map_a / plot_spacer() / map_b) +
  plot_layout(heights = unit(c(map_h, gap_mm, map_h), "mm")) +
  plot_annotation(theme = theme(plot.margin = margin(outer_mm[["top"]], side_mm,
                                                     outer_mm[["bottom"]], side_mm, "mm"))) &
  theme(plot.background = element_rect(fill = fig_col$paper, colour = NA))

stem <- file.path(out, "Figure_2_global_distribution_v2")
files <- fig_save(fig, stem, width_mm, height_mm)

# ---------------------------------------------------------------------------
# 4. Plot data and validation record
# ---------------------------------------------------------------------------
write_csv(d |> select(country_iso3, participations, oe, class_a, class_b),
          paste0(stem, "_plot_data.csv"))
sha256 <- function(f) system2("shasum", c("-a", "256", shQuote(f)), stdout = TRUE) |>
  sub(pattern = " .*", replacement = "")
write_json(list(
  figure = "Figure 2", version = "v2", generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  scope = "Presentation-only refinement of figure2_vertical.R; data and O/E values unchanged; panel b uses reciprocal-symmetric O/E classes.",
  validation = checks,
  class_counts_panel_a = as.list(table(d$class_a)),
  class_counts_panel_b = as.list(table(d$class_b)),
  export = list(width_mm = width_mm, height_mm = height_mm, png_dpi = fig_dpi, font = fig_font),
  input_sha256 = list(country_record = sha256(file.path(src, "country_record_453.csv")),
                      oe_results = sha256(file.path(src, "results/country_expected_oe_all_scenarios.csv")),
                      who_universe = sha256(file.path(src, "source_data/who_regions.csv")),
                      natural_earth_shp = sha256(file.path(src, "source/natural_earth/ne_50m_admin_0_countries.shp"))),
  output_sha256 = as.list(setNames(vapply(files, sha256, ""), basename(files)))
), paste0(stem, "_validation.json"), auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("WHO Member States: %d | participations: %d | participating: %d | none: %d\n",
            checks$who_member_states, checks$country_trial_participations,
            checks$participating_member_states, checks$member_states_without_participation))
cat("Wrote:", files, sep = "\n  ")
