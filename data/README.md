# Data

**`Emp_attrition_csv.csv`** — the source extract for this analysis. 74,610 rows × 24 columns of synthetic HR attrition data, committed here unaltered.

## Schema

The full column list, types, permitted values and nullability are documented in:

- `sql/hr_attrition_analysis.sql` — Section 1, the `hr_raw` table definition
- `excel/HR_Attrition_Analysis.xlsx` — the **Data Dictionary** sheet

## Loading it

The SQL script is written for PostgreSQL and expects the table `hr_raw`:

```sql
\copy hr_raw FROM 'data/Emp_attrition_csv.csv' WITH (FORMAT csv, HEADER true);
```

The file is UTF-8 with a BOM and uses spaced column headers (`Years at Company`,
`Company Tenure (In Months)`), which the script maps to snake_case on load.
Portability notes for SQL Server and MySQL are given inline in the script.

## A note on the data

This is synthetic data used for analysis practice. It contains genuine internal
contradictions — impossible age/tenure combinations, a pay field with no seniority
signal, and a class-balanced outcome variable. These are treated as **findings**
rather than worked around; see [`docs/FINDINGS.md`](../docs/FINDINGS.md), Section 1.

Absolute rates from this file are not quotable as organisational facts. Relative
comparisons between groups are the analytically valid output.
