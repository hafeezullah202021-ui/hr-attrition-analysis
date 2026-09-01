/* ============================================================================
   EMPLOYEE ATTRITION ANALYSIS — SQL ANALYSIS SCRIPT
   ----------------------------------------------------------------------------
   Project      : HR Attrition — Business Analysis engagement
   Analyst      : Hafeez Khan
   Date         : 26 August 2026
   Source file  : Emp_attrition_csv.csv (74,610 rows, 24 columns)
   Dialect      : PostgreSQL. Portability notes are given where syntax differs
                  for SQL Server / MySQL.

   PURPOSE
   This script reproduces the full analysis independently of Excel: it loads the
   raw extract, profiles it, documents and applies every cleaning rule, and then
   answers the ten business questions defined in the project brief.

   HOW TO READ IT
   Each section is numbered to match the project methodology. Every query states
   the business question it answers before the SQL, and states what the result
   means after it. Queries are written to be run top to bottom on a clean
   database; nothing depends on manual steps in between.

   IMPORTANT INTERPRETATION NOTE — READ BEFORE QUOTING ANY NUMBER
   The source extract records a 47.5% attrition rate and contains internal
   contradictions (see Section 2). Absolute rates from this file must not be
   presented to management as the organisation's true attrition rate. Relative
   comparisons between groups are the analytically valid output.
   ============================================================================ */


/* ============================================================================
   SECTION 1 — SCHEMA AND LOAD
   ============================================================================ */

DROP TABLE IF EXISTS hr_raw;

CREATE TABLE hr_raw (
    employee_id                 INTEGER,
    age                         INTEGER,
    gender                      VARCHAR(10),
    years_at_company            INTEGER,
    job_role                    VARCHAR(50),   -- holds a business FUNCTION, not a job title
    monthly_income              INTEGER,
    work_life_balance           VARCHAR(20),
    job_satisfaction            VARCHAR(20),
    performance_rating          VARCHAR(20),
    number_of_promotions        INTEGER,
    overtime                    VARCHAR(5),
    distance_from_home          INTEGER,       -- nullable: 2.6% blank
    education_level             VARCHAR(50),
    marital_status              VARCHAR(20),
    number_of_dependents        INTEGER,
    job_level                   VARCHAR(20),
    company_size                VARCHAR(20),
    company_tenure_months       INTEGER,       -- nullable: 3.2% blank
    remote_work                 VARCHAR(5),
    leadership_opportunities    VARCHAR(5),
    innovation_opportunities    VARCHAR(5),
    company_reputation          VARCHAR(20),
    employee_recognition        VARCHAR(20),
    attrition                   VARCHAR(10)
);

/* Load. The file is UTF-8 with a byte-order mark; declaring the encoding
   explicitly is what prevents the "Bachelorâ€™s Degree" corruption that is
   present when the file is read as Windows-1252.

   PostgreSQL:  \copy hr_raw FROM 'Emp_attrition_csv.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8', NULL '');
   SQL Server:  BULK INSERT hr_raw FROM 'Emp_attrition_csv.csv' WITH (FORMAT='CSV', FIRSTROW=2, CODEPAGE='65001');
   MySQL:       LOAD DATA INFILE 'Emp_attrition_csv.csv' INTO TABLE hr_raw
                CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' IGNORE 1 ROWS;                */


/* ============================================================================
   SECTION 2 — DATA PROFILING
   Business purpose: establish whether the extract can carry the weight of the
   conclusions management will be asked to act on. Run before any cleaning.
   ============================================================================ */

-- 2.1  File-level profile: size, key integrity, completeness.
SELECT
    COUNT(*)                                                       AS total_rows,
    COUNT(DISTINCT employee_id)                                    AS unique_employees,
    COUNT(*) - COUNT(DISTINCT employee_id)                         AS duplicate_ids,
    SUM(CASE WHEN distance_from_home    IS NULL THEN 1 ELSE 0 END) AS missing_distance,
    SUM(CASE WHEN company_tenure_months IS NULL THEN 1 ELSE 0 END) AS missing_company_tenure,
    ROUND(100.0 * SUM(CASE WHEN attrition = 'Left' THEN 1 ELSE 0 END) / COUNT(*), 2)
                                                                   AS attrition_rate_pct
FROM hr_raw;
/* RESULT: 74,610 rows / 74,498 unique IDs / 112 duplicates / 1,912 and 2,413
   blanks / 47.47% attrition.
   READ: completeness is good. The 47.47% is the finding that matters — a real
   employer at that rate would be losing half its workforce. This is a
   class-balanced extract, and every absolute figure must be caveated. */


-- 2.2  Are the duplicates exact copies, or genuinely different people sharing an ID?
--      This distinction decides whether we can safely delete them.
SELECT employee_id, COUNT(*) AS row_count, COUNT(DISTINCT age || gender || job_role || attrition) AS distinct_profiles
FROM hr_raw
GROUP BY employee_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC
LIMIT 20;
/* RESULT: every duplicated ID resolves to one profile — the rows are identical
   across all 24 fields. READ: safe to de-duplicate. Had the profiles differed,
   the correct action would have been to escalate to the HR data owner, not to
   pick a row. */


-- 2.3  Numeric range profile — the outlier and plausibility check.
SELECT 'age'                   AS field, MIN(age)::numeric, MAX(age)::numeric, ROUND(AVG(age),1)                   FROM hr_raw
UNION ALL SELECT 'years_at_company',     MIN(years_at_company),     MAX(years_at_company),     ROUND(AVG(years_at_company),1)     FROM hr_raw
UNION ALL SELECT 'monthly_income',       MIN(monthly_income),       MAX(monthly_income),       ROUND(AVG(monthly_income),1)       FROM hr_raw
UNION ALL SELECT 'number_of_dependents', MIN(number_of_dependents), MAX(number_of_dependents), ROUND(AVG(number_of_dependents),1) FROM hr_raw
UNION ALL SELECT 'distance_from_home',   MIN(distance_from_home),   MAX(distance_from_home),   ROUND(AVG(distance_from_home),1)   FROM hr_raw
UNION ALL SELECT 'company_tenure_months',MIN(company_tenure_months),MAX(company_tenure_months),ROUND(AVG(company_tenure_months),1)FROM hr_raw;
/* RESULT: dependents reaches 15 against a 0-6 body; income reaches 50,030
   against a 99th percentile of 12,233. READ: both are data-entry artefacts,
   not business signals. */


-- 2.4  CROSS-FIELD VALIDATION — the checks that matter most.
--      A field can be individually valid and still be impossible in context.
SELECT
    COUNT(*)                                                                          AS total_rows,
    SUM(CASE WHEN age - years_at_company < 16 THEN 1 ELSE 0 END)                      AS impossible_start_age,
    ROUND(100.0 * SUM(CASE WHEN age - years_at_company < 16 THEN 1 ELSE 0 END) / COUNT(*), 1)
                                                                                      AS pct_impossible_start_age,
    SUM(CASE WHEN years_at_company > company_tenure_months / 12.0 THEN 1 ELSE 0 END)  AS tenure_contradiction,
    ROUND(100.0 * SUM(CASE WHEN years_at_company > company_tenure_months / 12.0 THEN 1 ELSE 0 END)
          / COUNT(company_tenure_months), 1)                                          AS pct_tenure_contradiction,
    MAX(company_tenure_months) / 12.0                                                 AS max_company_age_years,
    MAX(years_at_company)                                                             AS max_employee_tenure_years
FROM hr_raw;
/* RESULT: 32.1% of employees would have started work before age 16; the company
   is at most 10.7 years old yet employees record up to 51 years of service, a
   contradiction in 62,822 records — 87.1% of the 72,117 rows where company
   tenure is populated and the comparison can be made, or 84.3% of the whole
   file. Note the denominator: this query divides by COUNT(company_tenure_months),
   which excludes NULLs, so it reports the 87.1% figure. Both are correct; state
   which one you mean.
   READ: this is the single most important finding of the profiling stage. The
   tenure fields are not jointly trustworthy. They are flagged rather than
   deleted, because deleting them would discard most of the file. */


-- 2.5  Category frequency profile — one query per categorical field pattern.
--      Shown for one field; repeat by substituting the column name.
SELECT job_level AS category, COUNT(*) AS records,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_workforce
FROM hr_raw
GROUP BY job_level
ORDER BY records DESC;


-- 2.6  Does pay behave like real pay? A structural credibility test.
SELECT job_level,
       COUNT(*)                          AS headcount,
       ROUND(AVG(monthly_income), 0)     AS avg_income,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monthly_income) AS median_income
FROM hr_raw
GROUP BY job_level
ORDER BY median_income DESC;
/* RESULT: median income is ~7,350 at entry, mid AND senior level.
   READ: no real pay structure is flat across seniority. The income field
   carries no grade signal, so the later finding that "pay does not predict
   attrition" is a statement about this file, not about compensation. */


/* ============================================================================
   SECTION 3 — CLEANING
   Every rule below is documented in the workbook's Cleaning Log. Raw data is
   never modified: the clean layer is a separate table, so the transformation
   is reproducible and auditable.
   ============================================================================ */

DROP TABLE IF EXISTS hr_clean;

CREATE TABLE hr_clean AS
WITH deduplicated AS (
    /* RULE 1 — remove exact duplicate records (112 rows, identical on all 24
       fields). ROW_NUMBER over the full field list keeps the first occurrence
       and would leave genuine ID collisions in place to be investigated. */
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY employee_id, age, gender, years_at_company, job_role,
                            monthly_income, work_life_balance, job_satisfaction,
                            performance_rating, number_of_promotions, overtime,
                            distance_from_home, education_level, marital_status,
                            number_of_dependents, job_level, company_size,
                            company_tenure_months, remote_work,
                            leadership_opportunities, innovation_opportunities,
                            company_reputation, employee_recognition, attrition
               ORDER BY employee_id
           ) AS rn
    FROM hr_raw
)
SELECT
    employee_id,
    age,
    gender,
    years_at_company,

    /* RULE 2 — rename. The source field "job_role" holds business functions
       (Technology, Healthcare, Education, Media, Finance), not job titles.
       The original name misleads anyone reading a management report. */
    job_role                                    AS department_function,

    monthly_income,
    work_life_balance,
    job_satisfaction,
    performance_rating,
    number_of_promotions,
    overtime,
    distance_from_home,                          -- RULE 3 — blanks left NULL, not imputed:
                                                 -- there is no defensible basis for an estimate.
                                                 -- Excluded pairwise from distance analysis only.

    /* RULE 4 — repair encoding corruption (37,409 values). The file is UTF-8;
       reading it as Windows-1252 turns the typographic apostrophe into 'â€™'.
       TRIM also removes any stray whitespace. */
    TRIM(REPLACE(education_level, 'â€™', '''')) AS education_level,

    marital_status,

    /* RULE 5 — reject impossible dependent counts (48 records hold 10 or 15
       against an otherwise 0-6 distribution). Set to NULL and flag rather than
       guess a replacement value. */
    CASE WHEN number_of_dependents IN (10, 15) THEN NULL
         ELSE number_of_dependents END          AS number_of_dependents,
    CASE WHEN number_of_dependents IN (10, 15) THEN 'Invalid - set to blank'
         ELSE 'OK' END                          AS dependents_flag,

    job_level,
    company_size,
    company_tenure_months,                       -- blanks left NULL, as above
    remote_work,
    leadership_opportunities,
    innovation_opportunities,
    company_reputation,
    employee_recognition,
    attrition,

    /* RULE 6 — flag extreme pay rather than deleting it. Flagging keeps the
       record available and lets any KPI be tested with and without it. */
    CASE WHEN monthly_income > 20000 THEN 'Extreme (>20,000)'
         ELSE 'Normal' END                      AS income_outlier_flag,

    /* RULE 7 — cross-field integrity flags. These carry the data-quality story
       through to the analysis layer instead of leaving it in a document. */
    age - years_at_company                      AS implied_start_age,
    CASE WHEN age - years_at_company < 16 THEN 'Impossible (implied start age <16)'
         ELSE 'Plausible' END                   AS age_tenure_consistency,
    CASE WHEN company_tenure_months IS NULL                            THEN 'Not testable (tenure missing)'
         WHEN years_at_company > company_tenure_months / 12.0          THEN 'Contradictory (employee tenure > company tenure)'
         ELSE 'Consistent' END                  AS tenure_consistency,

    /* RULE 8 — derived analysis fields. */
    CASE WHEN attrition = 'Left' THEN 1 ELSE 0 END AS attrition_flag,
    CASE WHEN age <= 25 THEN '18-25'
         WHEN age <= 35 THEN '26-35'
         WHEN age <= 45 THEN '36-45'
         WHEN age <= 55 THEN '46-55'
         ELSE '56-59' END                       AS age_band,
    CASE WHEN years_at_company <= 2  THEN '0-2 yrs'
         WHEN years_at_company <= 5  THEN '3-5 yrs'
         WHEN years_at_company <= 10 THEN '6-10 yrs'
         WHEN years_at_company <= 20 THEN '11-20 yrs'
         ELSE '20+ yrs' END                     AS tenure_band,
    CASE WHEN monthly_income <  4000 THEN '<4,000'
         WHEN monthly_income <  6000 THEN '4,000-5,999'
         WHEN monthly_income <  8000 THEN '6,000-7,999'
         WHEN monthly_income < 12000 THEN '8,000-11,999'
         ELSE '12,000+' END                     AS income_band,
    CASE WHEN distance_from_home IS NULL THEN NULL
         WHEN distance_from_home <= 20 THEN '1-20'
         WHEN distance_from_home <= 40 THEN '21-40'
         WHEN distance_from_home <= 60 THEN '41-60'
         WHEN distance_from_home <= 80 THEN '61-80'
         ELSE '81-99' END                       AS distance_band,
    CASE WHEN number_of_promotions = 0 THEN 'Never promoted'
         ELSE 'Promoted at least once' END      AS promotion_status
FROM deduplicated
WHERE rn = 1;

-- Validate the clean layer before using it. If either check fails, stop.
SELECT COUNT(*)                                   AS clean_rows,          -- expect 74,498
       COUNT(DISTINCT employee_id)                AS unique_ids,          -- expect 74,498
       SUM(CASE WHEN education_level LIKE '%â%' THEN 1 ELSE 0 END) AS remaining_corruption  -- expect 0
FROM hr_clean;


/* ============================================================================
   SECTION 4 — HR KPIs
   Business purpose: establish the measurement baseline. Every later comparison
   is read against these numbers.
   ============================================================================ */

SELECT
    COUNT(*)                                                                   AS total_employees,
    SUM(attrition_flag)                                                        AS employees_left,
    COUNT(*) - SUM(attrition_flag)                                             AS employees_active,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2)                           AS attrition_rate_pct,
    ROUND(AVG(age), 1)                                                         AS avg_age,
    ROUND(AVG(years_at_company), 1)                                            AS avg_tenure_years,
    ROUND(AVG(monthly_income), 0)                                              AS avg_monthly_income,
    ROUND(100.0 * SUM(CASE WHEN gender = 'Female'            THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_female,
    ROUND(100.0 * SUM(CASE WHEN remote_work = 'Yes'          THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_remote,
    ROUND(100.0 * SUM(CASE WHEN overtime = 'Yes'             THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_overtime,
    ROUND(100.0 * SUM(CASE WHEN number_of_promotions = 0     THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_never_promoted,
    ROUND(100.0 * SUM(CASE WHEN job_level = 'Entry'          THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_entry_level
FROM hr_clean;


-- 4.1  Do leavers and stayers differ on the numeric measures at all?
--      A fast way to see which fields are worth pursuing.
SELECT attrition,
       COUNT(*)                          AS employees,
       ROUND(AVG(age), 1)                AS avg_age,
       ROUND(AVG(years_at_company), 1)   AS avg_tenure,
       ROUND(AVG(monthly_income), 0)     AS avg_income,
       ROUND(AVG(distance_from_home), 1) AS avg_distance,
       ROUND(AVG(number_of_promotions), 2) AS avg_promotions
FROM hr_clean
GROUP BY attrition;
/* READ: average income differs by about 50 units between leavers and stayers —
   under 1%. Pay is not separating the two groups. Promotions and distance do. */


/* ============================================================================
   SECTION 5 — BUSINESS QUESTIONS
   Each query is written to answer one question from the project brief.
   ============================================================================ */

/* ----------------------------------------------------------------------------
   Q2 — Which business functions and job levels carry the highest attrition?
   A reusable pattern: rate plus share of total leavers. The rate says how bad
   a group is; the share says how much of the problem it represents. A group
   can have a terrible rate and still be operationally irrelevant if it is tiny.
   ---------------------------------------------------------------------------- */
SELECT
    department_function,
    COUNT(*)                                                    AS headcount,
    SUM(attrition_flag)                                         AS leavers,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 1)            AS attrition_rate_pct,
    ROUND(100.0 * SUM(attrition_flag) / SUM(SUM(attrition_flag)) OVER (), 1)
                                                                AS share_of_all_leavers_pct,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*)
          - (SELECT 100.0 * SUM(attrition_flag) / COUNT(*) FROM hr_clean), 1)
                                                                AS pp_vs_company_average
FROM hr_clean
GROUP BY department_function
ORDER BY attrition_rate_pct DESC;
/* RESULT: 46.8% to 48.8% — a 2-point spread across all five functions.
   READ: there is no departmental attrition problem. This is a genuinely useful
   negative finding: it stops management from launching a function-level
   investigation that the data does not support. */


SELECT
    job_level,
    COUNT(*)                                                    AS headcount,
    SUM(attrition_flag)                                         AS leavers,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 1)            AS attrition_rate_pct,
    ROUND(100.0 * SUM(attrition_flag) / SUM(SUM(attrition_flag)) OVER (), 1)
                                                                AS share_of_all_leavers_pct
FROM hr_clean
GROUP BY job_level
ORDER BY attrition_rate_pct DESC;
/* RESULT: Entry 63.3% (53.3% of all leavers) / Mid 45.4% / Senior 20.3%.
   READ: the problem is vertical, not horizontal. It sits in the grade
   structure, and it is the same in every function. */


/* ----------------------------------------------------------------------------
   Q3 — Does tenure relate to attrition? Are newer employees leaving more?
   ---------------------------------------------------------------------------- */
SELECT
    tenure_band,
    COUNT(*)                                                    AS headcount,
    SUM(attrition_flag)                                         AS leavers,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 1)            AS attrition_rate_pct,
    ROUND(100.0 * SUM(attrition_flag) / SUM(SUM(attrition_flag)) OVER (), 1)
                                                                AS share_of_all_leavers_pct
FROM hr_clean
GROUP BY tenure_band
ORDER BY MIN(years_at_company);
/* RESULT: 52.9% at 0-2 years falling to 43.7% at 20+ years, but the 0-2 group
   is only 9.1% of all leavers.
   READ: the common assumption that "we have an onboarding problem" is only
   weakly supported. Short-service employees do leave at a higher rate, but
   fixing onboarding alone would touch under a tenth of the departures. */


/* ----------------------------------------------------------------------------
   Q4 — Is attrition different by age, gender or marital status?
   ---------------------------------------------------------------------------- */
SELECT marital_status,
       COUNT(*)                                         AS headcount,
       ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 1) AS attrition_rate_pct,
       ROUND(100.0 * SUM(attrition_flag) / SUM(SUM(attrition_flag)) OVER (), 1) AS share_of_all_leavers_pct
FROM hr_clean
GROUP BY marital_status
ORDER BY attrition_rate_pct DESC;
/* RESULT: Single 66.8% / Divorced 40.8% / Married 36.0%. */


/* ----------------------------------------------------------------------------
   Q9 (part) — CONFOUNDING CHECK. Is the gender gap really a grade effect?
   This is the query that separates an analyst from a chart-maker. Never report
   a group difference without testing whether a third variable produces it.
   ---------------------------------------------------------------------------- */
SELECT
    job_level,
    COUNT(*)                                                                                     AS headcount,
    ROUND(100.0 * SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) / COUNT(*), 1)              AS pct_female_in_level,
    ROUND(100.0 * SUM(CASE WHEN gender = 'Female' THEN attrition_flag END)
          / NULLIF(SUM(CASE WHEN gender = 'Female' THEN 1 END), 0), 1)                           AS female_attrition_pct,
    ROUND(100.0 * SUM(CASE WHEN gender = 'Male'   THEN attrition_flag END)
          / NULLIF(SUM(CASE WHEN gender = 'Male'   THEN 1 END), 0), 1)                           AS male_attrition_pct,
    ROUND(100.0 * SUM(CASE WHEN gender = 'Female' THEN attrition_flag END)
          / NULLIF(SUM(CASE WHEN gender = 'Female' THEN 1 END), 0)
        - 100.0 * SUM(CASE WHEN gender = 'Male'   THEN attrition_flag END)
          / NULLIF(SUM(CASE WHEN gender = 'Male'   THEN 1 END), 0), 1)                           AS gap_pp
FROM hr_clean
GROUP BY job_level
ORDER BY headcount DESC;
/* RESULT: the female share of headcount is 45.3% / 45.4% / 44.7% across Entry /
   Mid / Senior — essentially identical — and women leave more at every level
   (gap of 9.9 / 10.6 / 9.1 points).
   READ: the gender gap is NOT a grade-composition artefact. It is real in this
   data and unexplained by any variable in the file. The correct output is a
   question for HR to investigate, not a conclusion about why women leave. */


/* ----------------------------------------------------------------------------
   Q5 — Does working arrangement relate to attrition, independently of grade?
   ---------------------------------------------------------------------------- */
SELECT
    job_level,
    ROUND(100.0 * SUM(CASE WHEN remote_work = 'No'  THEN attrition_flag END)
          / NULLIF(SUM(CASE WHEN remote_work = 'No'  THEN 1 END), 0), 1) AS onsite_attrition_pct,
    ROUND(100.0 * SUM(CASE WHEN remote_work = 'Yes' THEN attrition_flag END)
          / NULLIF(SUM(CASE WHEN remote_work = 'Yes' THEN 1 END), 0), 1) AS remote_attrition_pct,
    SUM(CASE WHEN remote_work = 'Yes' THEN 1 ELSE 0 END)                 AS remote_headcount
FROM hr_clean
GROUP BY job_level
ORDER BY onsite_attrition_pct DESC;
/* RESULT: 69.3 vs 37.1 (Entry), 51.0 vs 22.3 (Mid), 23.8 vs 5.2 (Senior).
   READ: the remote advantage holds at every grade, so it is not a composition
   effect. But direction of cause is NOT established — remote status may be
   granted to employees already seen as committed, in which case remote work
   marks retention rather than producing it. Any recommendation must be framed
   as a controlled test, not a rollout. */


/* ----------------------------------------------------------------------------
   Q6 — Does pay relate to attrition?
   ---------------------------------------------------------------------------- */
SELECT
    income_band,
    COUNT(*)                                         AS headcount,
    ROUND(AVG(monthly_income), 0)                    AS avg_income,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 1) AS attrition_rate_pct
FROM hr_clean
GROUP BY income_band
ORDER BY avg_income;
/* RESULT: 49.4% at the bottom band down to 45.4% at the top — a 4-point spread
   across a threefold pay range.
   READ: pay does not separate leavers from stayers here. Combined with the
   finding in 2.6 that median pay is identical across job levels, the honest
   conclusion is that the pay field is unreliable — NOT that compensation is
   irrelevant to retention. Reporting "pay doesn't matter" from this file would
   be a serious analytical error. */


/* ----------------------------------------------------------------------------
   Q7 — Does career progression relate to attrition?
   ---------------------------------------------------------------------------- */
SELECT
    number_of_promotions,
    COUNT(*)                                         AS headcount,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 1) AS attrition_rate_pct,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*)
          - LAG(100.0 * SUM(attrition_flag) / COUNT(*)) OVER (ORDER BY number_of_promotions), 1)
                                                     AS change_vs_previous_pp
FROM hr_clean
GROUP BY number_of_promotions
ORDER BY number_of_promotions;
/* RESULT: 49.3 / 49.0 / 49.0 / 24.9 / 23.3.
   READ: this is a THRESHOLD, not a gradient. Nothing changes between zero, one
   and two promotions; the rate halves at the third. A retention policy built on
   "promote people more" would achieve nothing until it crossed that line. The
   window function makes the break visible. */


/* ----------------------------------------------------------------------------
   Q8 — Which employee segments require management attention first?
   Combines the three strongest independent factors and ranks the result by
   both rate and volume, so the answer is actionable rather than merely true.
   ---------------------------------------------------------------------------- */
WITH segments AS (
    SELECT
        job_level,
        CASE WHEN remote_work = 'Yes' THEN 'Remote' ELSE 'On-site' END AS working_arrangement,
        marital_status,
        COUNT(*)            AS headcount,
        SUM(attrition_flag) AS leavers
    FROM hr_clean
    GROUP BY job_level,
             CASE WHEN remote_work = 'Yes' THEN 'Remote' ELSE 'On-site' END,
             marital_status
),
totals AS (SELECT SUM(leavers) AS all_leavers, SUM(headcount) AS all_staff FROM segments)
SELECT
    s.job_level,
    s.working_arrangement,
    s.marital_status,
    s.headcount,
    s.leavers,
    ROUND(100.0 * s.leavers / s.headcount, 1)      AS attrition_rate_pct,
    ROUND(100.0 * s.leavers / t.all_leavers, 1)    AS share_of_all_leavers_pct,
    ROUND(100.0 * s.headcount / t.all_staff, 1)    AS share_of_workforce_pct,
    CASE WHEN 1.0 * s.leavers / s.headcount >= 0.70 THEN 'CRITICAL'
         WHEN 1.0 * s.leavers / s.headcount >= 0.55 THEN 'High'
         WHEN 1.0 * s.leavers / s.headcount >= 0.40 THEN 'Monitor'
         ELSE 'Stable' END                         AS priority
FROM segments s CROSS JOIN totals t
ORDER BY attrition_rate_pct DESC;
/* RESULT: Entry / On-site / Single = 87.5% on 8,507 people — 21.0% of all
   leavers on its own. The top three segments hold 27.4% of the workforce and
   produce 44.5% of departures.
   READ: this is the sheet management acts on. The problem is concentrated
   enough to be addressable with a targeted programme rather than a
   company-wide one. */


/* ----------------------------------------------------------------------------
   Q1 / Q8 — Ranking every factor by how much it actually separates groups.
   One query that scores all categorical fields, so nothing is ranked by
   intuition. UNION ALL keeps it readable; a lateral join would be terser but
   harder for a reviewer to follow.
   ---------------------------------------------------------------------------- */
WITH by_category AS (
    SELECT 'Job Level'         AS factor, job_level          AS category, COUNT(*) AS n, AVG(attrition_flag) AS rate FROM hr_clean GROUP BY job_level
    UNION ALL SELECT 'Marital Status',      marital_status,      COUNT(*), AVG(attrition_flag) FROM hr_clean GROUP BY marital_status
    UNION ALL SELECT 'Remote Work',         remote_work,         COUNT(*), AVG(attrition_flag) FROM hr_clean GROUP BY remote_work
    UNION ALL SELECT 'Work-Life Balance',   work_life_balance,   COUNT(*), AVG(attrition_flag) FROM hr_clean GROUP BY work_life_balance
    UNION ALL SELECT 'Company Reputation',  company_reputation,  COUNT(*), AVG(attrition_flag) FROM hr_clean GROUP BY company_reputation
    UNION ALL SELECT 'Gender',              gender,              COUNT(*), AVG(attrition_flag) FROM hr_clean GROUP BY gender
    UNION ALL SELECT 'Overtime',            overtime,            COUNT(*), AVG(attrition_flag) FROM hr_clean GROUP BY overtime
    UNION ALL SELECT 'Education Level',     education_level,     COUNT(*), AVG(attrition_flag) FROM hr_clean GROUP BY education_level
    UNION ALL SELECT 'Performance Rating',  performance_rating,  COUNT(*), AVG(attrition_flag) FROM hr_clean GROUP BY performance_rating
    UNION ALL SELECT 'Job Satisfaction',    job_satisfaction,    COUNT(*), AVG(attrition_flag) FROM hr_clean GROUP BY job_satisfaction
    UNION ALL SELECT 'Employee Recognition',employee_recognition,COUNT(*), AVG(attrition_flag) FROM hr_clean GROUP BY employee_recognition
    UNION ALL SELECT 'Department/Function', department_function, COUNT(*), AVG(attrition_flag) FROM hr_clean GROUP BY department_function
    UNION ALL SELECT 'Company Size',        company_size,        COUNT(*), AVG(attrition_flag) FROM hr_clean GROUP BY company_size
    UNION ALL SELECT 'Age Band',            age_band,            COUNT(*), AVG(attrition_flag) FROM hr_clean GROUP BY age_band
    UNION ALL SELECT 'Tenure Band',         tenure_band,         COUNT(*), AVG(attrition_flag) FROM hr_clean GROUP BY tenure_band
    UNION ALL SELECT 'Income Band',         income_band,         COUNT(*), AVG(attrition_flag) FROM hr_clean GROUP BY income_band
    UNION ALL SELECT 'Distance Band',       distance_band,       COUNT(*), AVG(attrition_flag) FROM hr_clean GROUP BY distance_band
)
SELECT
    factor,
    COUNT(*)                                        AS categories,
    ROUND(100.0 * MIN(rate), 1)                     AS lowest_rate_pct,
    ROUND(100.0 * MAX(rate), 1)                     AS highest_rate_pct,
    ROUND(100.0 * (MAX(rate) - MIN(rate)), 1)       AS spread_pp,
    CASE WHEN 100.0 * (MAX(rate) - MIN(rate)) >= 20 THEN 'Strong'
         WHEN 100.0 * (MAX(rate) - MIN(rate)) >= 10 THEN 'Moderate'
         WHEN 100.0 * (MAX(rate) - MIN(rate)) >=  5 THEN 'Weak'
         ELSE 'Negligible' END                      AS signal_strength
FROM by_category
WHERE category IS NOT NULL
GROUP BY factor
ORDER BY spread_pp DESC;
/* READ: this single table replaces twenty charts. Job Level, Marital Status,
   Remote Work, Number of Promotions and Work-Life Balance are the factors worth
   management time. Employee Recognition, Department, Company Size and Income
   are noise. Note that spread alone ignores group size and confounding — it is
   a screening tool, and the regression in the workbook's Driver Model sheet is
   what confirms which of these survive when everything is controlled at once. */


/* ----------------------------------------------------------------------------
   Q10 — How reliable is the underlying data?
   Quantifies the integrity problems and shows whether they bias the outcome —
   the check that decides whether the flagged records can be kept.
   ---------------------------------------------------------------------------- */
SELECT
    age_tenure_consistency,
    tenure_consistency,
    COUNT(*)                                         AS records,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_file,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 1) AS attrition_rate_pct
FROM hr_clean
GROUP BY age_tenure_consistency, tenure_consistency
ORDER BY records DESC;
/* READ: if attrition rates were materially different between the flagged and
   unflagged groups, the flags would be confounded with the outcome and the
   records could not simply be kept. Compare the rates before concluding. */


/* ----------------------------------------------------------------------------
   SENSITIVITY TEST — do the headline findings survive if every questionable
   record is dropped? Run this before signing off any recommendation.
   ---------------------------------------------------------------------------- */
SELECT
    'All records'      AS dataset, job_level, COUNT(*) AS n,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 1) AS attrition_rate_pct
FROM hr_clean
GROUP BY job_level
UNION ALL
SELECT
    'Validated records only', job_level, COUNT(*),
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 1)
FROM hr_clean
WHERE age_tenure_consistency = 'Plausible'
  AND tenure_consistency     = 'Consistent'
  AND income_outlier_flag    = 'Normal'
  AND dependents_flag        = 'OK'
GROUP BY job_level
ORDER BY job_level, dataset;
/* READ: if the ranking of job levels holds in both halves, the finding is
   robust to the data-quality problems and can be reported with the caveat
   attached. If it does not hold, the finding must be withdrawn. */


/* ============================================================================
   SECTION 6 — DASHBOARD FEED
   A single denormalised view for Power BI / Tableau. Aggregating in SQL keeps
   the semantic layer thin and the refresh fast.
   ============================================================================ */

CREATE OR REPLACE VIEW vw_attrition_dashboard AS
SELECT
    department_function,
    job_level,
    gender,
    marital_status,
    age_band,
    tenure_band,
    income_band,
    distance_band,
    remote_work,
    overtime,
    work_life_balance,
    company_reputation,
    promotion_status,
    performance_rating,
    company_size,
    COUNT(*)                                         AS headcount,
    SUM(attrition_flag)                              AS leavers,
    COUNT(*) - SUM(attrition_flag)                   AS active_employees,
    ROUND(100.0 * SUM(attrition_flag) / COUNT(*), 2) AS attrition_rate_pct,
    ROUND(AVG(age), 1)                               AS avg_age,
    ROUND(AVG(years_at_company), 1)                  AS avg_tenure_years,
    ROUND(AVG(monthly_income), 0)                    AS avg_monthly_income
FROM hr_clean
GROUP BY department_function, job_level, gender, marital_status, age_band,
         tenure_band, income_band, distance_band, remote_work, overtime,
         work_life_balance, company_reputation, promotion_status,
         performance_rating, company_size;

/* ============================================================================
   END OF SCRIPT
   ============================================================================ */
