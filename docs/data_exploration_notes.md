# Data Source Exploration Notes

## Table of Contents
 
1. [Overview](#overview)
2. [What the Data Represents](#what-the-data-represents)
3. [Row Grain](#row-grain)
4. [Column Reference](#column-reference)
5. [Year Range Analysis](#year-range-analysis)
6. [Data Quality Observations](#data-quality-observations)
   - [1. `-` Used for Missing Values, Not Null](#1---used-for-missing-values-not-null)
   - [2. Two-Tier Row Structure in SMR Records](#2-two-tier-row-structure-in-smr-records)
   - [3. No Exact Dates — Semester Granularity Only](#3-no-exact-dates--semester-granularity-only)
   - [4. Disease Names Are Long and Unstandardised](#4-disease-names-are-long-and-unstandardised)
   - [5. `Event_id` and `Outbreak_id` Are Blank for SMR Records](#5-event_id-and-outbreak_id-are-blank-for-smr-records)
7. [Decisions Made as a Result of Exploration](#decisions-made-as-a-result-of-exploration)


## Overview

This document records the initial exploration of the WAHIS (World Animal Health Information System) data source used in this project. It covers the structure of the CSV export, known data quality issues, and decisions made as a result of exploration. It is intended as a reference for anyone working with this data and as evidence of data governance thinking throughout the project.

For a high-level summary of the data source, see the [README](../README.md).

---

## What the Data Represents

The WAHIS quantitative export combines records from two underlying report types, identifiable via the `Outbreak_id` column:

- **Six-monthly reports (SMR):** `Outbreak_id` is blank (`-`). These are aggregated summaries submitted by member countries every six months.
- **Immediate notifications and follow-up reports (IN/FUR):** `Outbreak_id` is populated. These are event-level records submitted in real-time when a notifiable disease event occurs.

When the same outbreak appears in both SMR and IN/FUR, **only the SMR record is used** by WAHIS to avoid duplication. This deduplication logic is handled at source and does not need to be replicated in the pipeline, but it is important to understand when interpreting outbreak counts.

---

## Row Grain

**One row = one species, within one outbreak event, within one administrative division, within one semester.**

A single H5N1 outbreak in Austria affecting three bird species across two regions will therefore appear as multiple rows.

To avoid double-counting outbreaks in IN/FUR records: only one species row per outbreak carries the `New outbreaks` count — the remaining species rows show `0`. This is by design and does not affect the summation of quantitative fields (cases, deaths, etc.).

---

## Column Reference

| Column | Description | Notes |
|--------|-------------|-------|
| `Year` | Reporting year | Integer |
| `Semester` | Six-month period (e.g. Jan-Jun 2023) | No exact dates available |
| `World region` | WOAH world region | e.g. Europe, Americas, Asia |
| `Country` | Reporting country | Full country names — not ISO codes |
| `Administrative Division` | Sub-national area | Ranges from province to district level depending on country |
| `Disease` | Full WAHIS disease name | Long, complex strings — will need standardising in staging |
| `Serotype/Subtype/Genotype` | Strain detail where applicable | e.g. H5N1 — often blank |
| `Animal Category` | Domestic or Wild | Useful dimension for outbreak analysis |
| `Event_id` | Links rows to a parent event | Blank for SMR records |
| `Outbreak_id` | Links rows to a specific outbreak | Blank for SMR records |
| `New outbreaks` | Number of new outbreaks starting in this semester | Only one species row per IN/FUR outbreak carries the count |
| `Susceptible` | Population at risk | Numeric — often blank |
| `Measuring units` | Unit for quantitative fields | Animal or Hives (for bee diseases) |
| `Cases` | Confirmed cases | `-` means missing, not zero |
| `Deaths` | Deaths from disease | `-` means missing, not zero |
| `Killed and disposed of` | Animals culled for disease control | `-` means missing, not zero |
| `Slaughtered` | Animals slaughtered (non-disease control) | `-` means missing, not zero |
| `Vaccinated` | Animals vaccinated | `-` means missing, not zero |

---

## Year Range Analysis

To determine the appropriate year range for the project, row counts per year were analysed using a pivot table across the full available dataset (2005–2025).

| Year | Row count |
|------|-----------|
| 2005 | 24,554 |
| 2006 | 25,931 |
| 2007 | 28,350 |
| 2008 | 29,955 |
| 2009 | 29,597 |
| 2010 | 32,858 |
| 2011 | 34,110 |
| 2012 | 31,155 |
| 2013 | 32,547 |
| 2014 | 30,882 |
| 2015 | 32,870 |
| 2016 | 34,420 |
| 2017 | 35,727 |
| 2018 | 36,347 |
| 2019 | 33,451 |
| 2020 | 27,787 |
| 2021 | 30,827 |
| 2022 | 31,801 |
| 2023 | 32,068 |
| 2024 | 32,483 |
| 2025 | 25,144 |

**Key observations:**

- Row counts are remarkably consistent across the full period, ranging between ~25,000 and ~36,000 rows per year. There is no dramatic jump indicating a structural change in reporting coverage, meaning the full dataset is suitable for analysis from 2005 onwards.
- The dip in 2020 (27,787 rows) is consistent with COVID-19 disrupting global veterinary surveillance and reporting. 
- 2025 shows a lower row count (25,144) because the Jul-Dec 2025 semester has not probably yet been fully submitted by member countries given possible reporting lags. 2025 is therefore excluded from the project scope.

**Decision:** Year range set to **2005–2024**, giving a clean 20-year window of complete data.

---

## Data Quality Observations

The following issues were identified during initial exploration of the CSV sample. Each has implications for the cleaning script and dbt models.

### 1. `-` used for missing values, not null

Throughout the quantitative fields (`Cases`, `Deaths`, `Killed and disposed of`, `Slaughtered`, `Vaccinated`, `Susceptible`), missing data is represented as a hyphen (`-`) rather than an empty cell or null. This is the most obvious quality issue in the dataset.

**Implication:** The cleaning script will explicitly replace `-` with `NULL` before loading to BigQuery. Treating `-` as a string or zero would silently affect all quantitative analysis.

### 2. Two-tier row structure in SMR records

SMR records follow a pattern of one summary row (where `Species` is blank and most quantitative fields are `-`) followed by one or more species-level detail rows with actual counts. For example:

```
Albania | Anthrax | Both animal categories | New outbreaks: 1 | Cases: -
Albania | Anthrax | Domestic | Sheep/goats  | Cases: 3
Albania | Anthrax | Domestic | Cattle        | Cases: 5
```

**Implication:** The staging model should distinguish between summary rows and detail rows. For quantitative analysis, only detail rows (where `Species` is populated) should be used. Summary rows are useful only for outbreak counts.

### 3. No exact dates — semester granularity only

The finest time resolution available is a six-month semester (e.g. `Jan-Jun 2023`). Exact outbreak start and end dates are not available in the CSV export.

**Implication:** Time-series analysis in this project is at semester or annual granularity.

### 4. Disease names are long and unstandardised

Disease names use the full WAHIS formal nomenclature, including taxonomic qualifiers and year suffixes. For example:

```
Influenza A viruses of high pathogenicity (Inf. with) (non-poultry including wild birds) (2017-)
```

The same disease may appear under slightly different names across years if WAHIS updated its nomenclature.

**Implication:** A `disease_categories` seed file will be created in dbt to map raw disease names to clean short names and broader categories (Avian, Livestock, Zoonotic, Wildlife). This is essential for any aggregation by disease type.

### 5. `Event_id` and `Outbreak_id` are blank for SMR records

SMR-sourced rows do not carry event or outbreak IDs, meaning they cannot be traced to a specific notifiable event.

**Implication:** Any analysis requiring event-level traceability must use IN/FUR records only. This is surfaced in the data quality mart model as a completeness metric.

---

## Decisions Made as a Result of Exploration

| Decision | Rationale |
|----------|-----------|
| Year range set to 2005–2024 | Row counts are consistent across the full period with no quality deterioration in earlier years. 2025 excluded as the Jul-Dec semester is not yet fully reported. Full 20-year window maximises analytical value. |
| 2020 dip flagged as a known anomaly | Row count drops to 27,787 in 2020, consistent with COVID-19 disrupting global veterinary surveillance. To be annotated on the dashboard. |
| Replace `-` with NULL in cleaning script | Prevents silent corruption of quantitative analysis |
| Filter to detail rows only for quantitative models | Summary rows would double-count cases and deaths |
| Build `disease_categories` seed file in dbt | Raw disease names are too long and inconsistent for direct use |
| Time-series granularity set to semester/annual | Exact dates not available in the CSV export |
| API integration deprioritised | Adds complexity without improving the analytical output for this project |

---

*This document will be updated as exploration continues and new data quality issues are discovered.*