#!/usr/bin/env Rscript
# Figure 2 (v3): migraine burden, country-trial participations and burden-adjusted
# representation across the 194 WHO Member States, as three stacked world maps:
#   a  Migraine burden: absolute migraine YLDs per country, GBD 2023, year 2023
#   b  Country-trial participations (absolute number; classes as in v2)
#   c  Representation relative to burden: observed-to-expected (O/E) ratio
#      (reciprocal-symmetric classes as in v2)
#
# Builds on figure2_global_distribution.R (v2, kept unchanged) and adds panel a.
# Panels b and c are v2's panels a and b; their data, classes and colours are
# unchanged. The O/E ratio is not recalculated; panel a shows the migraine YLDs
# that define the expected counts (expected = 453 x country YLDs / total YLDs).
# No analytical change.
#
# Panel a needs the country-level YLD input, which is a restricted third-party
# estimate (IHME GBD 2023) and is not in the public zip: results/
# country_analytic_with_yld_bounds_v1.csv of the full reproduction (DATA_ACCESS.md).
#
# Usage (from a full-reproduction directory that also holds the public zip contents):
#   Rscript figure2_three_panel.R [data_dir] [output_dir]
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

# Panel a input: migraine YLDs (GBD 2023, year 2023, both sexes, all ages).
yld_file <- file.path(src, "results/country_analytic_with_yld_bounds_v1.csv")
if (!file.exists(yld_file))
  stop("Panel a needs ", yld_file, " (restricted IHME input; see DATA_ACCESS.md)")
yld <- read_csv(yld_file, show_col_types = FALSE) |>
  transmute(country_iso3 = ISO3, yld = migraine_yld_point_2023, expected_point,
            gbd_release, reference_year)
stopifnot(nrow(yld) == nrow(universe), !anyDuplicated(yld$country_iso3),
          setequal(yld$country_iso3, universe$country_iso3),
          all(yld$gbd_release == "GBD 2023"), all(yld$reference_year == 2023),
          !anyNA(yld$yld), all(yld$yld > 0))
d <- d |> left_join(yld |> select(country_iso3, yld, expected_point), by = "country_iso3")
# YLDs and the expected counts must agree: expected = (country YLDs / total YLDs) x participations.
stopifnot(max(abs(d$expected_point - sum(d$participations) * d$yld / sum(d$yld))) < 1e-6,
          max(abs(d$expected_point - oe_file$expected[match(d$country_iso3, oe_file$ISO3)])) < 1e-6)
checks$migraine_yld_total <- sum(d$yld)
checks$expected_matches_yld_share <- TRUE

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
levels_y <- c("<50", "50–<200", "200–<500", "500–<1,000", "≥1,000")   # thousand YLDs
levels_a <- c("1–2", "3–5", "6–14", "15–29", "≥30")
levels_b <- c("<0.1", "0.1–<0.2", "0.2–<0.5", "0.5–<1", "1–<2", "2–<5", "5–<10", "≥10")
colours_y <- setNames(fig_navy, levels_y)     # same navy ramp as panel b: dark = more burden / more participations
colours_a <- setNames(fig_navy, levels_a)
colours_b <- setNames(fig_diverging, levels_b)
ZERO <- "No participation (0)"
OUT  <- "Not a WHO Member State"

d <- d |> mutate(
  class_y = as.character(cut(yld, c(0, 5e4, 2e5, 5e5, 1e6, Inf), labels = levels_y, right = FALSE)),
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
         class_y = coalesce(class_y, OUT),
         class_a = coalesce(class_a, OUT), class_b = coalesce(class_b, OUT)) |>
  st_transform("ESRI:54030")

fill_y <- c(colours_y, setNames(fig_col$not_in_universe, OUT))
fill_a <- c(colours_a, setNames(fig_col$zero, ZERO), setNames(fig_col$not_in_universe, OUT))
fill_b <- c(colours_b, setNames(fig_col$zero, ZERO), setNames(fig_col$not_in_universe, OUT))

bb <- st_bbox(world)
width_mm <- fig_width[["one_half"]]   # three stacked maps: 129 mm keeps the figure within the 225 mm limit with its legend
side_mm <- 1.5                                         # left/right page margin
map_w <- width_mm - 2 * side_mm
# Extra open space on the left (in printed mm) so the colour keys clear the
# American continents; the map itself is unchanged, only its frame is wider.
key_margin_mm <- 20
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
gap_mm <- 1.5
outer_mm <- c(top = 2, bottom = 2.5)                  # breathing room at the page edges
height_mm <- ceiling(3 * (map_h + heading_mm) + 2 * gap_mm + sum(outer_mm))

specials <- data.frame(
  label = c("No participation (0)", "Not a WHO Member State"),
  fill = c(fig_col$zero, fig_col$not_in_universe),
  outline = c(fig_col$zero, fig_col$rule)
)
# Keys sit in the open South Pacific, west of South America.
key_x0 <- x_lim[1] + 1.5 * mm
key_top <- unname(bb["ymin"]) + 18 * mm

specials_y <- specials[2, , drop = FALSE]
map_y <- draw_map("class_y", fill_y) +
  fig_binned_key(key_x0, key_top, mm, levels_y, unname(colours_y),
                 "Migraine YLDs, thousands", specials_y,
                 breaks = c("50", "200", "500", "1,000"), swatch_w = 7.5) +
  fig_heading("a", "Migraine burden (YLDs, 2023)")
map_a <- draw_map("class_a", fill_a) +
  fig_binned_key(key_x0, key_top, mm, levels_a, unname(colours_a),
                 "Participations, n", specials, swatch_w = 7.5) +
  fig_heading("b", "Country–trial participations")
# Same classes as levels_b (<0.1, ..., >=10), labelled at their
# lower-inclusive boundaries.
map_b <- draw_map("class_b", fill_b) +
  fig_binned_key(key_x0, key_top, mm, levels_b, unname(colours_b),
                 "Observed-to-expected ratio", specials,
                 breaks = c("0.1", "0.2", "0.5", "1", "2", "5", "10"), swatch_w = 5) +
  fig_heading("c", "Representation relative to migraine burden")

fig <- (map_y / plot_spacer() / map_a / plot_spacer() / map_b) +
  plot_layout(heights = unit(c(map_h, gap_mm, map_h, gap_mm, map_h), "mm")) +
  plot_annotation(theme = theme(plot.margin = margin(outer_mm[["top"]], side_mm,
                                                     outer_mm[["bottom"]], side_mm, "mm"))) &
  theme(plot.background = element_rect(fill = fig_col$paper, colour = NA))

stem <- file.path(out, "Figure_2_global_distribution_v3")
files <- fig_save(fig, stem, width_mm, height_mm)

# ---------------------------------------------------------------------------
# 4. Plot data and validation record
# ---------------------------------------------------------------------------
# Country-level YLD values are IHME estimates and are not redistributed: only the
# class assigned to each country is written (panel a).
write_csv(d |> select(country_iso3, participations, oe, class_y, class_a, class_b) |>
            rename(class_a_yld = class_y, class_b_participations = class_a,
                   class_c_oe = class_b),
          paste0(stem, "_plot_data.csv"))
sha256 <- function(f) system2("shasum", c("-a", "256", shQuote(f)), stdout = TRUE) |>
  sub(pattern = " .*", replacement = "")
write_json(list(
  figure = "Figure 2", version = "v3", generated = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  scope = "Adds panel a (migraine YLDs, GBD 2023) to the v2 maps; participations, O/E values and classes unchanged. Panels b and c are v2's panels a and b.",
  validation = checks,
  class_counts_panel_a_yld = as.list(table(d$class_y)),
  class_counts_panel_b_participations = as.list(table(d$class_a)),
  class_counts_panel_c_oe = as.list(table(d$class_b)),
  export = list(width_mm = width_mm, height_mm = height_mm, png_dpi = fig_dpi, font = fig_font),
  input_sha256 = list(country_record = sha256(file.path(src, "country_record_453.csv")),
                      yld_input = sha256(yld_file),
                      oe_results = sha256(file.path(src, "results/country_expected_oe_all_scenarios.csv")),
                      who_universe = sha256(file.path(src, "source_data/who_regions.csv")),
                      natural_earth_shp = sha256(file.path(src, "source/natural_earth/ne_50m_admin_0_countries.shp"))),
  output_sha256 = as.list(setNames(vapply(files, sha256, ""), basename(files)))
), paste0(stem, "_validation.json"), auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("WHO Member States: %d | participations: %d | participating: %d | none: %d\n",
            checks$who_member_states, checks$country_trial_participations,
            checks$participating_member_states, checks$member_states_without_participation))
cat("Wrote:", files, sep = "\n  ")
