# Public repository scope

Working research repository, 17 November 2026. The variable definitions below
describe the reviewed analytical dataset, including externally acquired inputs.
Restricted third-party input snapshots are not distributed in this repository.
See DATA_ACCESS.md and EXTERNAL_INPUTS.json. Releases are archived on Zenodo (all versions: https://doi.org/10.5281/zenodo.24386424).

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

---

# Part E. Figure 2 v2: refined geographic map and shared figure design system (17 November 2026)

## Status and scope

Presentation-only refinement of the manuscript's Figure 2 (two-panel world map).
**No analytical modification was made; the underlying results were preserved.**
No record, country–record pair, eligibility decision, country normalization,
removed registry location, WHO Member State classification, YLD input, expected
count or O/E ratio was changed or recalculated. Figure numbering follows the
current manuscript (Figure 1 is the PRISMA flow diagram). The previous script,
`figure2_vertical.R` (v1), is retained unchanged.

## Files

| Role | Path |
|---|---|
| Figure script | `figure2_global_distribution.R` |
| Shared design system (sourced by the script) | `figure_theme.R` |
| Vector PDF (fonts embedded) | `figures/figure2/Figure_2_global_distribution_v2.pdf` |
| Editable SVG (text kept as text) | `figures/figure2/Figure_2_global_distribution_v2.svg` |
| PNG, 600 dpi | `figures/figure2/Figure_2_global_distribution_v2.png` |
| Plotted values and classes, 194 rows | `figures/figure2/Figure_2_global_distribution_v2_plot_data.csv` |
| Validation record, input/output SHA-256 | `figures/figure2/Figure_2_global_distribution_v2_validation.json` |
| Proposed caption | `figures/figure2/Figure_2_legend_proposed.md` |

Inputs, all from `public_data_and_reference_results.zip`: `country_record_453.csv`
(participations), `results/country_expected_oe_all_scenarios.csv` (scenario
`Point`: observed, O/E), `source_data/who_regions.csv` (194-state universe) and
`source/natural_earth/ne_50m_admin_0_countries.shp`.

## Analytical population, unit and geography

Unit: the country–trial participation, i.e. one unique `(study_id, country_iso3)`
pair among WHO Member States; a trial contributes at most once per country,
irrespective of site count. Not sites, not enrolled participants, not unique
trials. Population: the adopted 108-record release (106 records with an eligible
country). Geographic unit: the 194 WHO Member States (ISO3). Variables plotted:
`participations` (count per Member State, including 0) and `oe` (observed ÷
expected, expected proportional to the country's share of GBD 2023 all-age,
both-sex migraine YLDs in 2023).

## Visualization transformations

- Natural Earth 1:50m Admin-0 polygons joined on ISO_A3 (ADM0_A3 where ISO_A3 is
  `-99`, e.g. France, Norway); Antarctica omitted; Robinson projection
  (ESRI:54030). All 194 Member States match exactly one polygon. French Guiana is
  part of the France polygon in Natural Earth and is shaded as France (unchanged
  from v1).
- Panel a classes (unchanged from v1): 0; 1–2; 3–5; 6–14; 15–29; ≥30.
- Panel b classes (**changed encoding**, see below): <0.1; 0.1–<0.2; 0.2–<0.5;
  0.5–<1; 1–<2; 2–<5; 5–<10; ≥10, lower-inclusive, applied to unrounded O/E.
  Member States with 0 participations (O/E = 0) form a separate category.

## Colour scale and interpretation

- Panel a: sequential navy ramp `#CFDCEC → #122C54`; darker = more participations.
- Panel b: diverging scale mirrored in lightness around O/E = 1. Warm
  (`#7E4325, #A8653F, #C99472, #E6CBB4`) = fewer participations than expected
  from migraine burden; navy (`#CFDCEC, #94B0D3, #4F78AE, #14305A`) = more.
  Classes are reciprocal-symmetric (0.5↔2, 0.2↔5, 0.1↔10), so equal colour
  intensity means the same fold-deviation from proportionality in either direction.
- Neutral grey `#DEDEDC`: WHO Member State with no participation (observed zero;
  147 states). White with grey outline: area outside the analytical universe
  (not a WHO Member State, e.g. Taiwan, Puerto Rico, Greenland, Western Sahara,
  Somaliland and small territories); not analysed, and not the same as zero.

## Validation checks (computed at run time; nothing hard-coded)

The script stops unless: pairs are unique; every pair country is in the 194-state
universe; per-country counts from the pair file equal `observed` in the O/E file
for all 194 states; every Member State joins to one polygon; totals equal
`CURRENT_RELEASE.json`. Result on 17 November 2026: 194 Member States; 453
country–trial participations; 47 participating states; 147 without
participation; 106 contributing records. Panel b class counts: <0.1, 2 (India,
China); 0.1–<0.2, 1 (Iran); 0.2–<0.5, 3; 0.5–<1, 5; 1–<2, 2; 2–<5, 12; 5–<10, 9;
≥10, 13.

Discrepancy investigated: an external brief cited ~452 participations. 452 is
the superseded 107-record version (`source/prior_country_record452.csv`); the
only difference is the pair NCT04361721–ITA adopted on 16 November 2026. The
manuscript already reports 453. No change was made.

## Changes relative to v1 (`figure2_vertical.R`)

Aesthetic: shared design system (`figure_theme.R`); Arial at final size
(7–10 pt; Montserrat not installed, Arial is Springer Nature's recommended face);
174 mm double-column width (164 mm high; 2 mm top and 1.5 mm side/bottom page margins) instead of 8 × 9.35 in; keys placed in
open ocean instead of below each map, sized 7.5 pt (title) / 7 pt (labels), with 6 mm of extra open ocean added on the left of the map frame so the keys stay clear of land (geography unchanged); stepped keys; bold lowercase panel letters
with short panel headings and no embedded figure title; restrained navy/warm
palette replacing ColorBrewer blue/orange; 0.25 pt white borders; areas outside
the universe drawn hollow so that they cannot be confused with zero; terminology
"country–trial" (manuscript wording) instead of "country–record"; PDF and SVG
exports added.

Visual encoding (not analytical): panel b changed from 2 classes below 1 and 4
above (<0.5, 0.5–<1 | 1–<2, 2–<5, 5–<10, ≥10) to 4 + 4 reciprocal-symmetric
classes, at the investigator's request on 17 November 2026, because the former
scale was asymmetric on a ratio scale. O/E values and the categories above 1 are
unchanged.

## Shared design system (`figure_theme.R`)

Typography (`fig_font`, `fig_size`: tag 10, heading 8, title 7.5, text 7,
in-panel keys 7.5/7, minimum 6.5 pt), colours (`fig_col`, `fig_navy`, `fig_diverging`, `fig_series`
for up to four grouped series), line weights (`fig_lwd`), widths (`fig_width`:
84 / 129 / 174 mm; maximum height 234 mm), panel headings (`fig_heading`),
themes (`theme_fig` for charts, `theme_fig_map` for maps), stepped keys
(`fig_binned_key`) and export (`fig_save`: SVG via svglite, PDF from that SVG via
librsvg, PNG 600 dpi via ragg). Later figures should source this file rather than
restate settings.

PDF note: librsvg emits a small Type 3 font containing only the space glyph;
all visible text is embedded Arial TrueType subsets.

## Reproduction

```sh
python3 run_analysis.py --output ../registry_validation --validate-only
Rscript figure2_global_distribution.R ../registry_validation figures/figure2
```

R packages: dplyr, readr, sf, ggplot2, patchwork, jsonlite, svglite, rsvg,
ragg; system font Arial. Outputs are overwritten in the given directory; compare
`output_sha256` in the validation JSON. The full launcher (`--figures`) also runs
this script.

## Recommended structural changes (not implemented)

1. Europe inset in both panels: 29 of the 47 participating states are in the WHO European Region and
   several are hard to read at 174 mm.
2. Point markers for participating states too small to see (Singapore, 2
   participations; Lebanon, 1).
Either would add a visual element and needs investigator approval.

---

# Part F. Figure 3 v2: representation relative to migraine burden by WHO region and income group (17 November 2026)

## Status and scope

New publication version of manuscript Figure 3. It replaces the income-only bar
chart (`build_figure3.R`, v1, retained unchanged) and adds a WHO-region panel.
Numbering follows the current manuscript (Figure 1 PRISMA; Figure 2 map).
**No analytical modification was made; values are reused from the adopted
release and only re-aggregated for checking.** The separate post hoc,
design-relaxed comparison (467 participations, Supplementary Table S9) is not
used.

## Purpose and interpretation

Descriptive comparison, for each group, of (i) its share of all country–trial
participations and (ii) its share of global migraine YLDs, i.e. the share it
would have if participation were proportional to migraine burden. The O/E ratio
summarizes the comparison. It is not a statistical test, a causal
counterfactual, or a measure of patient access or recruitment.

## Inputs and provenance (all in `public_data_and_reference_results.zip`)

| File | Use |
|---|---|
| `results/country_expected_oe_all_scenarios.csv` (scenario `Point`) | Country-level `observed`, `expected`, `who_region`, `income`; aggregated to groups |
| `results/who_income_expected_oe_all_scenarios.csv` (scenario `Point`) | Validated group results; cross-check |
| `country_record_453.csv` | Unique country–trial pairs; total and regional cross-check |
| `results/native_document_tables/manuscript_table_04.csv` | Manuscript Table 2 (regions); reconciliation |
| `results/figure3_income_data.csv` | v1 Figure 3 income shares; reconciliation |

## Definitions

- **Unit:** country–trial participation (Part A): one unique `(study_id,
  country_iso3)` pair among WHO Member States, at most once per trial and
  country, irrespective of site count.
- **Denominator population:** the 194 WHO Member States (zero-participation
  states included); 453 participations from the 108-record release.
- **Burden:** GBD 2023 migraine YLDs, all ages, both sexes, number, year 2023
  (Part B / `config.json`). Absolute YLDs are not redistributed publicly; a
  group's YLD share is recovered exactly as Σ expectedᵢ / Σ expected, because the
  release defines expectedᵢ = 453 × YLDᵢ / ΣYLD.
- **WHO region:** six regions from `source_data/who_regions.csv`.
- **Income group:** World Bank FY2019 classification, fixed (Part A). Cook
  Islands and Niue (WHO Member States, Western Pacific) have no World Bank
  classification ("Income group unavailable"): 0 participations, 0.0002% of
  YLDs. They are kept in all totals and denominators but are not drawn as a
  separate category in panel b; the caption states this.

## Formulas (unrounded)

- Observed share = observed_g / Σ observed
- YLD share = YLD_g / Σ YLD
- Expected_g = Σ observed × YLD share_g
- O/E_g = observed_g / expected_g = observed share / YLD share
- Zero participations give O/E = 0 (expected is always > 0 for the displayed groups).

## Display transformations (presentation, not analysis)

- Shares in % with one decimal; O/E with two decimals (as in Table 2). Exact
  zeros are written "0 (none)" with a short baseline mark, so they cannot be
  read as rounded small values (smallest nonzero: Eastern Mediterranean 0.4%).
- Both panels share one linear 0–100% axis; no truncation, no log scale.
- Groups ordered by O/E (regions) and income rank (income groups, which is
  also descending O/E).
- Grouped horizontal bars were chosen over a dumbbell plot: both quantities are
  shares of a whole with a meaningful zero, and connecting segments in a
  dumbbell tend to be read as change over time.
- Style from `figure_theme.R`: dark navy (`fig_pair["observed"]`, #14305A) for
  observed shares, light slate (`fig_pair["reference"]`, #AEB7C2) for YLD
  shares, which also separate in greyscale; Arial 7–10 pt; 174 × 114 mm; one
  shared key above both panels (it applies to a and b alike), aligned with the
  panel letters; O/E column right-aligned.

## Validation (automated in the script; it stops on any failure)

1. Group observed counts sum to 453, which equals the unique pair file and
   `CURRENT_RELEASE.json`; the total is not the 467 exploratory total.
2. WHO regions partition the 194 Member States (6 groups, no missing values).
3. Income groups partition the 194 states (4 groups plus the documented
   exception, which has 0 participations).
4. Group expected counts sum to 453 (YLD aggregation).
5–6. Observed and YLD shares each sum to 1 before rounding.
7. Observed, expected, O/E and YLD shares agree with the validated group
   results (max absolute difference 4 × 10⁻¹³) and regional counts with the pair file.
8. Rounded values equal manuscript Table 2 (regions: n, %, YLD %, expected, O/E)
   and the v1 income-figure data exactly.

Results:

| Group | Observed n (%) | YLD % | O/E |
|---|---|---|---|
| Europe | 297 (65.6) | 14.0 | 4.67 |
| Americas | 101 (22.3) | 14.0 | 1.59 |
| Western Pacific | 46 (10.2) | 22.4 | 0.45 |
| South-East Asia | 7 (1.5) | 27.8 | 0.06 |
| Eastern Mediterranean | 2 (0.4) | 9.7 | 0.05 |
| Africa | 0 (0.0) | 12.1 | 0.00 |
| High income | 392 (86.5) | 17.4 | 4.97 |
| Upper-middle income | 42 (9.3) | 33.4 | 0.28 |
| Lower-middle income | 19 (4.2) | 41.5 | 0.10 |
| Low income | 0 (0.0) | 7.7 | 0.00 |

Earlier checkpoints (452 participations; Europe 65.5%, O/E 4.46; Americas O/E
1.55; Western Pacific 0.44; high income 18.1% of YLDs, O/E 4.78) were traced on
17 November 2026. They reproduce exactly from the superseded 107-record data
(452 participations) combined with the legacy `Migraine YLD number, 2019` column of
`results/country_analytic_with_yld_bounds_v1.csv`, a restricted file that is not
distributed. Two changes since then explain every difference: the NCT04361721–ITA
pair (Europe 296 → 297), and the switch to GBD 2023 YLDs for 2023 (for example,
high-income YLD share 18.1% → 17.4%). The current release, manuscript Table 2 and
Results text agree with the values above. Nothing was adjusted to match earlier
versions.

## Files and reproduction

| Role | Path |
|---|---|
| Script | `figure3_burden_representation.R` (sources `figure_theme.R`) |
| Vector PDF | `figures/figure3/Figure_3_burden_representation_v2.pdf` |
| Editable SVG | `figures/figure3/Figure_3_burden_representation_v2.svg` |
| PNG, 600 dpi | `figures/figure3/Figure_3_burden_representation_v2.png` |
| Group values (unrounded; no absolute YLDs) | `figures/figure3/Figure_3_burden_representation_v2_plot_data.csv` |
| Validation record | `figures/figure3/Figure_3_burden_representation_v2_validation.json` |
| Proposed caption | `figures/figure3/Figure_3_legend_proposed.md` |

```sh
python3 run_analysis.py --output ../registry_validation --validate-only
Rscript figure3_burden_representation.R ../registry_validation figures/figure3
```

Reruns reproduce the SVG and PNG byte for byte. The PDFs (Figures 2 and 3) embed
a creation date and random font-subset tags, so their checksums change on every
run without any visual change.

## Changes relative to v1 (`build_figure3.R`)

Analytical: none; identical income shares. Content: WHO-region panel added (the
same values as manuscript Table 2) and O/E column added. Presentation: shared
design system, horizontal grouped bars with direct labels, explicit zeros,
PDF/SVG/PNG exports at 174 mm.

## Shared-style adjustments made with this figure

`figure_theme.R` gained `fig_pair` and `fig_key_row` (a figure-level key
sized in millimetres), and panel headings are now explicitly plain weight. The Figure 2 map was regenerated afterwards: its SVG and PNG are
byte-identical, so it is unchanged.

---

# Part G. Figure 4 v2 (HDI, GDP) and Supplementary Figure S3 v1 (HAQ, R&D) (17 November 2026)

> **Superseded layout.** On 17 November 2026 the investigator chose a single four-panel
> figure; see Part H. The model, axis, zero-strip, colour, size and label-rule
> specifications below still apply. Supplementary Figure S3 was never adopted: its files
> were removed. (The number S3 was later reused for a different figure; see Part I.)

## Status and scope

The four-panel socioeconomic figure (`build_figure_4panel.R`, retained unchanged)
is split as follows:

- Figure 4 v2: HDI (a) and GDP per capita, PPP (b). These are the primary socioeconomic indicators.
- Supplementary Figure S3 v1: HAQ Index (a) and R&D expenditure (b). These are the exploratory indicators. S3 is the next free number after Supplementary Figures S1–S2; no existing figure is renumbered.

**No analytical modification was made.** The models are refitted with the
validated specification only so that their curves can be drawn, and the script
stops unless they reproduce the reference outputs. All changes are graphical,
except for the y-axis treatment of zeros and the label rule described below.
Both are presentation decisions.

## Inputs (reviewed external snapshot; not redistributed)

Run the script in a full-reproduction directory that holds the exact inputs
listed in `EXTERNAL_INPUTS.json` (checked 17 November 2026 by SHA-256):

- `results/country_analytic_with_yld_bounds_v1.csv`: 194 Member States, `observed`, `expected_point`, `oe_point`, HDI and GDP period means.
- `covariates_haq_rd.csv`: `haq_2019`, `rd_value`.
- `source/region_plot_mapping.csv`: world region.
- `results/negative_binomial_models_all_scenarios.csv` (HDI/GDP) and `results/bounding_haq_rd.csv` (HAQ/R&D): reference estimates.
- `results/country_expected_oe_all_scenarios.csv`: public O/E cross-check.
- `results/native_document_tables/manuscript_table_06.csv`: manuscript Table 3.

## Model specification (confirmed from `build_figure_4panel.R`, `analysis.R`, `bounding_haq_rd.R`)

- Unit: WHO Member State.
- Outcome: country–trial participations.
- Model: `MASS::glm.nb(observed ~ predictor + offset(log(expected_point)))`, maxit 1000.
  `expected_point` = 453 × country share of GBD 2023 migraine YLDs (all ages, both sexes, 2023).
- Predictors (one model each; no mutual adjustment):

| Predictor | Transformation | Effect expressed per |
|---|---|---|
| HDI | (HDI − 0.8) / 0.1 | 0.1 unit |
| GDP | log2(GDP / 20 000) | doubling |
| HAQ | (HAQ − 80) / 10 | 10 points |
| R&D | log2(R&D % of GDP / 1) | doubling |

  Centring changes only the intercept.
- Inference: HC3 covariance (`sandwich::vcovHC`), two-sided Wald 95% CIs and P.
- Missing data: complete cases per indicator; no imputation.

| Model | n countries (with participation) | Participations | IRR (95% CI) | P |
|---|---|---|---|---|
| HDI per 0.1 | 190 (47) | 453 | 7.89 (5.92–10.52) | 3.3 × 10⁻⁴⁵ |
| GDP per doubling | 185 (47) | 453 | 5.17 (3.78–7.05) | 4.9 × 10⁻²⁵ |
| HAQ per 10 points (exploratory) | 194 (47) | 453 | 3.03 (2.46–3.73) | 3.1 × 10⁻²⁵ |
| R&D per doubling (exploratory) | 127 (46) | 452 | 2.87 (1.89–4.35) | 6.7 × 10⁻⁷ |

R&D is unavailable for Lebanon (1 participation), hence 452.

## Curves and bands

- The fitted mean on the O/E scale is E[count] / expected = exp(β₀ + β₁·predictor).
  The script checks that this equals `fitted()/expected` for every country, to within 10⁻⁸.
- Bands are 95% confidence intervals for the fitted mean, exp(η ± 1.96·SE(η)),
  with SE(η) taken from the same HC3 matrix as the reported IRR CI. They are not
  prediction intervals.
- Curves and bands are not drawn below O/E = 0.035, the bottom of the positive
  axis, so that they never enter the zero strip; above O/E = 75 they are clipped
  by the panel.

## Y axis and zero participation

- Positive O/E values use a log10 axis from 0.035 to 75. Ticks: 0.05, 0.1, 0.5, 1, 5, 10, 50.
- O/E = 0 (143, 138, 147 and 81 countries in the HDI, GDP, HAQ and R&D samples)
  cannot be placed on a log axis. These countries are drawn in a shaded strip
  below a visible gap, with the y axis broken between the two parts. Their
  vertical position within the strip is a deterministic display offset
  (`set.seed(20261117)`, uniform within ±75% of the strip half-height, stored as
  `zero_strip_display_offset` in the plot data) and carries no value.
- Model fitting uses the exact zeros. The script checks that observed = 0 exactly when O/E = 0.
- The previous version plotted log10(1 + O/E), which placed zeros on the axis but
  compressed every ratio below 1.
- The same axis, strip, limits and size scale are used in all four panels.

## Encodings

- **Colour:** continental "world region" from `source/region_plot_mapping.csv`
  (Africa, Asia, Europe, North America, Latin America and the Caribbean,
  Oceania). These are not WHO regions. Cook Islands and Niue are assigned to
  Oceania, Monaco to Europe and DPR Korea to Asia, as in the original script.
  Palette: Paul Tol muted (`fig_world_region`).
- **Point area:** expected participations, preserved from the original. Square-root
  scale, 0.9–3.8 mm, with identical limits in both figures.

## Country labels

The rule is the original one, reduced from 5 to 3 countries per criterion, in
each panel: the three highest O/E; the three lowest positive O/E; the three
largest expected counts among countries with O/E = 0. Ties are broken by ISO3.

- Labelled points get a thin dark ring.
- Placement uses ggrepel with seed 20261117. Labels for zero-strip countries sit
  in the gap above the strip.
- Result in every panel: DNK, FIN, GEO; IND, CHN, IRN; IDN, BRA, NGA.

## Model annotation

Each panel shows the IRR descriptor, the IRR with its 95% CI, and n, in the
panel's empty upper-left corner. P values (all < 0.001) are in the caption. No
significance stars are used.

## Validation (automated; the script stops on any failure)

1. O/E equals the public results and observed/expected.
2–4. IRR, CI and n reproduce the reference outputs (tolerance 10⁻⁶) and the
rounded manuscript Table 3.
5. All 194 identifiers are three-letter ISO3 codes.
6. Exact zeros are preserved.
7. Curves correspond to the models.
8. Bands use the reported HC3 covariance.
9–10. One drawing function provides a shared axis, strip, limits, colours and
sizes for both figures.

The point-YLD models are plotted. YLD-bound sensitivity fits exist for all four
indicators (lower/upper rows in the two reference files; Supplementary Table S6)
and are not mixed into the figures.

## Reconciled discrepancy

Earlier manuscript estimates (HDI 7.77; GDP 5.09) reproduce exactly from the
superseded 107-record data with the legacy 2019 YLD offset. The current
108-record, GBD 2023 models give 7.89 and 5.17, as reported in the current
manuscript and Table 3. No result was changed.

## Files and reproduction

| Role | Path |
|---|---|
| Script (both figures) | `figure4_socioeconomic.R` (sources `figure_theme.R`) |
| Figure 4 | `figures/figure4/Figure_4_socioeconomic_v2.{pdf,svg,png}` |
| Supplementary Figure S3 | `figures/figureS3/Supplementary_Figure_S3_HAQ_RD_v1.{pdf,svg,png}` |
| Plot data (no covariate values, per DATA_ACCESS.md) | `*_plot_data.csv` in each folder |
| Validation records | `*_validation.json` in each folder |
| Proposed captions | `figures/figure4/Figure_4_and_S3_legends_proposed.md` |

```sh
python3 run_analysis.py --output ../full_reproduction --external-inputs /path/to/external_inputs --figures
# or, in an existing full-reproduction directory:
Rscript figure4_socioeconomic.R ../full_reproduction figures
```

Size: 174 × 112 mm; Arial 6.5–10 pt.

## Changes relative to the four-panel version

- **Graphical:** two figures instead of one; true log y axis with a separate zero
  strip; smaller labels selected by an objective rule; compact in-panel model
  annotation; shared bottom legend; lowercase panel letters; shared design system;
  PDF, SVG and 600-dpi PNG exports.
- **Analytical:** none.

`figure_theme.R` gained `fig_world_region`. The SVG and PNG of Figures 2 and 3
regenerate byte-identically.

---

# Part H. Figure 4 v3: single four-panel socioeconomic figure (17 November 2026)

## Change

At the investigator's request, HDI (a), GDP per capita (b), HAQ Index (c) and R&D
expenditure (d) are combined again in one 2 × 2 Figure 4. All four panels are
styled identically, with no graphical distinction between primary and exploratory
analyses. The analytical roles are stated in the caption:

- HDI and GDP per capita: primary predictors.
- HAQ Index: protocol-listed, evaluated in an additional analysis.
- R&D expenditure: added post hoc as an exploratory predictor.

The v2 two-panel Figure 4 and the Supplementary Figure S3 files were removed from
the working tree (they remain in Git history).

**No analytical modification.** The models, IRRs, CIs, n, offsets and O/E values
are unchanged. The script still refits the models and stops unless they reproduce
the reference outputs and manuscript Table 3.

## Graphical changes relative to v2 (Part G)

- **Layout:** 2 × 2; 174 × 190 mm; one shared legend; y-axis title on the left column only.
- **Panel headings:** the "(exploratory)" tags were removed.
- **Positive axis:** the top of the positive O/E axis was raised from 75 to 100 so that
  labels above the highest points (O/E ≈ 49) are not cramped. Display only;
  identical in all panels; ticks unchanged.
- **Label readability (label selection rule unchanged):**
  - Every plotted positive point takes part in label repulsion; unlabelled points
    get an empty label.
  - Invisible repulsion points cover the model annotation block and sample the
    fitted curve, so labels avoid that text and the line.
  - Each point's repulsion radius equals its plotted bubble size (`point.size`
    mapped through the same square-root scale and 0.9–3.8 mm range).
  - All labels get thin leader lines and a white halo; seed 20261117.
- **Exports:** PDF (vector, embedded Arial), SVG and 600-dpi PNG in `figures/figure4/`
  as `Figure_4_socioeconomic_v3.*`, plus plot data (no covariate values) and the
  validation record.

## Reproduction

```sh
Rscript figure4_socioeconomic.R ../full_reproduction figures
```

This requires the reviewed external inputs (DATA_ACCESS.md). The caption is in
`figures/figure4/Figure_4_legend_proposed.md`.

## Part H update: WHO regions, size key and five labels per criterion (17 November 2026)

Investigator requests, all graphical:

- **Point colour = WHO region** (Africa, Americas, Eastern Mediterranean, Europe,
  South-East Asia, Western Pacific).
  - Source: the analysis file's `who_region`, which the script checks country by
    country against `source_data/who_regions.csv`. These are the same six
    regions as Figure 3.
  - Palette: Paul Tol muted (`fig_who_region` in `figure_theme.R`).
  - This replaces the continental "world region" grouping (`region_plot_mapping.csv`),
    which is no longer read. Visible consequences: Georgia (WHO European Region)
    is now coloured as Europe; India is South-East Asia; China is Western Pacific.
  - The plot-data column is now `who_region`.
- **Size key** steps: 1, 2, 5, 10, 20 and 50 expected participations. Same
  square-root scale and limits as before.
- **Labels per criterion: 5** (was 3). Same rule otherwise. Set by `n_lab`, default 5;
  the environment variable `FIG4_LABELS_PER_GROUP` can override it. Labelled countries:

  | Panels | Five highest O/E | Five lowest positive O/E | Five largest expected among O/E = 0 |
  |---|---|---|---|
  | a–c | DNK, FIN, GEO, ISL, CZE | IND, CHN, IRN, PHL, VNM | IDN, BRA, NGA, PAK, BGD |
  | d | as a–c | as a–c | IDN, BRA, NGA, PAK, EGY (Bangladesh has no R&D value) |

- **Label legibility:**
  - Labels are bold, with a wider white halo (0.16) and darker, slightly heavier
    leader lines (0.28).
  - Labelled points get a heavier ring (0.4).
  - The gap above the zero strip, where zero-participation labels sit, was
    widened from 0.19 to 0.24 log10 units.

Models, IRRs, CIs, n, axes and the zero strip are unchanged, and all validation
checks still pass. The caption in `Figure_4_legend_proposed.md` now says "WHO
region" and "five". The manuscript caption has not been updated yet.

---

# Part I. Figure 5, Supplementary Figures S1 and S3, and Table 1 Panel B Member States (18 November 2026)

## Figure 5: WHO clinical trial benchmarks

**Purpose.** Descriptive, unadjusted comparison of the income-group distribution of
anti-CGRP country–trial participations with three WHO ICTRP benchmarks: migraine
trials, neuropsychiatric trials and all clinical trials.

**Anti-CGRP set (investigator decision, 18 November 2026).** All **132 registry
records retained after deduplication, before full-record eligibility assessment**
(108 eligible trials and 24 excluded records): **477** country–trial participations.

| Income group | n (%) |
|---|---|
| High | 414 (86.79) |
| Upper-middle | 44 (9.22) |
| Lower-middle | 19 (3.98) |
| Low | 0 |

This replaces two earlier versions:
- the 467 values transcribed from Supplementary Table S9;
- a 468 "design-relaxed" set: the 108 eligible trials plus the 15 records excluded only for study design. It is kept only as an audit trail in `figures/figure5/registry_design_relaxed_20261118/`.

**Building the country–trial pairs.** `figure5_build_anti_cgrp_set.py` writes
`figures/figure5/anti_cgrp_record_sets_pairs.csv` from the 5 August 2026 search
snapshot. It needs restricted inputs that are not in the public zip:
- `harmonized_registry_records.json`;
- `deduplicated_registry_records_complete.json`;
- `final_screening_source_snapshot_20260829.csv`.

The rules:
- **Countries:** taken from ClinicalTrials.gov location countries, or from the ICTRP
  "Countries" field.
- **jRCT records:** a record with no listed country is Japan (the
  convention of the primary dataset).
- **Member States only:** only the 194 WHO Member States are kept. Taiwan, Puerto Rico and other non-members are dropped.
- **Rayyan duplicates:** EUCTR2020-004509-30-ES and EUCTR2020-000661-16-DK, the two duplicates removed in Rayyan (PRISMA n = 2), are excluded from the 134 deduplicated records, which leaves 132.
- **Checks:** the script stops unless the rule, applied to the 108 eligible trials, reproduces the 453 primary pairs exactly, and unless the record set equals the 132-record screening snapshot.

The CSV holds three PRISMA stages, all with income from the World Bank FY2019 classification:

| `set` | Records | Pairs | High income |
|---|---|---|---|
| `pre_dedup_167` | 167 identified (a trial registered twice counts twice) | 747 | 651 (87.15%) |
| `post_dedup_132` | 132 deduplicated, before eligibility (Figure 5) | 477 | 414 (86.79%) |
| `eligible_108` | 108 eligible trials | 453 | 392 (86.53%) |

**WHO benchmarks.** These are rebuilt from the WHO Global Observatory exports (UTF-16,
tab-separated, every row duplicated):

| Benchmark | Source file | Accessed | Participations | High income |
|---|---|---|---|---|
| Migraine | `Trials by country.csv` | 16 Nov 2026* | 4,090 | 66.85% |
| Neuropsychiatric | `Neuropsy - Trials by country (1).csv` | 16 Nov 2026* | 163,031 | 67.42% |
| All clinical trials | `Trials per country.csv` | 18 Nov 2026 | 1,464,719 | 63.69% |

\* Access date as cited in S9; the local file timestamps are 15 November 2026, late evening.

Handling of the exports:
- **Country matching:** names are matched to the 194 Member States with aliases. Nauru appears as "Naoero" in the reference; correcting this adds 6 neuropsychiatric participations, a fix the investigator approved.
- **Non-member areas:** areas that are not Member States are excluded. The all-trials export lists every Member State, so it is used to check that every unmatched name is a non-member.
- **Unclassified income:** participations without an FY2019 income group (12 neuropsychiatric, 45 all trials) stay in the denominators.
- **S9 update:** Supplementary Table S9 previously reported 1,512,056 / 62.68% for all trials, and the source export for those values was not found. S9 now uses the traceable reconstruction (18 November 2026).

**Differences in high-income share** (anti-CGRP minus benchmark, percentage points):

| Benchmark | 167 records | 132 records (Figure 5) | 108 eligible |
|---|---|---|---|
| Migraine | +20.30 | +19.95 | +19.69 |
| Neuropsychiatric | +19.73 | +19.37 | +19.11 |
| All clinical trials | +23.46 | +23.10 | +22.84 |

**Script and layout.** `Rscript figure5_who_benchmark.R <data_dir> <who_export_dir> [output_dir] [variant]`.

The layout follows Figure 3's conventions:
- 100% stacked bars with the `fig_income` navy ramp and a single key row;
- right-hand columns "n" and "Difference, pp";
- a rule separating the anti-CGRP bar from the benchmarks;
- size 174 × 57 mm.

The anti-CGRP bar is labelled "Anti-CGRP mAb records", because the set includes
observational studies and registries. The "Draft" marker was removed on 18 November 2026.

Outputs: `figures/figure5/Figure_5_who_benchmark.{pdf,svg,png,_data.csv,_validation.json}`.
Status notes are in `figures/figure5/PROVISIONAL_STATUS.md`.

## Supplementary Figure S3: three record-selection stages

`figure5_who_benchmark.R` with variant `record_sets` draws three anti-CGRP bars
next to the same three WHO benchmarks:
- (a) 167 records before deduplication;
- (b) 132 records after deduplication;
- (c) 108 eligible trials.

The difference columns ("vs a", "vs b", "vs c") give the difference in high-income share between each benchmark and each anti-CGRP set. Lower-middle-income segments of sets a–c (3.5%, 4.0% and 4.2%) are too narrow to label, so the caption reports them.

Purpose: to show reviewers that comparing a processed cohort with the rawer ICTRP
aggregates does not drive the result. Across the three anti-CGRP sets, the high-income share varies by 0.6 percentage points, and its difference from each benchmark by less than 1 point.

Outputs: `figures/figure5/Figure_S3_record_selection_stages.*`. Both the figure and its caption are in the supplement.

## Supplementary Figure S1: redesign (candidate; not yet in the supplement)

`Rscript figureS1_mab_income.R <data_dir> [output_dir]` redraws S1 as one chart
in the shared design system, in place of the two-panel layout of
`build_supplementary_drug_figure.R` (which is unchanged).

The layout:
- 100% stacked bars by income group, one per mutually exclusive antibody category;
- right-hand columns: Trials, Countries (WHO Member States reached) and Participations;
- "Multiple anti-CGRP mAbs" separated by a rule.

Data and classification are the same as before: `source/study_agent_records.json`,
`source/country_record_pairs.csv` and the two reviewed agent corrections (NCT04659226 → erenumab, NCT07071506 → fremanezumab). The script stops unless it reproduces `results/figure_s1_mab_data.csv`.

What the figure shows:
- It displays 452 participations. The unspecified-mAb trial (1 participation) is not shown.
- One fremanezumab trial and one multiple-mAb trial have no participating Member State.

Outputs: `figures/figureS1/Figure_S1_mab_income.*`.

## Table 1 Panel B: WHO Member States per subgroup

A column "WHO Member States n" was added between "Trials n" and
"Participations n" (manuscript, 18 November 2026).

The column definition:
- **Value:** the number of distinct WHO Member States with at least one country–trial participation in the subgroup.
- **Not additive across rows:** a country is counted once in each subgroup in which it participates. Overall there are 47 Member States.
- **Antibody rows overlap:** as in the rest of the table, a trial evaluating several antibodies counts in each antibody's row. Fremanezumab and galcanezumab therefore show 22 Member States here, against 21 in the mutually exclusive categories of Figure S1.

`python3 -I table1_member_states.py <data_dir> tables/table1_panel_b_member_states.csv`
computes the column from `country_record_453.csv`. It stops unless its participation and high-income counts equal the published Panel B values in every row. The table note was extended accordingly.


---

# Part J. Figure 1: PRISMA 2020 flow diagram, publication version (20 November 2026)

## Status and scope

Presentation-only redraw of the manuscript's Figure 1. **No count, record or
eligibility decision was changed.** The boxes, labels and counts are those of the
adopted 108-record flow diagram (`Figure_1_PRISMA_108_editable.docx`, which is
retained privately and not overwritten).

## Files

| Role | Path |
|---|---|
| Figure script | `figure1_prisma.py` |
| Counts drawn (one row per number in the figure) | `figures/figure1/Figure_1_PRISMA_counts.csv` |
| Vector PDF, SVG and 3600-px PNG | `figures/figure1/Figure_1_PRISMA_2020.*` |
| Validation record (checks, input and output SHA-256) | `figures/figure1/Figure_1_PRISMA_2020_validation.json` |

## Layout

- PRISMA 2020 template colours: header #FFC000, phase labels #9CC2E5; Arial; thin black boxes.
- Boxes in the same row share one height, and the text is centred vertically.
- **Screening is one stage.** Every record was assessed on the complete registry entry, and the footnote says so. The template's "records screened" and "reports sought for retrieval" boxes are therefore replaced by a single "full registry records assessed for eligibility" box.
- The figure title is not part of the image; it stays in the manuscript caption.

## Checks (the script stops on any mismatch)

Internal arithmetic:
- 167 = 109 + 58;
- 35 = 19 + 14 + 2;
- 132 = 167 − 35;
- 24 = sum of the seven reasons;
- 108 = 132 − 24.

Against the public package:
- `CURRENT_RELEASE.json`: 35 duplicates, 24 exclusions, 108 records.
- `trial_level_108.csv`: 108 unique records.
- Supplementary Table S2: 24 rows, and the count of each reason (every S2 reason is mapped to one figure label).
- Included and excluded identifiers do not overlap.

With `--restricted <processed_dir>`, also against the restricted registry processing files:
- `harmonized_registry_records.json`: 109 ClinicalTrials.gov and 58 ICTRP records.
- `automatic_exact_nct_matches.csv`: 19 automated exact-NCT matches.
- `manual_review_decisions_final.csv`: 14 pairs decided as duplicates.
- `deduplicated_registry_records_complete.json`: 134 records = 167 − 19 − 14. The two Rayyan duplicates (Part I) then leave 132.

```sh
python3 -I figure1_prisma.py ../registry_validation figures/figure1 [--restricted <processed_dir>]
```

---

# Part K. Manuscript item map and tables as submitted (24 November 2026)

## Status and scope

Bookkeeping update for versions 1.0.1 and 1.0.2 (24 November 2026, the latter after the manuscript was closed). **No count, model or eligibility decision was changed.** It records where each table and figure of the submitted manuscript comes from, and which items changed after the 17 November 2026 snapshot in `public_data_and_reference_results.zip` (`results/native_document_tables/`).

## Former Table 4 moved to the supplement; new Tables 4 and 5

The indicator table that was Table 4 in the 17 November manuscript (country-level indicators: Spearman ρ, odds ratios and burden-adjusted IRRs for HDI, GDP per capita, HAQ Index and R&D expenditure) is now **Supplementary Table S11**; the main text cites it together with Figure 4. The values are those listed under "Recalculated results with 108 records" in Part B and are produced by `table3_covariates.R`. In the 17 November snapshot the same table is `results/native_document_tables/manuscript_table_06.csv`; `figure4_socioeconomic.R` still reads that file to check the Figure 4 IRRs against the published table, so the snapshot is kept unchanged.

The manuscript's current **Table 4** (recruitment, completion and publication status by income group) and **Table 5** (published trials by journal category and income group) were added after the snapshot. They are transcribed from the manuscript. Their publication classification comes from a separate review of the 108 trials whose records are not part of this repository, so these two tables are not regenerated here; their participation and income totals (453; high income 392, upper-middle 42, lower-middle 19) equal the primary analysis. Supplementary Table S7 uses the same classification (63 completed trials with primary results published).

## Manuscript items and their sources

| Item in the manuscript | Source in this repository |
|---|---|
| Figure 1 (PRISMA 2020) | `figure1_prisma.py` (Part J) |
| Figure 2 (global distribution) | `figure2_global_distribution.R` (Part E) |
| Figure 3 (burden representation) | `figure3_burden_representation.R` (Part F) |
| Figure 4 (socioeconomic gradients, four panels) | `figure4_socioeconomic.R` (Parts G–H) |
| Figure 5 (WHO trial benchmarks) | `figure5_who_benchmark.R`, variant `main` (Part I) |
| Supplementary Table S12 (mutual adjustment, HDI and R&D) | `table3_covariates.R` (output `adjusted_hdi_rd.csv`; Part B, item 4) |
| Supplementary Table S13 (equal trial weight) | `supplement_equal_weight.py` (below) |
| Supplementary Figure S1 (antibody and income) | `figureS1_mab_income.R` (Part I) |
| Supplementary Figure S2 (income-group associations) | `build_supplementary_income_forest.R` |
| Supplementary Figure S3 (three record-selection stages) | `figure5_who_benchmark.R`, variant `record_sets` (Part I) |
| Table 1 Panel B, WHO Member States column | `table1_member_states.py` (Part I) |
| Tables as submitted, in CSV | `tables/submission/` (below) |
| Figure captions of Figures 1–5 | `figures/figure_captions_as_submitted.md` (supersedes the `*_legend_proposed.md` drafts) |

## Tables as submitted: `tables/submission/`

CSV copies of the five tables in the manuscript (Table 1 has three panels) and of the supplementary tables that changed or were added after the 17 November snapshot (S7, S9, S11, S12, S13). They are transcriptions of the submitted documents (header row first, notes omitted) and are not read by any script.

| File | Manuscript item |
|---|---|
| `Table_1_Panel_A_trial_characteristics.csv` | Table 1, Panel A |
| `Table_1_Panel_B_geographic_distribution_by_subgroup.csv` | Table 1, Panel B (with WHO Member States n) |
| `Table_1_Panel_C_by_antibody.csv` | Table 1, Panel C |
| `Table_2_WHO_region_representation.csv` | Table 2 |
| `Table_3_country_level_disparities.csv` | Table 3 |
| `Table_4_status_by_income_group.csv` | Table 4 (new; see above) |
| `Table_5_published_trials_by_journal_and_income.csv` | Table 5 (new; see above) |
| `Supplementary_Table_S7_recruitment_and_publication_status.csv` | Supplementary Table S7 (updated) |
| `Supplementary_Table_S9_WHO_benchmarks.csv` | Supplementary Table S9 |
| `Supplementary_Table_S11_country_indicator_associations.csv` | Supplementary Table S11 (former Table 4) |
| `Supplementary_Table_S12_mutual_adjustment_HDI_RD.csv` | Supplementary Table S12 (new) |
| `Supplementary_Table_S13_equal_trial_weight.csv` | Supplementary Table S13 (new) |

The Member States and participation counts in Panel B equal those of `tables/table1_panel_b_member_states.csv` in all 26 subgroup rows.

## Differences from the 17 November snapshot (`results/native_document_tables/`)

| Snapshot file | What changed in the submitted tables |
|---|---|
| `manuscript_table_02.csv` (Table 1 Panel B) | New column WHO Member States n (Part I). |
| `manuscript_table_01.csv` (Table 1 Panel A) | Wording ("Non-industry", "Unclear/not reported") and one new row in the antibody list: "Multiple named mAbs", 6 (5.6). No other number changed. |
| `manuscript_table_03.csv` (Table 1 Panel C) | Capitalization of antibody names only. |
| `manuscript_table_05.csv` (Table 3) | Heading of block D now reads "Highest migraine burden among countries with zero participations in the primary analysis". No number changed. |
| `manuscript_table_06.csv` (former Table 4) | Moved to Supplementary Table S11; values unchanged. |
| `supplement_table_07.csv` (S7) | Classification by publication status revised: 63 completed trials with primary results published (319 participations) and 12 completed without a qualifying primary-results publication (42), replacing 59 (315) and 16 (46). Other rows unchanged. |
| `supplement_table_09.csv` (S9) | Replaced. The anti-CGRP column now uses all 132 records retained after deduplication, before eligibility assessment (477 participations; high income 414, 86.79%), and the all-clinical-trials column the WHO export of 18 November 2026 (1,464,719; high income 932,896, 63.69%); neuropsychiatric: 6 Nauru participations added (163,031). See Part I. |
| (no snapshot file) | Supplementary Tables S12 and S13 were added to the supplement. |
| `supplement_table_03.csv` (S3) | The submitted S3 also lists migraine YLDs per country. IHME estimates are not redistributed here, so the snapshot and `supplementary_full_rankings_108.csv` keep the version without YLDs. |

All other snapshot tables (`manuscript_table_04`, `supplement_table_01`, `_02`, `_04` to `_06`, `_08`, `_10`) are identical to the submitted ones after normalizing minus signs and dashes.

## Supplementary Table S13: equal trial weight (`supplement_equal_weight.py`)

Sensitivity to multi-country trials. In the primary analysis each country–trial pair counts once, so a trial with many countries weighs more. Here each of the 106 trials with geography contributes a total weight of 1, split equally among its countries (1/k per country), and the shares by World Bank income group (FY2019) and WHO region are compared with the primary shares (difference in percentage points, equal-weight minus primary).

```sh
python3 -I supplement_equal_weight.py <extracted public_data_and_reference_results.zip> out.csv
```

The script stops unless the primary counts equal the published ones (453 pairs; income groups 392, 42, 19, 0; regions 101, 297, 46, 7, 2, 0) and the weights sum to 106. Its output reproduces the table in the supplement cell for cell.
