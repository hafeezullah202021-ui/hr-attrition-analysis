# Findings — HR Employee Attrition Analysis

Complete analytical findings from the 74,610-record HR workforce extract. Every figure here was independently recomputed from the raw file by a separate verification script sharing no code with the analysis pipeline (109/109 checks passed).

**Analysis base:** 74,498 records after cleaning · **Recorded attrition:** 47.48% (35,370 leavers)

---

## 0. Read this first

The source extract records a **47.5% attrition rate**. No functioning employer loses half its workforce in a reporting period. This file has been balanced between leavers and stayers, and it carries internal contradictions documented in Section 1.

| Can be relied on | Cannot be relied on |
|---|---|
| Relative comparisons between employee groups | Any absolute rate as an organisational fact |
| The ranking of factors by strength | The precise magnitude of any single effect |
| Identification of high-risk segments | Anything resting on the pay field |
| The direction of every effect reported | Any tenure finding stated without its caveat |
| The negative findings | Any causal claim whatsoever |

---

## 1. Data quality — the constraint on everything below

Profiling ran before analysis, which is what surfaced these. Four problems are not correctable by cleaning, because the values contradict each other rather than being malformed.

### 1.1 Integrity failures

| # | Finding | Scale |
|---|---|---|
| 1 | **Age and tenure are mutually impossible.** Age − Years at Company gives an implied start age below 16. | 23,902 records — **32.1%** |
| 2 | **The two tenure fields contradict each other.** Company Tenure never exceeds 128 months (10.7 years), yet employees record up to 51 years of service at that company. | 62,822 records — **84.3%** of the file, 87.1% of the 72,117 testable rows |
| 3 | **The pay field carries no seniority signal.** Median monthly income is ~7,350 at entry, mid *and* senior level. | All records |
| 4 | **The outcome variable is balanced, not natural.** 47.47% recorded attrition, near an even split. | All records |

Additionally, **Job Satisfaction is non-monotonic**: the lowest-satisfaction group leaves at 52.8% and the highest at 53.0%, while the two middle categories sit at 45.4% and 45.0%. A satisfaction scale in which the most and least satisfied behave identically is not measuring satisfaction reliably. The field is excluded from the recommendations.

### 1.2 Formatting issues — minor, fully corrected

| Issue | Volume | % of file | Action |
|---|---|---|---|
| Exact duplicate records | 112 | 0.15% | Removed — all resolved to a single profile, so deletion was safe |
| Encoding corruption (Education Level) | 37,409 values | 50.1% | Repaired — UTF-8 file read as Windows-1252 |
| Missing — Company Tenure | 2,381 | 3.2% | Left blank, excluded pairwise; not imputed |
| Missing — Distance from Home | 1,897 | 2.5% | Left blank, excluded pairwise; not imputed |
| Invalid dependent counts (10, 15) | 48 | 0.06% | Nulled and flagged |
| Extreme income (>20,000) | 87 | 0.12% | Flagged, retained for sensitivity testing |

### 1.3 The judgment call

Records failing cross-field validation were **flagged, not deleted**. Removing a third to four-fifths of the file would have biased every subsequent comparison more than retaining flagged records does. The contradictions are disclosed as a limitation instead, and the flags are carried through into the analysis layer so any finding can be re-tested on validated records only.

---

## 2. Factor ranking — what actually separates groups

Percentage-point spread between the highest and lowest category of each factor. This single table replaces twenty charts and decides where management time goes.

| Factor | Spread | Range | Signal |
|---|---|---|---|
| Job Level | **43.0 pp** | 20.3% → 63.3% | **Strong** |
| Marital Status | **30.8 pp** | 36.0% → 66.8% | **Strong** |
| Remote Work | **28.1 pp** | 24.7% → 52.8% | **Strong** |
| Number of Promotions | **26.0 pp** | 23.3% → 49.3% | **Strong** |
| Work-Life Balance | **24.5 pp** | 35.7% → 60.2% | **Strong** |
| Education Level | 24.5 pp | 24.4% → 48.9% | Strong, but PhD only |
| Number of Dependents | 21.4 pp | 28.6% → 50.0% | Moderate |
| Company Reputation | 13.0 pp | 43.0% → 56.0% | Moderate |
| Distance from Home | 11.3 pp | 41.7% → 53.0% | Moderate |
| Performance Rating | 11.0 pp | 46.1% → 57.1% | Moderate |
| Gender | 10.1 pp | 42.9% → 53.0% | Moderate |
| Tenure Band | 9.4 pp | 43.7% → 53.1% | Weak |
| Age Band | 8.6 pp | 44.5% → 53.1% | Weak |
| Job Satisfaction | 8.0 pp | 45.0% → 53.0% | Unreliable — non-monotonic |
| Overtime | 6.0 pp | 45.5% → 51.5% | Weak |
| Income Band | 4.1 pp | 45.4% → 49.5% | **Negligible** |
| Company Size | 3.2 pp | 46.5% → 49.7% | **Negligible** |
| Innovation Opportunities | 3.0 pp | 45.0% → 48.0% | **Negligible** |
| Leadership Opportunities | 2.8 pp | 44.8% → 47.6% | **Negligible** |
| Department / Function | 2.0 pp | 46.8% → 48.8% | **Negligible** |
| Employee Recognition | 1.8 pp | 46.0% → 47.8% | **Negligible** |

Spread is a screening tool only — it ignores group size and confounding. Section 5 confirms which of these survive when everything is controlled simultaneously.

---

## 3. The findings

Ordered by how much they should change management's decisions. Each reports **attrition rate** (how bad a group is) alongside **share of all leavers** (how much of the problem it represents). A group can have an alarming rate and still be operationally irrelevant if it is small.

### 3.1 The problem is vertical, not horizontal

**Department tells you nothing:**

| Business function | Headcount | Attrition | Share of leavers |
|---|---|---|---|
| Education | 15,658 | 48.8% | 21.6% |
| Healthcare | 17,074 | 47.5% | 22.9% |
| Technology | 19,322 | 47.1% | 25.7% |
| Finance | 10,448 | 46.9% | 13.9% |
| Media | 11,996 | 46.8% | 15.9% |

**Job level tells you everything:**

| Job level | Headcount | Attrition | Share of leavers |
|---|---|---|---|
| **Entry** | 29,780 | **63.3%** | **53.3%** |
| Mid | 29,678 | 45.4% | 38.1% |
| Senior | 15,040 | 20.3% | 8.6% |

> A two-point spread across five functions is no difference at all. A 43-point spread across three grades, in the same organisation, in every function, is the structure of the problem. Entry-level employees are 40% of the workforce and 53.3% of everyone who left.
>
> **The negative finding is worth as much as the positive one:** an investigation organised by department will consume management time and find nothing.

### 3.2 Marital status separates the workforce more sharply than any other demographic

| Marital status | Headcount | Attrition | Share of leavers |
|---|---|---|---|
| **Single** | 26,001 | **66.8%** | **49.1%** |
| Divorced | 11,078 | 40.8% | 12.8% |
| Married | 37,419 | 36.0% | 38.1% |

**Tested against the obvious objection — is this just age?** No:

| Marital status | 18–25 | 26–35 | 36–45 | 46–55 | 56–59 |
|---|---|---|---|---|---|
| Single | 72.0% | 66.9% | 65.1% | 65.3% | 64.2% |
| Divorced | 48.4% | 41.8% | 36.7% | 39.0% | 38.3% |
| Married | 41.7% | 36.5% | 33.8% | 34.7% | 32.6% |

> The gap is stable across the entire age range, so it is not young employees being mislabelled. Marital status is almost certainly a **marker for mobility and life-stage commitments rather than a cause**. It is not something HR can or should address directly — its value is as a targeting variable, which is exactly how Section 4 uses it.

### 3.3 Working arrangement is the largest modifiable factor

| Arrangement | Headcount | Attrition | Share of leavers |
|---|---|---|---|
| **On-site** | 60,300 | **52.8%** | **90.1%** |
| Remote | 14,198 | 24.7% | 9.9% |

**Holds within every job level, so it is not a composition effect:**

| Job level | On-site | Remote | Gap |
|---|---|---|---|
| Entry | 69.3% | 37.1% | 32.2 pp |
| Mid | 51.0% | 22.3% | 28.7 pp |
| Senior | 23.8% | 5.2% | 18.6 pp |

> **Do not over-read this.** Direction of causation is not established and cannot be from this data. Remote status may be *granted* to employees already regarded as committed or already likely to stay — in which case remote work marks retention rather than producing it.
>
> This is why the recommendation is a randomised pilot with a comparison group, not a rollout. A pilot is what converts an association into evidence, and it is cheaper than a rollout that turns out to have read the relationship backwards.

### 3.4 Career progression is a threshold, not a gradient

| Promotions | Headcount | Attrition | Change vs previous |
|---|---|---|---|
| 0 | 37,145 | 49.3% | — |
| 1 | 18,681 | 49.0% | −0.3 pp |
| 2 | 13,634 | 49.0% | 0.0 pp |
| **3** | 4,049 | **24.9%** | **−24.1 pp** |
| 4 | 989 | 23.3% | −1.6 pp |

> The most operationally useful shape in the dataset. Nothing changes between zero, one and two promotions; the rate then halves at the third. A policy of "promote people more often" would achieve **nothing at all** until it crossed that threshold.
>
> What separates the two groups is unlikely to be the promotion count itself but whatever the third promotion *represents* — most plausibly a genuine change in role, responsibility and standing rather than an incremental step. That hypothesis is testable against the HR system and should be tested before any progression policy is redesigned. Only 6.8% of the workforce has reached three or more.

### 3.5 Work-life balance is the strongest factor HR actually controls

| Work-life balance | Headcount | Attrition | Share of leavers |
|---|---|---|---|
| Poor | 10,379 | 60.2% | 17.7% |
| Fair | 22,529 | 57.6% | 36.7% |
| Good | 28,158 | 40.4% | 32.1% |
| Excellent | 13,432 | 35.7% | 13.5% |

> A clean monotonic gradient — the most credible engagement measure in the file, and the only strong factor that is a lever rather than a fact about the workforce.
>
> **The threshold sits between "Fair" and "Good", not at the bottom of the scale.** Adjusted odds ratios are 4.43 for Poor and 3.65 for Fair against Excellent. A management scorecard that flags only "Poor" misses the larger half of the affected population: **44.2% of the workforce reports Poor or Fair.**

**Overtime interacts with it but is not the same thing:**

| Overtime | Excellent | Good | Fair | Poor |
|---|---|---|---|---|
| No | 34.0% | 38.5% | 55.9% | 57.7% |
| Yes | 39.2% | 44.3% | 61.0% | 65.2% |

> Overtime adds roughly 5–8 points within every balance category, so it carries independent signal (adjusted OR 1.42), but the balance gradient is around three times larger. Overtime appears to be **one input into perceived balance rather than a separate driver** — review it in the same exercise, not as a separate initiative.

### 3.6 Tenure matters less than expected

| Tenure band | Headcount | Attrition | Share of leavers |
|---|---|---|---|
| 0–2 years | 6,095 | 52.9% | 9.1% |
| 3–5 years | 8,948 | 53.1% | 13.4% |
| 6–10 years | 14,852 | 51.6% | 21.7% |
| 11–20 years | 22,339 | 44.7% | 28.2% |
| 20+ years | 22,264 | 43.7% | 27.5% |

**Within each job level, tenure barely moves the rate:**

| Job level | 0–2 | 3–5 | 6–10 | 11–20 | 20+ |
|---|---|---|---|---|---|
| Entry | 67.3% | 68.9% | 67.7% | 61.0% | 59.2% |
| Mid | 52.3% | 51.2% | 49.7% | 41.9% | 41.9% |
| Senior | 25.6% | 26.1% | 23.2% | 17.9% | 16.8% |

> The common assumption that high attrition means an onboarding problem is only **weakly supported**. Short-service employees do leave at a higher rate, but they account for 9.1% of all departures — an onboarding programme alone would address under a tenth of the problem.
>
> Within-level spread is 6–9 points against a 38–43 point spread *between* levels. What looks like a tenure effect in the raw data is largely a grade effect. Note also that **long tenure at entry level is itself a warning sign**: 59.2% attrition among 20+ year entry-level staff.

### 3.7 The gender gap is real and unexplained

| Job level | Female share of level | Female attrition | Male attrition | Gap |
|---|---|---|---|---|
| Entry | 45.3% | 68.7% | 58.8% | 9.9 pp |
| Mid | 45.4% | 51.2% | 40.6% | 10.6 pp |
| Senior | 44.7% | 25.3% | 16.2% | 9.1 pp |
| **All** | 45.2% | **53.0%** | **42.9%** | **10.1 pp** |

> The standard explanation for a gender gap in attrition is that women are concentrated in more junior roles where attrition is higher. **That explanation fails here.** The female share of headcount is essentially identical across all three grades, and women leave more within each one.
>
> The gap also survives the full regression (adjusted OR 0.55 for men), which controls simultaneously for grade, pay, function, tenure, working arrangement, overtime, marital status and every engagement measure.
>
> **Nothing in this dataset explains it.** That is a finding about the limits of the data as much as about the workforce. The honest output is a structured qualitative investigation — exit-interview review and a listening exercise — not a hypothesis about why women leave, which this data cannot support and which would be speculation presented as analysis.

### 3.8 Secondary patterns

**Company reputation — a plausible leading indicator, and cheap to monitor:**

| Reputation | Headcount | Attrition |
|---|---|---|
| Poor | 15,116 | 56.0% |
| Fair | 14,786 | 51.8% |
| Excellent | 7,414 | 44.0% |
| Good | 37,182 | 43.0% |

**Performance rating — some of this attrition may be desirable:**

| Rating | Headcount | Attrition |
|---|---|---|
| Low | 3,730 | 57.1% |
| Below Average | 11,139 | 51.6% |
| High | 14,910 | 46.2% |
| Average | 44,719 | 46.1% |

> Low performers leave at 57.1%. Not every departure is a retention failure, and progression policy should not be designed to retain employees the organisation is not seeking to retain. The dataset does not distinguish voluntary from involuntary exits, so the true retention problem is smaller than the headline figure suggests.

**Education — only the doctorate separates:**

| Education | Headcount | Attrition |
|---|---|---|
| Bachelor's Degree | 22,331 | 48.9% |
| Master's Degree | 15,021 | 48.8% |
| Associate Degree | 18,649 | 48.7% |
| High School | 14,680 | 48.4% |
| **PhD** | 3,817 | **24.4%** |

> Four of the five qualifications are statistically indistinguishable. PhD holders (adjusted OR 0.21) sit on a small base and are likely concentrated in particular roles.

**Commute distance — a steady gradient, on a suspect field:**

| Distance band | Headcount | Attrition |
|---|---|---|
| 1–20 | 14,645 | 41.7% |
| 21–40 | 14,688 | 42.2% |
| 41–60 | 14,716 | 48.3% |
| 61–80 | 14,719 | 52.7% |
| 81–99 | 13,833 | 53.0% |

> One of the few numeric fields with a clear pattern (adjusted OR 1.010 per unit — compounded, a 50-unit commute carries 1.63× the odds of a 1-unit commute). But the distribution is near-perfectly uniform across 1–99 and the unit is undefined, which is consistent with generated rather than observed values. Reported, but carries little weight.

**Age — weak, and mostly running through grade:**

| Age band | Headcount | Attrition |
|---|---|---|
| 18–25 | 14,018 | 53.1% |
| 26–35 | 17,800 | 47.9% |
| 36–45 | 17,960 | 45.1% |
| 46–55 | 17,641 | 46.2% |
| 56–59 | 7,079 | 44.5% |

---

## 4. Risk segmentation

The three strongest independent factors combined. This is the table management acts on.

| Rank | Job level | Arrangement | Marital status | Headcount | Attrition | Share of leavers | Priority |
|---|---|---|---|---|---|---|---|
| 1 | Entry | On-site | Single | 8,507 | **87.5%** | **21.0%** | CRITICAL |
| 2 | Mid | On-site | Single | 8,323 | **72.2%** | **17.0%** | CRITICAL |
| 3 | Entry | On-site | Divorced | 3,557 | 64.1% | 6.4% | High |
| 4 | Entry | Remote | Single | 1,965 | 58.5% | 3.3% | High |
| 5 | Entry | On-site | Married | 12,118 | 58.1% | 19.9% | High |
| 6 | Mid | On-site | Divorced | 3,652 | 43.2% | 4.5% | Monitor |
| 7 | Senior | On-site | Single | 4,189 | 42.9% | 5.1% | Monitor |
| 8 | Mid | Remote | Single | 2,059 | 40.9% | 2.4% | Monitor |
| 9 | Mid | On-site | Married | 11,953 | 38.6% | 13.0% | Stable |
| 10 | Entry | Remote | Divorced | 821 | 27.9% | 0.6% | Stable |
| 11 | Entry | Remote | Married | 2,812 | 24.9% | 2.0% | Stable |
| 12 | Mid | Remote | Divorced | 863 | 16.5% | 0.4% | Stable |
| 13 | Senior | On-site | Divorced | 1,775 | 15.8% | 0.8% | Stable |
| 14 | Senior | On-site | Married | 6,226 | 13.2% | 2.3% | Stable |
| 15 | Senior | Remote | Single | 958 | 12.8% | 0.3% | Stable |
| 16 | Mid | Remote | Married | 2,828 | 10.6% | 0.8% | Stable |
| 17 | Senior | Remote | Divorced | 410 | 2.9% | 0.0% | Stable |
| 18 | Senior | Remote | Married | 1,482 | **0.8%** | 0.0% | Stable |

### Concentration

> **The three highest-risk segments hold 27.4% of the workforce and account for 44.5% of all recorded departures.**
>
> The lowest-risk segment — senior, remote, married — loses effectively nobody (0.8% on 1,482 people).

This spread is the entire case for a targeted programme. Concentrated attrition is an operational problem with a costable solution; diffuse attrition would require changing the employment proposition itself, at a different order of cost. **The evidence supports the cheaper diagnosis.**

---

## 5. Adjusted effects — what survives simultaneous control

Sections 3 and 4 report differences one or three variables at a time. In a real workforce these variables move together — junior staff are more often single, less often remote, less often promoted — so a raw difference can be produced entirely by a third variable. A logistic regression entering all factors simultaneously separates them.

**Model:** n = 72,601 complete records · pseudo-R² = 0.289

| Factor (vs reference) | Adjusted OR | p | Interpretation |
|---|---|---|---|
| Single (vs divorced) | **4.68** | <0.001 | Largest single association in the model |
| Work-life balance: Poor (vs Excellent) | **4.43** | <0.001 | Strongest **modifiable** factor |
| Work-life balance: Fair (vs Excellent) | **3.65** | <0.001 | "Fair" is far closer to "Poor" than to "Good" |
| Company reputation: Poor (vs Excellent) | 2.09 | <0.001 | Plausible leading indicator |
| Performance: Low (vs Average) | 1.80 | <0.001 | Some of this attrition may be desirable |
| Job satisfaction: Low (vs High) | 1.66 | <0.001 | See next row before using this field |
| Job satisfaction: **Very High** (vs High) | 1.65 | <0.001 | **Also** raises the odds — field is unreliable |
| Company reputation: Fair | 1.61 | <0.001 | |
| Overtime: Yes | 1.42 | <0.001 | Independent of reported work-life balance |
| Performance: Below Average | 1.41 | <0.001 | |
| Company size: Small | 1.22 | <0.001 | Marginal |
| Distance from home (per unit) | 1.010 | <0.001 | 1.63× odds at 50 units vs 1 |
| Monthly income (per 1,000) | **1.00** | **0.79** | **No detectable relationship** |
| Years at company (per year) | 0.986 | <0.001 | Weak once grade is controlled |
| Age (per year) | 0.994 | <0.001 | Weak once grade is controlled |
| Promoted at least once | 0.81 | <0.001 | Larger effect appears at the 3rd promotion |
| Leadership opportunities: Yes | 0.83 | <0.001 | Small base (4.9% of staff) |
| Department / Function (all) | 0.88–0.91 | <0.01 | Negligible, confirming §3.1 |
| Male (vs female) | **0.55** | <0.001 | Unexplained by any control |
| Education: PhD (vs Associate) | 0.21 | <0.001 | Small base |
| Remote work: Yes | **0.17** | <0.001 | On-site carries ~6× the odds |
| Job level: Senior (vs Entry) | **0.08** | <0.001 | 93% reduction — dominant structural factor |
| Job level: Mid (vs Entry) | 0.37 | <0.001 | Steep, consistent grade gradient |
| Employee recognition (all levels) | 0.94–1.03 | >0.13 | **Not significant** |
| Education: HS / Bachelor's / Master's | 1.01–1.02 | >0.36 | **Not significant** |

**Reference groups:** Female · Education function · Excellent work-life balance · High job satisfaction · Average performance · No overtime · Associate degree · Divorced · Entry level · Large company · On-site · No leadership opportunities · No innovation opportunities · Excellent reputation · High recognition · Never promoted.

### What the model changes

- The **work-life balance threshold** sits between Fair and Good, not at the bottom of the scale.
- **Overtime** carries an independent 42% increase even after balance is controlled — it is not merely acting through perceived balance.
- The **gender gap survives** every control.
- **Age and tenure become weak** once grade is controlled. What looked like a tenure effect is largely a grade effect.
- **Department remains negligible**, confirming §3.1.

### What the model cannot do

- **It cannot establish causation.** These are associations at a single point in time.
- **It cannot explain most individual departures.** Pseudo-R² of 0.289 means a substantial but partial share of variation. Manager quality, team dynamics, external offers and personal circumstances are absent from this file and are likely to matter more than several factors that are present.
- **It inherits every integrity problem in Section 1.** The *ranking* of factors is more trustworthy than the *magnitude* of any single one.
- **Statistical vs practical significance:** at 72,601 records, trivial differences reach significance. Effect size, not p-value, decides what matters operationally.

---

## 6. Confounding tests

Each headline difference was tested against a plausible alternative explanation before being reported as a finding. All five survived.

| # | Test | Verdict |
|---|---|---|
| 1 | Is the gender gap a grade effect? | **No.** Female share is 45.3 / 45.4 / 44.7% across Entry / Mid / Senior, and women leave more at all three |
| 2 | Is the remote-work effect a grade effect? | **No.** Remote workers leave less within every level; the gap widens with seniority |
| 3 | Is marital status an age proxy? | **No.** Single 64–72% and married 33–42% in every age band |
| 4 | Does tenure matter once job level is held constant? | **Only weakly.** Within-level spread 6–9 pp vs 38–43 pp between levels |
| 5 | Does overtime act independently of work-life balance? | **Partly.** Adds 5–8 pp within every balance category, but the balance gradient is ~3× larger |

---

## 7. Negative findings

Findings that should **stop** work rather than start it. These are worth as much as the positive ones, because each prevents a costly investigation the data does not support.

| Factor | Evidence | Conclusion |
|---|---|---|
| **Department / Function** | 2.0 pp spread across five functions; OR 0.88–0.91 | There is no departmental attrition problem |
| **Employee Recognition** | 1.8 pp spread; not significant in the adjusted model | No meaningful relationship |
| **Company Size** | 3.2 pp spread; OR 1.00 for Medium | Marginal at best |
| **Leadership / Innovation Opportunities** | 2.8 and 3.0 pp on small bases | Weak evidence |
| **Monthly Income** | 4.1 pp across a 3× pay range; **p = 0.79**; leavers 7,317 vs stayers 7,370 | See below |

### The pay finding needs care

This must **not** be reported to management as "pay does not affect retention."

Section 1 established that median pay is identical at entry, mid and senior level, which no real pay structure produces. A field that does not vary with seniority cannot be expected to correlate with anything.

> **The defensible conclusion is that the pay data is unusable for this purpose — not that compensation is irrelevant to retention.** The question remains open.

Reporting the first version of that sentence instead of the second would be the most consequential analytical error available in this project.

---

## 8. Recommendations

| # | Recommendation | Rests on | Owner |
|---|---|---|---|
| 1 | **Run a controlled remote/hybrid pilot** for the entry-level on-site cohort (24,182 employees), with a randomised comparison group | 28-point rate gap holding within every grade | HR Director + function heads |
| 2 | **Make work-life balance a monitored management KPI**, treating "Fair" as a warning rather than an acceptable score | 24.5-point gradient; OR 4.43 / 3.65; affects 44.2% of the workforce | HR + line management |
| 3 | **Establish what the third promotion represents** before redesigning progression policy | Attrition halves at the 3rd promotion; flat before it | HR + Reward |
| 4 | **Commission a qualitative investigation** into the gender gap | 10-point gap unexplained by any available variable | HR Director |
| 5 | **Remediate the HR data** — tenure fields, pay field, satisfaction instrument, export encoding | 32.1% of records internally impossible; pay carries no grade signal | HR data owner |

### Sequencing

| Timing | Actions | Why |
|---|---|---|
| Immediate (0–1 month) | Rec 5 (data remediation); scope Rec 1's pilot population | Prerequisites — one governs confidence in all future measurement, the other must be scoped before randomising |
| Short term (1–3 months) | Launch Rec 1 pilot; implement Rec 2 scorecard | The two largest modifiable factors; the scorecard also provides the measurement to evaluate the pilot |
| Medium term (3–6 months) | Rec 3 progression review; Rec 4 qualitative investigation | Both need diagnostic work before policy change; neither is blocked by the earlier actions |
| Ongoing | Re-run the KPI baseline quarterly | The baseline exists so effects can be measured rather than assumed |

---

## 9. Limitations

### Of the data
- 47.5% attrition indicates a class-balanced extract. Absolute rates are not organisational facts.
- Age and tenure mutually impossible in 32.1% of records; tenure fields contradictory in 84.3%.
- The pay field carries no seniority signal and is treated as unusable.
- Job Satisfaction is non-monotonic and excluded from recommendations.
- Distance from Home is near-uniform with an undefined unit — consistent with generated values.
- **No time dimension.** No hire dates, no leaving dates, no reporting period. Attrition cannot be trended, seasonality cannot be examined, and no before-and-after comparison is possible.

### Of the analysis
- Every relationship is an association from a single cross-sectional snapshot. Nothing here establishes causation.
- Pseudo-R² 0.289 — manager quality, team dynamics, market conditions and personal circumstances are absent and likely matter more than several factors that are present.
- **Voluntary and involuntary departures are not distinguished.** Some attrition (particularly among the 57.1% of low performers who left) may be intended. The true retention problem is smaller than the headline suggests.
- At 74,498 records, differences of no operational consequence reach statistical significance.
- Smaller segments in Section 4 hold a few hundred employees; their rates are correspondingly less stable.

### What would materially improve the next analysis
1. **Hire and leave dates** — enabling time-to-attrition and survival analysis rather than a snapshot.
2. **A voluntary/involuntary flag** — separating the retention problem from intended exits.
3. **Exit interview data** — the only realistic route to explaining the gender gap.
4. **Manager or team identifiers** — manager quality is widely the strongest single predictor of departure and is entirely absent here.
5. **A verified pay field** — which would reopen the compensation question.

---

## 10. Management conclusion

**What is happening.** Departures are concentrated, not diffuse. They sit in the grade structure rather than in any department: entry-level employees are 40% of the workforce and 53.3% of everyone who left, while the spread across all five business functions is two points. Within that structure, three conditions separate people sharply — seniority, working arrangement and work-life balance — and one demographic marker, marital status, identifies risk without explaining it.

**Why it matters.** Concentration is good news operationally. The three highest-risk segments hold 27.4% of the workforce and produce 44.5% of departures, so a targeted programme can reach almost half the problem while addressing just over a quarter of the organisation. Diffuse attrition would have required changing the employment proposition itself, at a different order of cost.

**What the evidence supports.**

- **Strongly:** job level, working arrangement, work-life balance and progression beyond the second promotion are where management time belongs — all four survive simultaneous control.
- **Strongly:** department, employee recognition, company size and education below doctoral level are not. These should stop work, not start it.
- **With caution:** the gender gap is real and unexplained. It warrants investigation, not a policy response built on an assumed cause.
- **Not at all:** that pay is unrelated to retention. The pay field is unusable and the question remains open.
- **Never:** any causal claim.

**The one-sentence version.** Attrition is concentrated in entry-level, on-site employees rather than in any department; the two things management can actually change are working arrangement and work-life balance; and the pay and tenure data need fixing before anyone asks this question again.

---

*See [`README.md`](../README.md) for repository contents and method. Full workings in [`excel/HR_Attrition_Analysis.xlsx`](../excel/HR_Attrition_Analysis.xlsx); reproducible logic in [`sql/hr_attrition_analysis.sql`](../sql/hr_attrition_analysis.sql).*
