# Shared visual design system for the manuscript figures
# (Journal of Headache and Pain; Springer Nature artwork specifications).
#
# Presentation only. Nothing in this file reads data, derives variables or
# changes an analytical definition. Figure scripts source it with
#   source(file.path(<script directory>, "figure_theme.R"))
#
# Introduced with the refined geographic figure (Figure 2 v2, 17 November 2026)
# so that all manuscript figures share one typography, palette, line-weight and
# export specification.

suppressPackageStartupMessages({
  library(ggplot2)
  library(grid)
})

# ---------------------------------------------------------------------------
# Typography
# ---------------------------------------------------------------------------
# Montserrat is not installed on the reference workstation and is not bundled
# with the repository; Arial is used (Springer Nature's recommended sans-serif).
# Override with options(figure_font = "Helvetica") if Arial is unavailable.
fig_font <- getOption("figure_font", "Arial")

# Sizes are in points at final printed size (Springer Nature: 8-12 pt body,
# never below 6 pt).
fig_size <- list(
  tag     = 10,   # panel letters (a, b, c)
  heading = 8,    # short panel heading next to the panel letter
  title   = 7.5,  # legend / axis titles
  text    = 7,    # legend labels, axis tick labels
  note    = 6.5,  # smallest permitted text (annotations, footnotes)
  key_title = 7.5,  # in-panel colour keys (kept compact so they stay subordinate
  key_text  = 7    #   to the data they explain)
)

# ---------------------------------------------------------------------------
# Colour
# ---------------------------------------------------------------------------
fig_col <- list(
  ink        = "#1B2430",  # primary text
  muted      = "#5A6472",  # secondary text, tick labels
  rule       = "#C3C9D1",  # axis lines, separators, outlines of no-data areas
  grid       = "#E7EAEE",  # optional major gridlines
  paper      = "#FFFFFF",
  border     = "#FFFFFF",  # country borders between filled polygons
  zero       = "#DEDEDC",  # observed zero (data present, value = 0)
  not_in_universe = "#FFFFFF"  # outside the analytical universe: hollow + rule outline
)

# Sequential navy ramp (light -> dark). Used for counts and for the
# "above 1" arm of ratio scales. Lightness steps are approximately even.
fig_navy <- c("#CFDCEC", "#9CB6D6", "#6489BA", "#335A91", "#122C54")

# Diverging scale for ratios centred on 1 (O/E, and later OR/IRR displays),
# with reciprocal-symmetric classes: 4 warm classes below 1 (dark -> light)
# and 4 navy classes above 1 (light -> dark). Lightness is mirrored around 1.
fig_diverging <- c("#7E4325", "#A8653F", "#C99472", "#E6CBB4",
                   "#CFDCEC", "#94B0D3", "#4F78AE", "#14305A")

# Observed-versus-reference pair (e.g. observed participation share vs the
# burden-proportional reference share): dark navy for what was observed, a
# light cool slate for the reference. Strong luminance contrast, so the pair
# also separates in greyscale and for colour-vision deficiency.
fig_pair <- c(observed = "#14305A", reference = "#AEB7C2")

# Continental "world region" colours for country scatterplots (the project's
# region_plot_mapping.csv grouping; not WHO regions). Paul Tol's muted
# colour-blind-safe scheme, as in the original socioeconomic figure.
fig_world_region <- c("Africa" = "#332288", "Asia" = "#DDCC77", "Europe" = "#117733",
                      "North America" = "#88CCEE",
                      "Latin America and the Caribbean" = "#CC6677", "Oceania" = "#AA4499")

# WHO regions for country scatterplots (same six regions as Figure 3), Paul
# Tol's muted colour-blind-safe scheme.
fig_who_region <- c("Africa" = "#332288", "Americas" = "#CC6677",
                    "Eastern Mediterranean" = "#DDCC77", "Europe" = "#117733",
                    "South-East Asia" = "#88CCEE", "Western Pacific" = "#AA4499")

# World Bank income groups as an ordinal sequential scale on the navy ramp
# (high income darkest), consistent with Figures 2-3; a neutral grey for
# unclassified. Avoids warm hues that mean WHO regions in Figure 4.
fig_income <- c("High income" = "#122C54", "Upper-middle income" = "#4F78AE",
                "Lower-middle income" = "#9CB6D6", "Low income" = "#D6E1EE",
                "Income group unavailable" = "#B9BFC7")

# Qualitative series for grouped bars / multi-series plots:
# navy, mid-blue, slate, warm accent. Use in this order; max 4 series.
fig_series <- c("#14305A", "#6489BA", "#8A939E", "#A8653F")

# ---------------------------------------------------------------------------
# Line weights (ggplot linewidth units; 0.1 ~ 0.21 pt)
# ---------------------------------------------------------------------------
fig_lwd <- list(
  border = 0.12,  # country borders (~0.25 pt hairline)
  outline = 0.12, # hollow no-data outlines
  axis   = 0.25,  # axis lines and ticks (~0.5 pt)
  data   = 0.45,  # data lines, error bars (~1 pt)
  ref    = 0.3    # reference lines (e.g. O/E = 1, OR = 1)
)

# ---------------------------------------------------------------------------
# Export dimensions (mm) - Springer Nature artwork guidelines
# ---------------------------------------------------------------------------
fig_width <- c(single = 84, one_half = 129, double = 174)
fig_max_height <- 234
fig_dpi <- 600

# ---------------------------------------------------------------------------
# Themes
# ---------------------------------------------------------------------------
# General theme for charts (bars, forest/regression plots, scatter).
theme_fig <- function() {
  theme_minimal(base_family = fig_font, base_size = fig_size$text) %+replace%
    theme(
      text = element_text(colour = fig_col$ink),
      axis.text = element_text(size = fig_size$text, colour = fig_col$muted),
      axis.title = element_text(size = fig_size$title, colour = fig_col$ink),
      axis.line = element_line(colour = fig_col$rule, linewidth = fig_lwd$axis),
      axis.ticks = element_line(colour = fig_col$rule, linewidth = fig_lwd$axis),
      axis.ticks.length = unit(1.2, "mm"),
      panel.grid = element_blank(),
      legend.title = element_text(size = fig_size$title, face = "bold"),
      legend.text = element_text(size = fig_size$text),
      legend.key.size = unit(3, "mm"),
      strip.text = element_text(size = fig_size$title, face = "bold", hjust = 0),
      plot.tag = element_text(size = fig_size$tag, face = "bold", family = fig_font),
      plot.title = element_text(size = fig_size$heading, face = "bold", hjust = 0,
                                margin = margin(b = 2)),
      plot.margin = margin(2, 2, 2, 2, "mm"),
      plot.background = element_rect(fill = fig_col$paper, colour = NA),
      complete = TRUE
    )
}

# Map theme: no axes, no graticule, no background.
theme_fig_map <- function() {
  theme_void(base_family = fig_font, base_size = fig_size$text) %+replace%
    theme(
      text = element_text(colour = fig_col$ink),
      legend.position = "none",
      plot.margin = margin(1.5, 0, 0, 0, "mm"),
      plot.background = element_rect(fill = fig_col$paper, colour = NA),
      complete = TRUE
    ) + fig_heading_theme()
}

# Panel heading: bold lowercase panel letter (plot.tag) followed on the same
# line by a short plain descriptor (plot.title):  "a   Country-trial participations".
# Plain text only (no plotmath), so exported PDFs embed only Arial subsets.
fig_heading_theme <- function(indent_mm = 4.2) {
  theme(
    plot.tag = element_text(family = fig_font, face = "bold", size = fig_size$tag,
                            colour = fig_col$ink, hjust = 0, vjust = 1),
    plot.tag.location = "plot",
    plot.tag.position = c(0, 1),
    plot.title = element_text(family = fig_font, size = fig_size$heading, face = "plain",
                              colour = fig_col$ink, hjust = 0, vjust = 1,
                              margin = margin(t = 0.45, b = 1.8, l = indent_mm, unit = "mm")),
    plot.title.position = "plot"
  )
}
fig_heading <- function(tag, text) labs(tag = tag, title = text)

# ---------------------------------------------------------------------------
# Binned key
# ---------------------------------------------------------------------------
# Returns ggplot layers that draw a stepped key in the plot's own data
# coordinates, so it can sit inside open space of a map (or chart) at an exact
# printed size. `mm` is the number of data units per printed millimetre.
# Layout (top to bottom): bold title; contiguous class swatches with labels
# centred beneath; then the "special" categories (e.g. observed zero, outside
# the analytical universe) as separate boxed swatches on their own row, so they
# are never read as part of the ordered scale.
#   labels, colours : the ordered data classes; labels are centred under each
#                     swatch (use for discrete ranges such as "3-5")
#   breaks          : optional n-1 boundary labels drawn at the internal swatch
#                     edges instead of `labels` (use for continuous ratios;
#                     state the lower-inclusive convention in the caption)
#   specials        : data.frame(label, fill, outline), one per row below
fig_binned_key <- function(x0, y_top, mm, labels, colours, title, specials = NULL,
                           breaks = NULL, swatch_w = 7, swatch_h = 2.2,
                           special_w = 3.2) {
  n <- length(colours)
  y_sw <- y_top - 3.6 * mm                       # top of swatches
  bins <- data.frame(xmin = x0 + (seq_len(n) - 1) * swatch_w * mm,
                     xmax = x0 + seq_len(n) * swatch_w * mm,
                     ymin = y_sw - swatch_h * mm, ymax = y_sw, fill = colours)
  layers <- list(
    annotate("text", x = x0, y = y_top, label = title, hjust = 0, vjust = 1,
             family = fig_font, fontface = "bold", size = fig_size$key_title / .pt,
             colour = fig_col$ink),
    annotate("rect", xmin = bins$xmin, xmax = bins$xmax, ymin = bins$ymin,
             ymax = bins$ymax, fill = bins$fill, colour = fig_col$paper,
             linewidth = 0.15)
  )
  y_lab <- bins$ymin[1] - 0.9 * mm
  if (is.null(breaks)) {
    layers <- c(layers, list(
      annotate("text", x = (bins$xmin + bins$xmax) / 2, y = y_lab, label = labels,
               vjust = 1, family = fig_font, size = fig_size$key_text / .pt,
               colour = fig_col$ink)))
  } else {
    edges <- bins$xmax[-n]
    layers <- c(layers, list(
      annotate("segment", x = edges, xend = edges, y = bins$ymin[1],
               yend = bins$ymin[1] - 0.6 * mm, colour = fig_col$muted,
               linewidth = fig_lwd$axis),
      annotate("text", x = edges, y = y_lab - 0.2 * mm, label = breaks, vjust = 1,
               family = fig_font, size = fig_size$key_text / .pt, colour = fig_col$ink)))
  }
  if (!is.null(specials)) {
    y_sp <- bins$ymin[1] - 5.0 * mm              # top of first special row
    for (i in seq_len(nrow(specials))) {
      y <- y_sp - (i - 1) * (swatch_h + 1.2) * mm
      layers <- c(layers, list(
        annotate("rect", xmin = x0, xmax = x0 + special_w * mm,
                 ymin = y - swatch_h * mm, ymax = y,
                 fill = specials$fill[i], colour = specials$outline[i],
                 linewidth = fig_lwd$outline * 1.6),
        annotate("text", x = x0 + (special_w + 1.2) * mm, y = y - swatch_h / 2 * mm,
                 label = specials$label[i], hjust = 0, vjust = 0.5, family = fig_font,
                 size = fig_size$key_text / .pt, colour = fig_col$ink)))
    }
  }
  layers
}

# ---------------------------------------------------------------------------
# Figure-level key
# ---------------------------------------------------------------------------
# One row of swatch + label pairs, sized in absolute millimetres and placed
# above all panels (e.g. with patchwork::wrap_elements(full = ...)), for keys
# that apply to every panel of a figure. Left-aligned with the panel letters.
fig_key_row <- function(labels, fills, swatch_w = 4, swatch_h = 2.4, gap_mm = 7,
                        pad_mm = 1.5, x0_mm = 0) {
  kids <- list()
  x <- unit(x0_mm, "mm")
  for (i in seq_along(labels)) {
    txt <- textGrob(labels[i], x = x + unit(swatch_w + pad_mm, "mm"), y = 0.5, just = "left",
                    gp = gpar(fontfamily = fig_font, fontsize = fig_size$text, col = fig_col$ink))
    kids <- c(kids, list(
      rectGrob(x = x, y = 0.5, width = unit(swatch_w, "mm"), height = unit(swatch_h, "mm"),
               just = c("left", "centre"), gp = gpar(fill = fills[i], col = NA)),
      txt))
    x <- x + unit(swatch_w + pad_mm + gap_mm, "mm") + grobWidth(txt)
  }
  gTree(children = do.call(gList, kids))
}

# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------
# Writes an editable SVG (text kept as <text> elements), a vector PDF rendered
# from that SVG with librsvg (fonts embedded as subsets; does not depend on R's
# optional cairo device) and a 600-dpi PNG with identical geometry.
fig_save <- function(plot, stem, width_mm, height_mm) {
  dir.create(dirname(stem), recursive = TRUE, showWarnings = FALSE)
  w <- width_mm / 25.4
  h <- height_mm / 25.4
  ggsave(paste0(stem, ".svg"), plot, width = w, height = h, units = "in",
         device = svglite::svglite, bg = fig_col$paper, fix_text_size = FALSE)
  # 72 pt per inch: PDF page size equals the SVG's physical size.
  rsvg::rsvg_pdf(paste0(stem, ".svg"), paste0(stem, ".pdf"),
                 width = round(w * 72), height = round(h * 72))
  ggsave(paste0(stem, ".png"), plot, width = w, height = h, units = "in",
         device = ragg::agg_png, dpi = fig_dpi, bg = fig_col$paper)
  invisible(paste0(stem, c(".pdf", ".svg", ".png")))
}
