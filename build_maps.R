#!/usr/bin/env Rscript
suppressPackageStartupMessages({library(dplyr);library(readr);library(sf);library(ggplot2);library(patchwork)})
args <- commandArgs(trailingOnly=TRUE)
out <- if(length(args)) normalizePath(args[1],mustWork=TRUE) else normalizePath(".",mustWork=TRUE)
d <- read_csv(file.path(out,"results/country_expected_oe_all_scenarios.csv"),show_col_types=FALSE) %>% filter(scenario == "Point") %>% transmute(country_iso3 = ISO3, participations = observed, oe = oe)
stopifnot(nrow(d) == 194, sum(d$participations) == 453, !anyDuplicated(d$country_iso3))
world_file <- if(length(args)>1) args[2] else file.path(out,"source/natural_earth/ne_50m_admin_0_countries.shp")
world <- st_read(world_file,quiet=TRUE) %>% filter(ADMIN!="Antarctica") %>% mutate(country_iso3=if_else(ISO_A3!="-99" & nchar(ISO_A3)==3,ISO_A3,ADM0_A3)) %>% select(country_iso3,geometry) %>% left_join(d,by="country_iso3") %>% st_transform("ESRI:54030")
base <- theme_void(base_family="Arial",base_size=10)+theme(legend.position="bottom",legend.title=element_text(face="bold",size=8),legend.text=element_text(size=7.5),legend.key.height=grid::unit(3.2,"mm"),legend.key.width=grid::unit(5,"mm"),plot.margin=margin(4,4,4,4),plot.tag=element_text(face="bold",size=11))
oelevels<-c("No participation","<0.5","0.5–<1","1–<2","2–<5","5–<10","≥10")
oecolors<-c("#E2E2E2","#B35806","#F1A340","#D8E7F1","#92C5DE","#4393C3","#2166AC")
parts <- function(metric,breaks,labels,title,tag){
 z<-world %>% mutate(category=case_when(is.na(.data[[metric]])~NA_character_,.data[[metric]]==0~"0",TRUE~as.character(cut(.data[[metric]],breaks=breaks,labels=labels,include.lowest=TRUE,right=TRUE))))
 levels<-c("0",labels);colors<-c("#E2E2E2","#DCEAF5","#AFCFE6","#6BAED6","#3182BD","#08519C")
 ggplot(z)+geom_sf(aes(fill=factor(category,levels=levels)),color="white",linewidth=.08)+scale_fill_manual(values=setNames(colors,levels),breaks=levels,na.value="#F7F7F7",drop=FALSE,name=title,guide=guide_legend(ncol=3,byrow=TRUE,title.position="top"))+coord_sf(datum=NA,expand=FALSE)+labs(tag=tag)+base
}
oes <- function(metric,oe,tag){
 z<-world %>% mutate(category=case_when(is.na(.data[[metric]])~NA_character_,.data[[metric]]==0~oelevels[1],.data[[oe]]<.5~oelevels[2],.data[[oe]]<1~oelevels[3],.data[[oe]]<2~oelevels[4],.data[[oe]]<5~oelevels[5],.data[[oe]]<10~oelevels[6],TRUE~oelevels[7]))
 ggplot(z)+geom_sf(aes(fill=factor(category,levels=oelevels)),color="white",linewidth=.08)+scale_fill_manual(values=setNames(oecolors,oelevels),breaks=oelevels,na.value="#F7F7F7",drop=FALSE,name="Observed-to-expected participation ratio",guide=guide_legend(ncol=3,byrow=TRUE,title.position="top"))+coord_sf(datum=NA,expand=FALSE)+labs(tag=tag)+base
}
a<-parts("participations",c(0,2,5,14,29,Inf),c("1–2","3–5","6–14","15–29","≥30"),"Country–record participations, n","(a)")
b<-oes("participations","oe","(b)")
p<-a+b
ggsave(file.path(out,"Figure_2_country_record_GBD2023_year2023_draft.png"),p,width=10,height=4.5,dpi=300,bg="white")
