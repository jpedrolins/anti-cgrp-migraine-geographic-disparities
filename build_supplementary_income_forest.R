#!/usr/bin/env Rscript
# Reuse the earlier forest-plot functions with the current NB models.
suppressPackageStartupMessages({library(dplyr);library(ggplot2);library(patchwork);library(sandwich)})
root <- normalizePath(".",mustWork=TRUE)
source_plot <- file.path(root,"source/figure3_income_group_associations.R")
d <- read.csv(file.path(root,"results/country_analytic_with_yld_bounds_v1.csv"),check.names=FALSE)
nb <- read.csv(file.path(root,"results/negative_binomial_models_all_scenarios.csv"))
nb <- nb[nb$scenario=="Point",]
comparison_order <- c("HIC vs UMIC/LMIC/LIC","HIC vs LMIC/LIC","HIC vs UMIC","HIC vs LMIC","HIC vs LIC")
subgroups <- list(c("Upper-middle income","Lower-middle income","Low income"),c("Lower-middle income","Low income"),"Upper-middle income","Lower-middle income","Low income")
or_data <- do.call(rbind,lapply(seq_along(subgroups),function(i){
 z <- d[d[["Income group (FY2019)"]] %in% c("High income",subgroups[[i]]),]
 if(i==5) return(data.frame(Comparison=comparison_order[i],estimate=NA,lower=NA,upper=NA,p_value=NA,estimate_label="Not estimable"))
 z$hic <- as.integer(z[["Income group (FY2019)"]]=="High income")
 m <- glm(I(observed>0)~hic,data=z,family=binomial()); b<-unname(coef(m)[2]); s<-sqrt(diag(vcovHC(m,type="HC3")))[2]
 v<-exp(c(b,b-qnorm(.975)*s,b+qnorm(.975)*s))
 data.frame(Comparison=comparison_order[i],estimate=v[1],lower=v[2],upper=v[3],p_value=2*pnorm(-abs(b/s)),estimate_label=sprintf("%.2f (%.2f–%.2f)",v[1],v[2],v[3]))
}))
irr_data <- do.call(rbind,lapply(comparison_order,function(n){z<-nb[nb$model==n,]; stopifnot(nrow(z)==1); data.frame(Comparison=n,estimate=z$IRR,lower=z$wald_lower_95,upper=z$wald_upper_95,p_value=z$p,estimate_label=if(is.na(z$IRR)) "Not estimable" else sprintf("%.2f (%.2f–%.2f)",z$IRR,z$wald_lower_95,z$wald_upper_95))}))
base_font <- "Arial"
lines <- readLines(source_plot,warn=FALSE); first <- grep('^make_forest_panel <- function',lines); last <- grep('^png_file <-',lines)
stopifnot(length(first)==1,length(last)==1,last>first)
eval(parse(text=lines[first:(last-1)]))
ggsave(file.path(root,"Supplementary_Figure_S2_income_forest_GBD2023.png"),figure_3,width=180,height=110,units="mm",dpi=300,bg="white")
write.csv(or_data,file.path(root,"results/figure_s2_logistic.csv"),row.names=FALSE,na="")
write.csv(irr_data,file.path(root,"results/figure_s2_negative_binomial.csv"),row.names=FALSE,na="")
