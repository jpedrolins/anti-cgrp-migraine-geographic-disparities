# Figure 5 — status (18 November 2026)

Outputs: `Figure_5_who_benchmark.*` (Figure 5) and `Figure_S3_record_selection_stages.*`
(Supplementary Figure S3). Both are in the manuscript and supplement. Nothing in
`figures/figure5/` has been committed.

## What is validated

- **WHO migraine benchmark:** rebuilt from the WHO Global Observatory export
  "Trials by country.csv". It matches Supplementary Table S9 exactly (4,090).
- **WHO neuropsychiatric benchmark:** rebuilt from "Neuropsy - Trials by country (1).csv".
  It matches S9 except Nauru: 6 participations, FY2019 upper-middle income. S9 had
  dropped them because the reference file spells the name "Naoero". The
  investigator approved the correction on 18 November 2026: upper-middle income
  40,114 (24.61%), total 163,031. The high-income share is unchanged at 67.42%.
- **Counting unit:** all three WHO exports count trials with at least one site in each
  country, so the sums across Member States are country–trial participations, the
  same unit as the anti-CGRP column.
- **Member-State restriction:** non-member areas (territories, "Unknown", "NA") are excluded.
  Every export's unmatched names are checked against the all-trials export, which
  lists all 194 Member States.

## Anti-CGRP column (decided 18 November 2026)

Figure 5 uses **all 132 records retained after deduplication, before full-record
eligibility assessment** (477 country–trial participations; high income 414,
86.79%). The investigator chose this set; the earlier 468 set (108 eligible + 15
design-ineligible studies, `registry_design_relaxed_20261118/`) is superseded and
kept only as an audit trail.

`figure5_build_anti_cgrp_set.py` builds `anti_cgrp_record_sets_pairs.csv` from the
5 August 2026 snapshot for three PRISMA stages: all 167 records identified (747),
the 132 deduplicated records (477) and the 108 eligible trials (453). Applied to
the 108 eligible trials, the rule reproduces the 453 primary pairs exactly.

The three-bar version (`Rscript figure5_who_benchmark.R <data> <who_exports> figures
record_sets`) is **Supplementary Figure S3**, showing that the high-income share is
stable across the three stages (87.15%, 86.79%, 86.53%).

## WHO all clinical trials

Rebuilt from "Trials per country.csv" (downloaded 18 November 2026): 1,464,719
participations, high income 932,896 (63.69%). Supplementary Table S9 was updated to
these values on 18 November 2026 (it previously reported 1,512,056 / 62.68%, whose
source export was not found).

## Differences in high-income share (from counts)

| Benchmark | 167 records | 132 records (Figure 5) | 108 eligible |
|---|---|---|---|
| Migraine | +20.30 pp | +19.95 pp | +19.69 pp |
| Neuropsychiatric | +19.73 pp | +19.37 pp | +19.11 pp |
| All clinical trials | +23.46 pp | +23.10 pp | +22.84 pp |

## Reproduction

```sh
Rscript figure5_who_benchmark.R <registry_validation_dir> <folder with the three WHO exports> figures
```

## Design (revised 18 November 2026, at the investigator's request)

The figure was rebuilt on Figure 3's conventions so that it reads as part of the
same article:

- **Colours:** income groups use an ordinal navy ramp (`fig_income`): high income
  darkest, low income lightest. This replaces the earlier ochre and coral, which
  resembled Figure 4's WHO-region colours. Bars are drawn at full colour.
- **Key:** a single top-left key row (`fig_key_row`), as in Figure 3.
- **Right-hand columns:** "n" (participations) and "Difference, pp" (anti-CGRP
  high-income share minus the benchmark's), with 7.5-pt bold headers as in Figure 3.
- **Other conventions from Figure 3:** row pitch 7.2 mm, vertical baseline at 0%,
  in-segment percentages to one decimal.
- **Separation:** a thin rule separates the anti-CGRP set from the three WHO benchmarks.
- **Removed from the figure** (to go in the caption): the italic group label, the
  dagger and the in-figure footnote.
- **Draft marker:** removed on 18 November 2026 at the investigator's request.

The caption must give the low-income shares (anti-CGRP 0; migraine 0.05%;
neuropsychiatric 0.34%; all trials 0.61%), which are too narrow to label, and
the unclassified participations (12 and 45), which are kept in the denominators.

Size: 174 × 57 mm.
