# Reproduce the exploratory preview from the audited 107-record release.
library(ggplot2)

trial_path <- 'trial_level_108.csv'
pair_path <- 'country_record_453.csv'
out <- '.'
trials <- read.csv(trial_path, stringsAsFactors = FALSE, check.names = FALSE)
pairs <- read.csv(pair_path, stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(nrow(trials) == 108, nrow(pairs) == 453,
          !anyDuplicated(trials$study_id),
          !anyDuplicated(pairs[c('study_id', 'country_iso3')]),
          all(pairs$income %in% c('HIC', 'UMIC', 'LMIC', 'LIC')))

# A country contributes once for each eligible registry record in which it appears.
joined <- merge(pairs, trials[c('study_id', 'start_date_harmonized',
                               'start_date_precision', 'start_date_type_raw', 'fda_period')],
                by = 'study_id', all.x = TRUE, sort = FALSE,
                suffixes = c('_pair', '_trial'))
stopifnot(nrow(joined) == 453, !anyNA(joined$start_date_harmonized))
stopifnot(all(joined$fda_period_pair == joined$fda_period_trial))
joined$fda_period <- joined$fda_period_trial
joined$year <- as.integer(substr(joined$start_date_harmonized, 1, 4))
stopifnot(all(joined$year >= 2011 & joined$year <= 2026),
          !any(joined$fda_period == 'Missing or insufficient precision'))
joined$income_binary <- ifelse(joined$income == 'HIC', 'High-income countries',
                               'Non-HIC (UMIC, LMIC, LIC)')

# Split the transition year at the exact FDA approval, retaining unequal lengths.
joined$bin <- as.character(joined$year)
joined$bin[joined$year == 2018 & joined$fda_period == 'Before approval'] <- '2018 pre'
joined$bin[joined$year == 2018 & joined$fda_period == 'On/after approval'] <- '2018 post'
bins <- c(as.character(2011:2017), '2018 pre', '2018 post', as.character(2019:2026))
joined$bin <- factor(joined$bin, levels = bins)
agg <- as.data.frame(table(bin = joined$bin,
                           income = factor(joined$income_binary,
                                           levels = c('High-income countries', 'Non-HIC (UMIC, LMIC, LIC)'))))
names(agg)[3] <- 'participations'
stopifnot(sum(agg$participations) == 453,
          sum(agg$participations[agg$income == 'High-income countries']) == 392,
          sum(agg$participations[agg$income == 'Non-HIC (UMIC, LMIC, LIC)']) == 61,
          sum(agg$participations[agg$bin %in% bins[1:8]]) == 193,
          sum(agg$participations[agg$bin %in% bins[9:17]]) == 260)
agg$x <- as.integer(agg$bin)
agg$group <- ifelse(agg$income == 'High-income countries', 'HIC', 'Non-HIC')

p <- ggplot(agg, aes(x = x, y = participations, fill = income)) +
  annotate('rect', xmin = .5, xmax = 8.5, ymin = -Inf, ymax = Inf,
           fill = '#F5F6F8', colour = NA) +
  geom_col(position = position_dodge(width = .76), width = .69, colour = NA) +
  geom_vline(xintercept = 8.5, linetype = 'dashed', linewidth = .55, colour = '#555555') +
  annotate('text', x = 8.65, y = max(agg$participations) * 1.22,
           label = 'FDA approval of erenumab\n17 May 2018', hjust = 0, vjust = 1,
           size = 3.2, colour = '#333333') +
  scale_fill_manual(values = c('High-income countries' = '#225B85',
                               'Non-HIC (UMIC, LMIC, LIC)' = '#C17B36'),
                    name = NULL) +
  scale_x_continuous(breaks = seq_along(bins),
                     labels = c(as.character(2011:2017), '2018\npre', '2018\npost',
                                as.character(2019:2025), '2026*'),
                     expand = expansion(add = c(.6, .6))) +
  scale_y_continuous(expand = expansion(mult = c(0, .27)),
                     breaks = scales::breaks_pretty(n = 5)) +
  labs(title = 'Country–trial participation over time, by income group',
       subtitle = 'Eligible anti-CGRP monoclonal antibody trials for migraine',
       x = 'Study start year', y = 'Country–trial participations, n',
       caption = paste0('2018 is split into periods before and on/after 17 May; the intervals are not of equal length.\n',
                        '*2026 is incomplete in the registry snapshot. Dates include actual and estimated starts.')) +
  theme_minimal(base_size = 12, base_family = 'sans') +
  theme(plot.title = element_text(face = 'bold', size = 15, margin = margin(b = 5)),
        plot.subtitle = element_text(size = 11, colour = '#444444', margin = margin(b = 12)),
        axis.title = element_text(size = 11), axis.text.x = element_text(size = 9, colour = '#333333'),
        axis.text.y = element_text(size = 10, colour = '#333333'),
        panel.grid.major.x = element_blank(), panel.grid.minor = element_blank(),
        panel.grid.major.y = element_line(colour = '#E1E3E5', linewidth = .35),
        legend.position = 'top', legend.justification = 'left',
        legend.text = element_text(size = 10), legend.key.width = unit(1.15, 'cm'),
        plot.caption = element_text(hjust = 0, size = 9, colour = '#555555',
                                    margin = margin(t = 13)),
        plot.margin = margin(16, 22, 12, 16))

ggsave(file.path(out, 'temporal_income_preview.png'), p, width = 13, height = 6.3,
       dpi = 180, bg = 'white')
write.csv(agg[c('bin', 'group', 'participations')], file.path(out, 'temporal_counts.csv'),
          row.names = FALSE, na = '')
cat('Country–trial participations:', nrow(joined), '\n')
cat('Income:', paste(names(table(joined$income_binary)), table(joined$income_binary), collapse = '; '), '\n')
cat('Before/after:', paste(names(table(joined$fda_period)), table(joined$fda_period), collapse = '; '), '\n')
print(agg[c('bin','group','participations')], row.names = FALSE)
