#!/usr/bin/env Rscript
# Reuse the previously reviewed bar-plot expression with updated burden estimates.
suppressPackageStartupMessages({library(dplyr); library(ggplot2); library(tidyr); library(readr)})
root <- normalizePath(".",mustWork=TRUE)
src <- file.path(root,"source/figure2_income_representation.R")
groups <- read.csv(file.path(root,"results/who_income_expected_oe_all_scenarios.csv"))
order <- c("High income", "Upper-middle income", "Lower-middle income", "Low income")
z <- groups[groups$scenario == "Point" & groups$dimension == "income" & groups$group %in% order, ]
z <- z[match(order,z$group), ]
stopifnot(nrow(z)==4, sum(z$observed)==453)
plot_data <- data.frame(income_group=factor(z$group, levels=order),
  trial_country_participations=100*z$observed/453,
  migraine_burden_ylds=100*z$burden_share)
plot_long <- plot_data %>% pivot_longer(cols=c(trial_country_participations,migraine_burden_ylds),
  names_to="measure",values_to="percentage") %>% mutate(measure=factor(measure,
  levels=c("trial_country_participations","migraine_burden_ylds"),
  labels=c("Trial-country participations","Migraine burden (YLDs)")))
base_font <- "Arial"
lines <- readLines(src,warn=FALSE)
start <- grep('^figure_2 <- ggplot\\(', lines)
end <- grep('^png_file <-', lines)
stopifnot(length(start)==1,length(end)==1,end>start)
eval(parse(text=lines[start:(end-1)]))
ggsave(file.path(root,"Figure_3_income_GBD2023_year2023_draft.png"),figure_2,
       width=160,height=92,units="mm",dpi=300,bg="white")
write.csv(plot_data,file.path(root,"results/figure3_income_data.csv"),row.names=FALSE)
