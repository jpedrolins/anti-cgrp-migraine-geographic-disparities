# Public repository scope

Working research repository, 17 November 2026. The variable definitions below
describe the reviewed analytical dataset, including externally acquired inputs.
Restricted third-party input snapshots are not distributed in this repository.
See DATA_ACCESS.md and EXTERNAL_INPUTS.json. This is not the final Zenodo release.

# Codebook v4 country–record analysis with 108 records

## Adopted eligibility decision

NCT04361721 was included by explicit author adjudication on 16 November 2026.
The author considered its examination of the erenumab effect on pain threshold;
the linked publication also describes a baseline period and three scheduled
administrations. The original registry value `study_type_raw=OBSERVATIONAL` is
preserved. `study_type_harmonized=Interventional` is an analytical adjudication,
not a correction of the registry. `study_type_rule_id` identifies this conflict,
and no numerical confidence is assigned to the manual decision. See the audit.

The adopted dataset has 108 records, 453 WHO country–record participations,
106 records with an eligible country, 47 participating countries and 194 WHO
Member States. The only pair added to the previous version is NCT04361721–ITA.
The 24 excluded records, original independent screening decisions and 35
duplicate removals otherwise remain unchanged. Kappa is not recomputed as though
the original independent screening decisions had changed.

Migraine burden remains GBD 2023, reference year 2023. No city or site analyses
are included. The 22 explicitly removed country–record pairs remain excluded.

# Codebook v3 — 16 November 2026

Version 3 keeps the subgroup dataset codebook of 16 November 2026 (Part A) and the country-level covariates of 13 November 2026 (Part B) unchanged and adds the exploratory before/after-approval comparison of non-high-income participations reported in Results 4.7 (Part C). The earlier files (`CODEBOOK.md` and `CODEBOOK_v2_20261113.md`) are retained and not overwritten.

---

# Part A. Subgroup dataset (unchanged from 16 November 2026)

## Analytical population and unit
`trial_level_108.csv` contains one row per eligible interventional trial record (N=108). `country_record_453.csv` contains one row per unique record–country participation among the 194 WHO Member States (N=453; 47 participating countries). A record contributes at most once per country, irrespective of site count. Explicitly removed countries are excluded. The trial file retains NCT07655440, for which no country is assigned, and NCT04334408, for which the only listed country was removed; neither has a row in the pair file.

## Trial-level analytical variables
| Variable | Meaning and permitted values / source |
|---|---|
| study_id | Registry identifier and join key. |
| source, source_registry, source_snapshot | Registry and snapshot provenance; copied from the reviewed harmonized release. |
| phase_raw | Verbatim source phase. |
| phase_harmonized | Phase 1, Phase 2, Phase 2/3, Phase 3, Phase 4, Not applicable, or an explicit unresolved/missing value. Phase 2/3 is separate. The approved adjudications on 31 October 2026 are retained; see phase_pre_adjudication, phase_adjudication_source, phase_adjudication_note and phase_decision_date. |
| status_raw, status_harmonized | Source recruitment status and harmonized status; Unknown/not reported is explicit. Status is not publication status. |
| lead_sponsor_class_raw, sponsor_group_analysis | Registry sponsor class and analysis grouping. ClinicalTrials.gov INDUSTRY maps to Industry, OTHER maps to Non-industry under the prior project rule; sponsor class was not standardized in ICTRP-only records, categorized Unclear/not reported. Mapping is registry classification, not independent verification of funding. |
| anti_cgrp_agent_proposed | Earlier automatic proposal; retained without alteration for provenance. |
| agent_analysis | Current reviewed individual antibody or semicolon-separated list; Not specified denotes no named individual antibody. NCT04659226 = erenumab and NCT07071506 = fremanezumab according to the 1 November reviewed supplement. Individual antibody categories overlap. |
| start_date_raw, start_date_harmonized, start_date_precision | Source date, normalized date and its precision; a year–month is not treated as an exact day. |
| fda_period | Before approval, On/after approval, or Missing or insufficient precision. Cutoff is 17 May 2018, the FDA approval date of erenumab. For month-only dates, classify only if the complete possible month lies on one side of cutoff; otherwise uncertain. A start date is not country-specific recruitment timing. |
| participations | Number of eligible WHO member countries for that trial, including zero. |

Other columns are preserved from the phase-adjudicated harmonized source for provenance and should be interpreted using its original data dictionary; they are not newly derived in this analysis.

## Country–record file
`study_id` is the registry key; `country_iso3` is the standardized country code; `income` is the World Bank FY2019 income group (HIC, UMIC, LMIC, LIC, or Income unavailable); `who_region` is one of the six WHO regions. `phase`, `sponsor`, `recruitment_status`, `fda_period`, and `agents` repeat trial-level analysis variables to permit aggregation. The retained `source/country_analytic_with_yld_bounds_v1.csv` includes a legacy column labeled 2019: that column was not used here; the current project's migraine YLD measure is the GBD 2023 release for 2023. No YLD values are used in these descriptive subgroup calculations.

## Table calculations
`subgroup_table.csv` has one row per category. `trials_n` counts complete trial rows. `participations_n` counts country–record pairs. Income and WHO cells are counts and percentages of participations in the corresponding subgroup, not percentages of trials. A dash indicates a zero participation denominator. All non-antibody subgroup categories are mutually exclusive and sum to 108 trials and 453 pairs. Antibody counts overlap, so they must not be added to reconstruct totals. Percentages may not sum to exactly 100 because of rounding. No significance tests are performed.

## Provenance and reproducibility
Source snapshots in `source/` are copies, not modified originals. `validation.json` records SHA-256 hashes and total checks. Run `python3 summarize_current.py` with Python 3; only the standard library is required. These files are a new analysis release, not a destructive replacement of locked historical datasets. `source/agent_change_manuscript_audit.json` records the antibody reconciliation; the original adjudication log is in the project phase-audit release. The FDA approval date is documented at https://www.accessdata.fda.gov/drugsatfda_docs/nda/2018/761077Orig1s000Approv.pdf.

---

# Part B. Country-level indicators, Table 3 and Figure 4 (added 13 November 2026)

## Status
HDI and GDP per capita are prespecified covariates. The HAQ Index and R&D expenditure are exploratory additions not specified in the PROSPERO protocol (CRD420261470942) and are reported as such in Methods 3.7. Results do not change any primary or prespecified estimate.

## Analytical unit and denominator
One row per WHO Member State (N=194) from `results/country_analytic_with_yld_bounds_v1.csv` in the GBD 2023 audit release (`GBD2023_2023_analysis_audit_20261112.zip`). `observed` = country–trial participations (total 453; 47 countries with ≥1). `expected_point` = expected participations, proportional to each country's share of 2023 migraine YLDs (GBD 2023). `oe_point` = observed/expected. Each indicator is analyzed in the countries with non-missing data for that indicator; no imputation.

## New file: `covariates_haq_rd.csv`
One row per WHO Member State (N=194), joined to the analytic file by ISO3 code.

| Variable | Definition | Source | Coverage |
|---|---|---|---|
| country_iso3 | ISO 3166-1 alpha-3 code; join key. | Project country list | 194/194 |
| haq_2019 | Healthcare Access and Quality Index, 2019, age-standardized, scale 0–100 (point estimate). | IHME, GBD 2019 HAQ Index 1990–2019, file `IHME_GBD_2019_HAQ_1990_2019_DATA_Y2022M012D21.CSV`, indicator "Overall" (indicator_id 100). The release has only 1990 and 2019; 2019 is the latest available year. File supplied by the investigator on 16 November 2026. | 194/194 (47/47 participating countries) |
| rd_value | Gross domestic expenditure on research and development, % of GDP, for the selected year (see rule below). | UNESCO Institute for Statistics, distributed through World Bank World Development Indicators, series GB.XPD.RSDV.GD.ZS (API, last updated 11 November 2026; extracted 16 November 2026). | 127/194 (46/47 participating countries; Lebanon, 1 participation, has no value) |
| rd_year | Year(s) used for rd_value. "2018+2020" or "2015+2023" means two equidistant years were averaged. | Derived | Same as rd_value |

### R&D year-selection rule
R&D series are sparse and irregular, and low-income countries often report only old years. To avoid mixing values from very different periods, the value used is the one for the year closest to 2019, the median start year of included trials, restricted to 2015–2023. When two available years were equally close to 2019, their values were averaged. Countries with no value in 2015–2023 are missing (no carry-forward from earlier years). Distribution of selected years: 2019, 94 countries; 2018, 5; 2016, 6; 2015, 6; 2022, 5; 2017, 3; 2018+2020, 3; 2023, 2; 2020, 1; 2021, 1; 2015+2023, 1.

## Prespecified indicators used alongside (unchanged)
| Column in analytic file | Definition | Coverage |
|---|---|---|
| HDI, period mean | UNDP Human Development Index, mean of available years in the study period (2011–2026). | 190/194 |
| GDP per capita, PPP-adjusted, period mean | World Bank GDP per capita, PPP (constant 2021 international $), mean of available years in the study period. | 185/194 |

The four Member States without HDI (Cook Islands, Niue, Monaco, Democratic People's Republic of Korea) are absent from the original Figure 4 region map; in the four-panel figure they are assigned to Oceania, Oceania, Europe and Asia so they can be plotted in the HAQ panel.

## Regression contrasts
| Indicator | Model term | Reported contrast |
|---|---|---|
| HDI | (HDI − 0.8)/0.1 | per 0.1 increase |
| GDP per capita | log2(GDP/20 000) | per doubling |
| HAQ Index | (HAQ − 80)/10 | per 10-point increase |
| R&D expenditure | log2(R&D/1%) | per doubling |

Centering changes only the intercept.

## Models (Table 3 and Figure 4)
1. **Any participation (OR):** logistic regression of any trial participation (observed > 0) on one indicator; model-based Wald 95% CIs.
2. **Burden-adjusted participation (IRR):** negative binomial regression (MASS::glm.nb) of `observed` on one indicator with offset log(`expected_point`); HC3 robust covariance (sandwich::vcovHC); Wald 95% CIs and P values. Same specification as the original HDI and GDP panels; Figure 4 curves and 95% bands come from these models.
3. **Spearman ρ:** rank correlation between each indicator (untransformed; ρ is invariant to monotone transformation) and `oe_point` across countries with data; P from cor.test (asymptotic); 95% CI from 2000 bootstrap resamples of countries (percentile method, seed 20261113).
4. **Exploratory mutual adjustment:** in the 126 countries with all four indicators (46 with trials, 452 participations), HDI and log2 R&D expenditure were each standardized to mean 0, SD 1 and entered together in the logistic and negative binomial models above. GDP and HAQ were not co-adjusted because of collinearity with HDI (VIF with all four: HDI 18.9, GDP 11.3, HAQ 8.4, R&D 2.0; VIF for HDI + R&D: 1.87). Pairwise Spearman correlations with HDI: GDP 0.96, HAQ 0.94, R&D 0.75.

## Recalculated results with 108 records

| indicator | countries | with_trials | spearman | OR | IRR |
| --- | --- | --- | --- | --- | --- |
| HDI (per 0.1) | 190 | 47 | 0.61 (0.51–0.69) | 5.41 (3.14–9.33) | 7.89 (5.92–10.52) |
| GDP per capita, PPP (per doubling) | 185 | 47 | 0.55 (0.45–0.64) | 3.00 (2.07–4.34) | 5.17 (3.78–7.05) |
| HAQ Index (per 10 points) | 194 | 47 | 0.60 (0.51–0.68) | 2.59 (1.96–3.41) | 3.03 (2.46–3.73) |
| R&D expenditure, % of GDP (per doubling) | 127 | 46 | 0.71 (0.62–0.78) | 4.27 (2.59–7.04) | 2.87 (1.89–4.35) |

## Files added in this release
| File | Content |
|---|---|
| `covariates_haq_rd.csv` | HAQ 2019 and selected R&D values (above). |
| `table3_covariates.R` | Reproduces Table 3, the adjusted model, VIFs and indicator correlations; writes `table3_covariates.csv`, `adjusted_hdi_rd.csv`, `table3_covariates_audit.json`. |
| `build_figure_4panel.R` | Builds Figure 4 (A HDI, B GDP, C HAQ, D R&D); stops if the HDI and GDP IRRs differ from the original Figure 4. Writes `figure_4panel_audit.json` and per-panel country data. |
| `figure_4panel_audit.json` | n, participations, IRR, P, theta and labeled countries per panel. |

Run from the release root with `LC_ALL=C.UTF-8 Rscript <script>`; requires R with MASS, sandwich, jsonlite (and ggplot2, ggrepel, dplyr, patchwork for the figure).

---

# Part C. Before/after FDA approval comparison of non-high-income participations (added 16 November 2026)

## Status
Exploratory analysis added during analysis and not specified in the PROSPERO protocol (CRD420261470942). It is recorded in the dated Protocol Amendment of 16 November 2026 (section 3) and reported in Results 4.7 of the manuscript. It does not change any primary or prespecified estimate. The statement in Part A that no significance tests are performed refers to `subgroup_table.csv`, which remains descriptive; the test below is separate and is not part of that table.

## Question and interpretation
Whether the share of non-high-income countries among country–trial participations differs between trials starting before and trials starting on or after the first FDA approval of erenumab (17 May 2018). The comparison describes the composition of participations by trial start date. It is not an estimate of an effect of the approval, and a trial start date is not country-specific recruitment timing (see `fda_period` in Part A).

## Analytical unit and input
`country_record_453.csv` (one row per unique record–country participation; N=453). The 453 participations belong to 106 trials; 42 trials contribute participations in more than one country (maximum 18 countries in one trial). The two trials of the 108 without a participation row (NCT07655440 and NCT04334408) are not part of this analysis. Participations are the unit of analysis, and participations from the same trial are treated as clustered.

## Variables
| Variable | Definition |
|---|---|
| nonhic | 1 if `income` is UMIC, LMIC or LIC; 0 if HIC. Income is the World Bank FY2019 group (see Part A). Among the 453 participations: HIC 392, UMIC 42, LMIC 19, LIC 0; none has income unavailable. |
| after | 1 if `fda_period` is "On/after approval"; 0 if "Before approval". All 453 participations have one of these two values (193 before, 260 on/after); records with "Missing or insufficient precision" would be excluded and none occurs in the participation file. |
| trial | Cluster identifier, from `study_id`. |

## Model
Logistic regression of `nonhic` on `after` (`nonhic ~ after`). The reported estimate is the odds ratio (OR) of a participation being in a non-high-income country on or after approval versus before. Standard errors are clustered on trial (`study_id`) with no small-sample correction (statsmodels `cov_type="cluster"`, `use_correction=False`); 95% confidence intervals are Wald intervals and P is two-sided. With this setting the result is numerically identical to a generalized estimating equation with independence working correlation and robust standard errors.

## Recalculated temporal comparison

Before approval: 21/193 non-HIC participations (10.9%). On/after approval:
40/260 (15.4%). The trial-clustered OR is 1.49 (95% CI 0.63–3.53), P = 0.365.
The equivalent independence-working-correlation GEE with robust sandwich errors
was rerun in R (`pre_post_income_test.R`). The 20,000 whole-record bootstrap
replicates give a difference of 4.50 percentage points and a percentile interval
of −5.35 to 13.29 percentage points. Other robustness specifications listed in
the historical v3 codebook are not presented as recalculated results.

---

# Part D. Bounding analysis for exploratory HAQ and R&D models (16 November 2026)

This sensitivity analysis extends the separate exploratory HAQ Index and R&D expenditure models to the lower and upper country-specific 95% GBD 2023 YLD uncertainty limits for reference year 2023. For each scenario, expected participations are calculated across all 194 WHO Member States as 453 times the country's scenario YLD divided by the sum of scenario YLDs. The same 194 HAQ countries and 127 R&D countries are retained for point, lower and upper scenarios. R&D includes 452 participations. The models use the original transformations `(HAQ - 80) / 10` and `log2(R&D expenditure as % GDP)`, respectively; each is a separate negative binomial model with log(expected participations) as offset. Model-based theta is estimated by maximum likelihood; covariance uses HC3 and intervals are two-sided 95% Wald intervals. These scenario fits are a bounding exercise and do not propagate the joint GBD uncertainty distribution.

| Indicator | Point YLD IRR (95% CI) | Lower YLD IRR (95% CI) | Upper YLD IRR (95% CI) |
|---|---|---|---|
| HAQ, per 10 points | 3.03 (2.46–3.73) | 3.03 (2.46–3.74) | 3.03 (2.46–3.73) |
| R&D, per doubling | 2.87 (1.89–4.35) | 2.87 (1.89–4.35) | 2.87 (1.89–4.34) |

`bounding_haq_rd_20261114.py` is an independent implementation using Python, NumPy, pandas and SciPy. It reads `results/country_analytic_with_yld_bounds_v1.csv` and `results/negative_binomial_models_all_scenarios.csv` from `GBD2023_2023_analysis_audit_20261112.zip`, plus `covariates_haq_rd.csv`. It checks the 194-country expected-count construction, reproduces HAQ and R&D point estimates and confidence intervals against `figure_4panel_audit.json`, verifies all six point/lower/upper HDI and GDP fits against the original R analysis, and checks that each indicator's country sample is identical in the three scenarios. It writes `bounding_haq_rd_20261114.csv` and `bounding_haq_rd_20261114.audit.json`; the latter records country lists, input SHA-256 hashes, fit diagnostics, package versions and validation. It refuses to overwrite output files. The 2019 YLD column retained in the dataset is not used.

Run from a directory containing the original release's `results/` and the covariate file:

```
python bounding_haq_rd_20261114.py --analytic results/country_analytic_with_yld_bounds_v1.csv --covariates covariates_haq_rd.csv --reference results/negative_binomial_models_all_scenarios.csv --output bounding_haq_rd_20261114.csv
```

The original R script and historical release remain unchanged. Analyses were run and validated on 16 November 2026; the new sensitivity results are exploratory in the same sense as the underlying HAQ and R&D models.

**Current implementation:** `bounding_haq_rd.R` reruns the adopted 108-record scenarios in R. The older Python script remains part of historical provenance, not a claim that the old 107-record outputs are current.

## Reproducibility and recovered exploratory inputs

The original HAQ/R&D covariate CSV was unavailable in the shared folder. It was
reconstructed from the retained original IHME HAQ 2019 export and the documented
World Bank series and year-selection rule (2015–2023, closest to 2019, ties
averaged). The public World Bank source still reports last update 11 November
2026. Before inclusion, the reconstruction reproduced all four previous
ORs/IRRs, their confidence intervals, Spearman bootstrap intervals and the
mutually adjusted IRRs at the reported precision. Source bytes, hash and checks
are retained in the audit package. This was not an undocumented change to the
indicator definition. The subsequent 108-record models were then recalculated.

Use the analysis directory in the new ZIP as the current computational release.
The accompanying notebook runs these versioned scripts; historical notebooks,
datasets and codebooks are retained for audit, not mixed into the current run.
