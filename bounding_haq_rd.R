# Extend the documented bounding analysis to HAQ/R&D, retaining each country sample.
suppressPackageStartupMessages({library(MASS);library(sandwich)})
d<-read.csv('results/country_analytic_with_yld_bounds_v1.csv',check.names=FALSE)
c<-read.csv('covariates_haq_rd.csv')
d$haq<-(c$haq_2019[match(d$ISO3,c$country_iso3)]-80)/10
d$rd<-log2(c$rd_value[match(d$ISO3,c$country_iso3)])
stopifnot(nrow(d)==194,sum(d$observed)==453)
out<-list()
for(s in c('point','lower','upper'))for(v in c('haq','rd')){
 z<-d[is.finite(d[[v]]),];z$expected<-z[[paste0('expected_',s)]]
 m<-glm.nb(as.formula(paste('observed ~',v,'+ offset(log(expected))')),data=z,control=glm.control(maxit=1000))
 b<-coef(m)[[2]];se<-sqrt(vcovHC(m,type='HC3')[2,2]);crit<-qnorm(.975)
 out[[length(out)+1]]<-data.frame(scenario=s,model=if(v=='haq')'HAQ per 10 points' else 'R&D per doubling',n_countries=nrow(z),participations=sum(z$observed),IRR=exp(b),wald_lower_95=exp(b-crit*se),wald_upper_95=exp(b+crit*se),p=2*pnorm(-abs(b/se)),converged=m$converged)
}
out<-do.call(rbind,out);stopifnot(all(out$converged));write.csv(out,'results/bounding_haq_rd.csv',row.names=FALSE)
