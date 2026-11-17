# External input access and exact-snapshot reproduction

The public package deliberately excludes restricted third-party datasets and
country-level merged inputs that contain their direct numerical estimates.
`EXTERNAL_INPUTS.json` specifies each required file's relative path, SHA-256,
row count and column names. These hashes identify the reviewed snapshot; they
do not guarantee that a current portal download will be identical.

1. **GBD migraine YLDs:** use https://vizhub.healthdata.org/gbd-results/, GBD 2023
   release; year 2023; population group 1; measure YLDs (3); sex Both (3); age
   All ages (22); cause Migraine (547); metric Number (1). Retain `location_id`,
   `val`, `lower`, `upper` and the identifying/filter columns in the manifest.
   Match countries with the supplied GBD crosswalk. Access may require an IHME
   account and agreement to source terms. Do not replace the 2023 reference year
   with the latest available year without a documented new analysis version.
2. **Country GDP/HDI input:** the exact reviewed merge has 194 WHO Member States.
   GDP is World Bank NY.GDP.PCAP.PP.KD (PPP, constant 2021 international dollars),
   mean of available annual observations for the study period; HDI is UNDP,
   mean of available observations. Available data extend through 2025 and 2023,
   respectively, as specified in the codebook. Obtain source data through
   https://data.worldbank.org/indicator/NY.GDP.PCAP.PP.KD and
   https://hdr.undp.org/data-center. The preserved historical YLD column is an
   audit comparator, not the current model offset.
3. **HAQ/R&D input:** HAQ is the 2019 overall age-standardized index from IHME
   GBD 2019 HAQ, release `IHME_GBD_2019_HAQ_1990_2019_DATA_Y2022M012D21.CSV`.
   Use IHME/GHDx source access, respecting its terms. R&D is World Bank/UNESCO
   GB.XPD.RSDV.GD.ZS; select the available year closest to 2019 within 2015–2023,
   averaging equidistant years; do not fill missing countries. See CODEBOOK.md.

Exact reproduction requires the reviewed input snapshots or a faithful,
documented reconstruction that matches their checksums. If a portal has revised
its data, stop and document the difference rather than treating it as identical.
The investigator retains the full preparation snapshot privately. This repository
does not automatically retrieve data, grant source access, or promise unrestricted
redistribution of the original files. Registry counts and their validation remain
available without these external inputs.
