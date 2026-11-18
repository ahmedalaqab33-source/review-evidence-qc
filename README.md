# Review evidence QC

Development-stage R quality-control utilities for systematic-review extraction tables. This is a code-only subset of a local high-risk medication review reconstruction, with a newly added input-checking wrapper. It is not the original manuscript analysis or a clinically validated tool.

## Problem and functionality
Extraction workbooks can contain duplicate or missing study identifiers, invalid event counts, inconsistent confidence intervals, mismatched risk-of-bias records and inconsistent PRISMA arithmetic. The preserved functions flag these for investigator review; they do not correct data or establish source accuracy. The schema helper validates a two-workbook filename/hash manifest without reading workbooks.

## Computational approach
Deterministic base-R checks compare counts with denominators, verify numeric boundaries and match study identities. No pooled effects, model fitting, dosing advice or statistical imputation is implemented. The PRISMA helper assumes the original three-source linear flow; it does not support all PRISMA 2020 flow variants. CI checks do not distinguish log-scale versus transformed estimates automatically.

## Environment and installation
R 4.6.1 was used for the executed tests. No contributed packages, installation hooks or network access are needed. Clone https://github.com/ahmedalaqab33-source/review-evidence-qc and enter the repository directory. Run commands from this directory:

```sh
Rscript --vanilla tests/test_qc.R
Rscript --vanilla tests/test_api.R
Rscript --vanilla examples/synthetic_qc.R
```

Example output is one finding: invented row 3 has 9 events for 8 participants. All examples are invented. No study results are reproduced.

## Validation and limitations
The original synthetic regression script and the added API tests cover positive and negative examples, missingness, duplicate identities, event boundaries, risk-of-bias concordance, manifest/schema and PRISMA arithmetic, deterministic behavior and input preservation. Synthetic software tests establish only the tested mechanics. They do not establish extraction correctness, clinical validity, complete schema coverage, all R-version compatibility or the validity of the source review. See docs/VALIDATION.md.

## Data restrictions and status
No participant records, manuscript text, extraction sheets, source-paper PDFs, questionnaire instruments, model coefficients or clinical datasets are distributed. No scientific workflow was rerun. This code-only package is released under MIT with confirmed redistribution authority and applicable institutional/coauthor clearance. It remains development-stage research software. The parent manuscript workflow and all source data remain outside this release.

## Authorship and citation
Maintained by Ahmed Alaqab, who confirmed authority to redistribute the included original code and satisfaction of applicable contributor/institutional permissions. SOURCE_PROVENANCE.json records original hashes. New R/api.R, API tests and synthetic example were prepared in this execution. Use CITATION.cff for software citation. Version 0.1.0 identifies this bounded code-only release; it does not identify a validated manuscript analysis.
