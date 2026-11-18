# Executed checks

## Rscript --vanilla tests/test_qc.R

```text
QC regression tests passed; all fixtures are synthetic.
Cross-workbook and scientific review queue regressions passed.
Manifest and PRISMA boundary regressions passed.
```

## Rscript --vanilla tests/test_api.R

```text
API input, empty-frame, determinism, non-mutation and denominator boundary tests passed.
```

## Rscript --vanilla examples/synthetic_qc.R

```text
      sheet row               field severity                     issue
 extraction   3 Intervention_Events    error Events exceed denominator
```

No clinical analysis, workbook reading, package installation, network call or source-data validation was executed.
