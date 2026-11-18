# Geographic disparities in anti-CGRP migraine trials

Research code and curated registry data for *Geographic disparities in registered
clinical trials of anti-CGRP monoclonal antibodies for migraine*. This is a public
working repository; the definitive archived release will be deposited on Zenodo
after the manuscript and analyses are finalized.

## Study and analytical unit

The reviewed dataset contains 108 eligible registry records, of which 106 have
an eligible recruitment country, contributing 453 unique country–record
participations across 47 countries. The country-level universe comprises all
194 WHO Member States, including countries with zero participations.

A record contributes at most once per country, regardless of recruitment-site
count. The 22 country–record pairs explicitly listed as removed remain excluded.
City-level and site-level analyses are not included. Migraine burden is based on
GBD 2023 estimates for 2023: all-age, both-sex YLD numbers and 95% uncertainty
intervals. World Bank income groups use the fixed FY2019 classification.

NCT04361721 was included by author adjudication. Its original registry label
`OBSERVATIONAL` is preserved alongside the adjudicated analytical classification.
The discrepancy is documented, not presented as a change to the source registry.

## Repository contents

- R scripts: burden-offset negative-binomial models, country-level covariates,
  uncertainty-bound analyses, temporal comparisons, and scientific figures.
- Python scripts: descriptive reconciliation and record-clustered subgroup tests.
- `public_data_and_reference_results.zip`: reviewed registry data, country/region
  mappings, Natural Earth plotting support and numerical reference results.
- `CODEBOOK.md`: definitions, harmonization decisions and analytical specifications.
- `EXTERNAL_INPUTS.json` and `DATA_ACCESS.md`: required external inputs, exact
  checksums, expected schemas and acquisition instructions.
- `VALIDATION.md`: scope of the reproduction and public-package checks.

Restricted third-party source data and merged input tables containing those
values are not distributed. Their omission does not change any analytical result.
See `LICENSES.md` for rights and source attribution.

## Reproduction

Python 3.10 or newer is required for the launcher. Validate the curated registry
counts without downloading external inputs:

```sh
python3 run_analysis.py --output ../registry_validation --validate-only
```

To run the full analysis, obtain the exact reviewed external input snapshots
described in `DATA_ACCESS.md`, preserving the relative paths listed in
`EXTERNAL_INPUTS.json`:

```sh
python3 run_analysis.py --output ../full_reproduction --external-inputs /path/to/external_inputs --clustered --figures
```

The output directory must be new. The launcher verifies checksums before running
the analysis, preserves reference outputs and makes no API calls. It stops if
an input is missing or differs from the reviewed snapshot; it never imputes a
missing source or substitutes newer data silently.

R packages: MASS, sandwich, jsonlite, ggplot2, dplyr, tidyr, readr, sf, ggrepel,
patchwork and geepack; the refined figures also use svglite, rsvg and ragg. Python packages for clustered tests: numpy and pandas.
Environment details are retained in the archived `results/R_session_info.txt`.
The subgroup tests use 99,999 resamples with a recorded fixed seed.

## Figures

`figure_theme.R` is the shared design system (typography, palette, line weights,
export sizes) for the manuscript figures. The publication version of Figure 2
(geographic distribution and O/E map) is produced by
`figure2_global_distribution.R` and committed in `figures/figure2/` as PDF, SVG
and 600-dpi PNG, with its plotted values and a validation record. Regenerate it
after the registry validation step:

```sh
Rscript figure2_global_distribution.R ../registry_validation figures/figure2
```

See CODEBOOK.md, Part E. `figure2_vertical.R` is the previous version.

Figure 3 (observed participation share vs share of migraine YLDs, with O/E, by
WHO region and World Bank income group) is produced by
`figure3_burden_representation.R` into `figures/figure3/`; it validates every
value against the release and manuscript Table 2 before drawing (CODEBOOK.md,
Part F). `build_figure3.R` is the previous income-only version.

```sh
Rscript figure3_burden_representation.R ../registry_validation figures/figure3
```

## Development and citation

Updates are tracked through Git commits. This working repository is not a claim
that the manuscript has been accepted or published. Zenodo remains an unpublished
draft; its reserved DOI is not yet an active citation. The final manuscript will
cite the specific archived code/data version that produced its reported results.

For the current working code, see `CITATION.cff` and cite the relevant commit.
No new software or documentation licence is granted by making the repository
public; a reusable open licence remains to be approved by the investigators.
