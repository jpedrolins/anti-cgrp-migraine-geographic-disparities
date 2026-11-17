#!/usr/bin/env Rscript
# Reproduce Figure 2 using the original 2023 WHO-country data and binning.
# Only layout and legibility are changed; the original source and figures remain untouched.
suppressPackageStartupMessages({library(dplyr); library(readr); library(sf); library(ggplot2); library(patchwork)})
src <- '.'
out <- '.'
d <- read_csv(file.path(src,'results/country_expected_oe_all_scenarios.csv'), show_col_types=FALSE) |>
  filter(scenario == 'Point') |>
  transmute(country_iso3 = ISO3, participations = observed, oe = oe)
stopifnot(nrow(d) == 194, sum(d$participations) == 453, !anyDuplicated(d$country_iso3),
          sum(d$participations > 0) == 47)
world <- st_read(file.path(src,'source/natural_earth/ne_50m_admin_0_countries.shp'), quiet=TRUE) |>
  filter(ADMIN != 'Antarctica') |>
  mutate(country_iso3 = if_else(ISO_A3 != '-99' & nchar(ISO_A3) == 3, ISO_A3, ADM0_A3)) |>
  select(country_iso3, geometry) |> left_join(d, by='country_iso3') |>
  st_transform('ESRI:54030')
base <- theme_void(base_family='Arial',base_size=10) +
  theme(legend.position='bottom', legend.title=element_text(face='bold',size=10),
        legend.text=element_text(size=9.5), legend.key.height=grid::unit(4,'mm'),
        legend.key.width=grid::unit(7,'mm'), legend.spacing.x=grid::unit(4,'mm'),
        plot.margin=margin(3,4,3,4), plot.tag=element_text(face='bold',size=13),
        plot.tag.position=c(0.09, 0.94))

# These boundaries and color values match the original horizontal figure.
levels_a <- c('0','1–2','3–5','6–14','15–29','≥30')
colors_a <- setNames(c('#E2E2E2','#DCEAF5','#AFCFE6','#6BAED6','#3182BD','#08519C'),levels_a)
levels_b <- c('No participation','<0.5','0.5–<1','1–<2','2–<5','5–<10','≥10')
colors_b <- setNames(c('#E2E2E2','#B35806','#F1A340','#D8E7F1','#92C5DE','#4393C3','#2166AC'),levels_b)

map_a <- world |> mutate(category=case_when(is.na(participations)~NA_character_,participations==0~'0',
  TRUE~as.character(cut(participations,breaks=c(0,2,5,14,29,Inf),
    labels=levels_a[-1],include.lowest=TRUE,right=TRUE))))
map_b <- world |> mutate(category=case_when(is.na(participations)~NA_character_,participations==0~levels_b[1],
  oe<.5~levels_b[2],oe<1~levels_b[3],oe<2~levels_b[4],oe<5~levels_b[5],oe<10~levels_b[6],TRUE~levels_b[7]))
a <- ggplot(map_a) + geom_sf(aes(fill=factor(category,levels=levels_a)),color='white',linewidth=.08) +
  scale_fill_manual(values=colors_a,breaks=levels_a,na.value='#F7F7F7',drop=FALSE,
    name='Country–record participations, n',guide=guide_legend(ncol=3,byrow=TRUE,title.position='top')) +
  coord_sf(datum=NA,expand=FALSE) + labs(tag='(a)') + base
b <- ggplot(map_b) + geom_sf(aes(fill=factor(category,levels=levels_b)),color='white',linewidth=.08) +
  scale_fill_manual(values=colors_b,breaks=levels_b,na.value='#F7F7F7',drop=FALSE,
    name='Observed-to-expected participation ratio',guide=guide_legend(ncol=3,byrow=TRUE,title.position='top')) +
  coord_sf(datum=NA,expand=FALSE) + labs(tag='(b)') + base
p <- a / b
ggsave(file.path(out,'Figure_2_vertical_inset_preview.png'),p,width=8,height=9.35,dpi=300,bg='white')
cat('WHO members:', nrow(d), '\nObserved participations:',sum(d$participations),
    '\nParticipating countries:',sum(d$participations>0),'\n')
cat('Input SHA-256 must be recorded alongside the untouched source files.\n')
