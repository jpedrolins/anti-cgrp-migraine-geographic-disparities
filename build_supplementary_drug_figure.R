#!/usr/bin/env Rscript
# Use the harmonized record-country pairs and the two previously reviewed agent updates.
suppressPackageStartupMessages({library(dplyr);library(ggplot2);library(patchwork);library(tidyr);library(jsonlite)})
root <- normalizePath(".",mustWork=TRUE)
source_plot <- file.path(root,"source/figure4_geographic_reach_by_drug.R")
records <- fromJSON(file.path(root,"source/study_agent_records.json"))
pairs <- read.csv(file.path(root,"source/country_record_pairs.csv"))
records$agent[records$id=="NCT04659226"] <- "erenumab"
records$agent[records$id=="NCT07071506"] <- "fremanezumab"
approved <- c("erenumab","fremanezumab","galcanezumab","eptinezumab")
category <- function(x) {s<-intersect(trimws(tolower(unlist(strsplit(x,";",fixed=TRUE)))),approved);if(length(s)>1)"Multiple anti-CGRP mAbs" else if(length(s)==0)"Unspecified anti-CGRP mAb" else paste0(toupper(substr(s,1,1)),substring(s,2))}
records$drug <- vapply(records$agent,category,character(1))
stopifnot(nrow(records)==108,!anyDuplicated(records$id),nrow(pairs)==453)
pairs$drug <- records$drug[match(pairs$study_id,records$id)]
stopifnot(!anyNA(pairs$drug))
drug_order <- c("Erenumab","Eptinezumab","Fremanezumab","Galcanezumab","Multiple anti-CGRP mAbs")
figure_data <- do.call(rbind,lapply(drug_order,function(g){z<-pairs[pairs$drug==g,]; n<-nrow(z); data.frame(drug=g,trials=sum(records$drug==g),countries_reached=length(unique(z$country_iso3)),trial_country_participations=n,HIC=100*sum(z$income=="HIC")/n,UMIC=100*sum(z$income=="UMIC")/n,LMIC=100*sum(z$income=="LMIC")/n,LIC=100*sum(z$income=="LIC")/n,category_type=if(g=="Multiple anti-CGRP mAbs") "Combined or unspecified" else "Individual mAb")}))
stopifnot(sum(figure_data$trial_country_participations)==452,all(figure_data$LIC==0))
base_font <- "Arial"
lines<-readLines(source_plot,warn=FALSE);first<-grep('^axis_labels <-',lines);last<-grep('^png_file <-',lines);stopifnot(length(first)==1,length(last)==1,last>first)
eval(parse(text=lines[first:(last-1)]))
ggsave(file.path(root,"Supplementary_Figure_S1_mab_2023_revision.png"),figure_4,width=180,height=112,units="mm",dpi=300,bg="white")
write.csv(figure_data,file.path(root,"results/figure_s1_mab_data.csv"),row.names=FALSE)
