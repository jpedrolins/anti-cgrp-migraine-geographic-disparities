# Exploratory comparison: a country–trial pair is one observation.
# The regression uses working independence and a sandwich variance clustered by trial.
library(geepack)
trials <- read.csv('trial_level_108.csv', stringsAsFactors = FALSE)
pairs <- read.csv('country_record_453.csv', stringsAsFactors = FALSE)
stopifnot(nrow(trials) == 108, nrow(pairs) == 453,
          !anyDuplicated(trials$study_id), !anyDuplicated(pairs[c('study_id','country_iso3')]),
          all(pairs$income %in% c('HIC','UMIC','LMIC','LIC')))

dat <- pairs[order(pairs$study_id), ]
dat$cluster_id <- match(dat$study_id, unique(dat$study_id))
dat$non_hic <- as.integer(dat$income != 'HIC')
dat$post <- as.integer(dat$fda_period == 'On/after approval')
stopifnot(all(dat$fda_period %in% c('Before approval','On/after approval')),
          sum(dat$post == 0) == 193, sum(dat$post == 1) == 260,
          sum(dat$non_hic[dat$post == 0]) == 21,
          sum(dat$non_hic[dat$post == 1]) == 40)
fit <- geeglm(non_hic ~ post, id = cluster_id, family = binomial('logit'),
              corstr = 'independence', std.err = 'san.se', data = dat)
z <- summary(fit)$coefficients['post', ]
estimate <- z[['Estimate']]; se <- z[['Std.err']]
cat('GEEs use', length(unique(dat$study_id)), 'trials with at least one eligible country.\n')
cat('Non-HIC proportion before:', mean(dat$non_hic[dat$post == 0]), '\n')
cat('Non-HIC proportion after:', mean(dat$non_hic[dat$post == 1]), '\n')
cat('Difference in percentage points:', 100 * (mean(dat$non_hic[dat$post == 1]) - mean(dat$non_hic[dat$post == 0])), '\n')
cat('OR post vs before:', exp(estimate), '95% CI', exp(estimate - 1.96 * se), exp(estimate + 1.96 * se), '\n')
cat('Robust Wald p:', z[['Pr(>|W|)']], '\n')

# Resample entire trial clusters independently within period, including two records
# with zero eligible countries. This estimates the participation-weighted difference.
tt <- aggregate(cbind(non_hic, total = rep(1, nrow(dat))) ~ study_id + fda_period,
                data = dat, FUN = sum)
full <- merge(trials[c('study_id','fda_period')], tt,
              by = c('study_id','fda_period'), all.x = TRUE)
full$non_hic[is.na(full$non_hic)] <- 0
full$total[is.na(full$total)] <- 0
pre <- full[full$fda_period == 'Before approval', ]; post <- full[full$fda_period == 'On/after approval', ]
stopifnot(nrow(pre) == 39, nrow(post) == 69,
          sum(pre$total) == 193, sum(post$total) == 260)
set.seed(20261112)
boot <- replicate(20000, {
  a <- pre[sample.int(nrow(pre), nrow(pre), replace = TRUE), ]
  b <- post[sample.int(nrow(post), nrow(post), replace = TRUE), ]
  if (sum(a$total) == 0 || sum(b$total) == 0) return(NA_real_)
  100 * (sum(b$non_hic)/sum(b$total) - sum(a$non_hic)/sum(a$total))
})
stopifnot(!anyNA(boot))
cat('Trial-stratified bootstrap percentile 95% CI of risk difference (pp):',
    quantile(boot, .025), quantile(boot, .975), '\n')
cat('Method note: one-way clustering does not account for repeated countries across trials; observational period is not randomized.\n')
