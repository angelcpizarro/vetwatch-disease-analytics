# Problems and Solutions

## Table of Contents

1. [Overview](#overview)
2. [Ingestion Layer](#ingestion-layer)
   - [Problem 1 — BigQuery dataset didn't exist](#problem-1--bigquery-dataset-didnt-exist)
3. [Staging Layer](#staging-layer)
   - [Problem 2 — event_id and outbreak_id loaded as float](#problem-2--event_id-and-outbreak_id-loaded-as-float)
   - [Problem 3 — Non-breaking space in disease names](#problem-3--non-breaking-space-in-disease-names)
4. [Intermediate Layer](#intermediate-layer)
   - [Problem 4 — Duplicate countries in int_country_reporting_quality](#problem-4--duplicate-countries-in-int_country_reporting_quality)
   - [Problem 5 — Inconsistent outbreak counts between marts](#problem-5--inconsistent-outbreak-counts-between-marts)
   - [Problem 6 — Apiary diseases inflating outbreak counts](#problem-6--apiary-diseases-inflating-outbreak-counts)
   - [Problem 7 — Completeness flags including IN/FUR rows incorrectly](#problem-7--completeness-flags-including-infur-rows-incorrectly)

---

## Overview

This document records the technical problems found during the build of VetWatch, how each was diagnosed, and how it was resolved. It is intended as a reference for understanding the engineering decisions made throughout the project and as evidence of systematic problem-solving.

---

## Ingestion Layer

### Problem 1 — BigQuery dataset didn't exist

**What happened:** The load script failed with `Error 404: Not found: Dataset vetwatch-disease-analytics:wahis_raw`.

**Diagnosis:** The Python script assumed the dataset already existed in BigQuery. It doesn't create it automatically.

**Solution:** Manually created the `wahis_raw` dataset in the BigQuery console before running the script again.

**Lesson:** Infrastructure must be set up before code that depends on it is run.

---

## Staging Layer

### Problem 2 — `event_id` and `outbreak_id` loaded as float

**What happened:** When exploring column types in BigQuery, `event_id` and `outbreak_id` were float instead of integer.

**Diagnosis:** pandas loaded integer columns that contain NULL values as float64 by default.

**Solution:** Cast to integer in the staging model:
```sql
cast(event_id as integer) as event_id,
cast(outbreak_id as integer) as outbreak_id
```

**Lesson:** Always cast types explicitly in the staging layer.

---

### Problem 3 — Non-breaking space in disease names

**What happened:** After building `int_outbreaks_enriched`, an orphan check revealed one disease (`Mycoplasma gallisepticum`) wasn't joining to the seed file despite the names appearing visually identical.

**Diagnosis:** With AI assistance, converted both strings to hex using `TO_HEX(CAST(field AS BYTES))` and compared character by character. Found `c2a0` (non-breaking space, unicode `\u00a0`) in the raw data where the seed file had `20` (regular space). `TRIM()` did not remove it.

**Solution:** Applied `REPLACE()` in the staging model to convert `'\u00a0'` whitespace variant to standard form:
```sql
REPLACE(TRIM(disease), '\u00a0', ' ') as disease_name_raw
```

**Result:** Zero orphaned disease names after the fix.

**Lesson:** Visual inspection of data is not always enough. Always apply a quality test to check for orphaned data after applying a LEFT JOIN. I've learned that non-breaking spaces are a common source of silent join failures in data from web forms.

---

## Intermediate Layer

### Problem 4 — Duplicate countries in `int_country_reporting_quality`

**What happened:** The `unique` test on `country_name` in `int_country_reporting_quality` failed.

**Diagnosis:** 20 Middle Eastern and North African countries appeared under two different `world_region` values in different records — predominantly classified inconsistently between "Middle East" and "Africa" or "Asia". This caused one row per region per country instead of one row per country.

**Solution:** Resolved in two steps:

1. Initially applied `ROW_NUMBER()` in `mart_data_quality_summary` to pick the most common region per country.

2. Refactored to resolve the inconsistency upstream in `int_outbreaks_enriched` instead — ensuring all downstream models use a consistent region classification without repeating the logic:

```sql
row_number() over (
    partition by country_name
    order by count(*) desc
) as rn
```

The resolved `world_region` is then joined into `int_country_reporting_quality` at the end of the model, after all country-level aggregations are complete, for its use in the analysis and dashboard.

**Lesson:** Data cleaning concerns should live as close to the source as possible. Fixing inconsistencies in the intermediate layer means all downstream marts automatically benefit without repeating logic.

---

### Problem 5 — Inconsistent outbreak counts between marts

**What happened:** `mart_disease_trends` and `mart_data_quality_summary` returned different `total_outbreaks` values for the same countries.

**Diagnosis:** The two marts were summing `new_outbreaks` from different row types. `mart_disease_trends` filtered to `is_detail_row = true` (missing SMR summary rows where the count lives), while `mart_data_quality_summary` included all rows (double counting).

**Solution:** Added `is_outbreak_count_row` flag in `int_outbreaks_enriched` to correctly identify rows carrying valid outbreak counts regardless of source type:
```sql
case
    when o.new_outbreaks is not null
     and o.new_outbreaks > 0
     and o.outbreak_id is null    -- SMR only
    then true
    else false
end as is_outbreak_count_row
```

Applied consistently across both marts. Verified consistency with cross-mart COUNT queries.

**Lesson:** When the same metric is used across multiple models, define it once in the intermediate layer as a flag rather than repeating the logic in each mart.

---

### Problem 6 — Apiary diseases inflating outbreak counts

**What happened:** After implementing `is_outbreak_count_row`, total outbreaks jumped to 5,889,113 — a significant increase from the previous number of 7,150. The Apiary category dominated the time series chart with a peak of approximately 1 million in 2011.

**Diagnosis:** Apiary diseases show abnormally large `new_outbreaks` values — American foulbrood alone reported 918,254 globally in 2011, which is clinically unrealistic as a distinct outbreak count. Detail rows for Apiary diseases use `Hives` as the measuring unit rather than `Animals`, suggesting the quantitative fields record hive counts rather than individual outbreak events. This makes Apiary figures incomparable with animal disease outbreak counts.

**Note:** *The interpretation of `new_outbreaks` for Apiary diseases is explained from the measuring unit and the abnormally large values. The WAHIS documentation does not explicitly clarify this distinction for bee diseases.*

**Solution:** Excluded Apiary from all quantitative analysis by filtering at the intermediate layer:
```sql
select * from enriched_with_flags
where disease_category != 'Apiary'
```

**Documented in dashboard:** A note explains the exclusion to dashboard viewers.

**Lesson:** Always check measuring units when aggregating across disease types.

---

### Problem 7 — Completeness flags including IN/FUR rows incorrectly

**What happened:** During model review, it was noted that `has_case_count` and other completeness flags were being calculated across all rows including IN/FUR, but the WAHIS documentation states deduplication is handled at source and quantitative data from both SMR and IN/FUR detail rows is valid and can be summed.

**Diagnosis:** Re-reading the WAHIS documentation clarified the correct approach:
- `new_outbreaks` → SMR summary rows only (via `is_outbreak_count_row`)
- Quantitative data (cases, deaths, vaccinated) → ALL detail rows from both SMR and IN/FUR

**Solution:** Updated completeness flags to use `is_detail_row = true` only (not restricting to SMR):
```sql
case
    when case_count is not null
     and is_detail_row = true
    then true else false
end as has_case_count
```

**Lesson:** Always read the source documentation carefully before, during, and after the project.