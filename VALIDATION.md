# Reproducibility and public-package validation

The full 108-record preparation snapshot was executed on 17 November 2026:
burden-offset models and YLD-bound scenarios, covariate models, pre/post-approval
GEE, descriptive reconciliation and 99,999-resample clustered tests.
All 21 principal/sensitivity model rows matched the adopted analytical release.

Public packaging omits restricted inputs and direct source-estimate columns.
Observed registry counts, model equations, effect estimates and uncertainty
limits are unchanged. The public `analysis.R` omits only an unused read of a
legacy indicator table; no equation or data-selection rule is changed.

Public-package checks are run independently: ZIP integrity and member hashes;
absence of private input files; 108 unique records; 453 unique country–record
pairs; 106 records with geography; 47 participating countries; correspondence
to the 194-country universe; unchanged principal/sensitivity model estimates.
The complete pipeline is also tested by restoring the three exact external
inputs privately, without placing them in the public source package.

No city/site analysis, new eligibility decision, or manuscript revision is
introduced by this repository packaging. Version 1.0.3 is archived on Zenodo (https://doi.org/10.5281/zenodo.24515455; all versions: https://doi.org/10.5281/zenodo.24386424).
