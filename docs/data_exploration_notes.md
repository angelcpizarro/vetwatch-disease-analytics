# Data Source Exploration Notes

## Table of Contents
 
1. [Overview](#overview)
2. [Data Representation](#data-representation)
3. [Row Grain](#row-grain)
4. [Column Reference](#column-reference)
5. [Year Range Analysis](#year-range-analysis)
6. [Data Quality Observations](#data-quality-observations)
7. [Decisions Made as a Result of Exploration](#decisions-made-as-a-result-of-exploration)


## Overview

This document records the initial exploration of the WAHIS (World Animal Health Information System) data source used in this project. It covers the structure of the CSV export, known data quality issues, and decisions made as a result of exploration.

For a summary of the data source, see the [README](../README.md).

---

## Data Representation

The WAHIS quantitative export combines records from two underlying report types, identifiable via the `Outbreak_id` column:

- **Six-monthly reports (SMR):** `Outbreak_id` is blank (`-`). These are aggregated summaries submitted by member countries every six months.
- **Immediate notifications and follow-up reports (IN/FUR):** `Outbreak_id` is populated. These are event-level records submitted in real-time when a notifiable disease event occurs.

When the same outbreak appears in both SMR and IN/FUR, WAHIS only retains the SMR record in the export to avoid duplication.

**`New outbreaks` count behaviour:**
- **IN/FUR:** Only one species row per outbreak carries the count — the remaining rows show `0`
- **SMR:** The count appears on the summary row — detail-level rows show `-`

---

## Row Grain

**One row = one species, within one outbreak event, within one administrative division, within one semester.**

*A single H5N1 outbreak in Austria affecting three bird species across two regions will therefore appear as multiple rows.*

For IN/FUR records, only one species row per outbreak carries the New outbreaks count — the remaining rows show 0 to avoid double counting.

---

## Column Reference

| Column | Description | Notes |
|--------|-------------|-------|
| `Year` | Reporting year | Integer |
| `Semester` | Six-month period (e.g. Jan-Jun 2023) | No exact dates available |
| `World region` | WOAH world region | e.g. Europe, Americas, Asia |
| `Country` | Reporting country | Full country names — not ISO codes |
| `Administrative Division` | Sub-national area | Ranges from province to district level depending on country |
| `Disease` | Full WAHIS disease name | Long, complex strings — will need standardising |
| `Serotype/Subtype/Genotype` | Strain detail where applicable | Often blank |
| `Animal Category` | Domestic or Wild | Useful dimension for outbreak analysis |
| `Species` | Animal affected | e.g. Cattle, Wild boar, Mute Swan |
| `Event_id` | Links rows to a parent event | Blank for SMR records |
| `Outbreak_id` | Links rows to a specific outbreak | Blank for SMR records |
| `New outbreaks` | Number of new outbreaks starting in this semester | Refer to [Data Representation](#data-representation) |
| `Susceptible` | Population at risk | Numeric — often blank |
| `Measuring units` | Unit for quantitative fields | Animal or Hives (for bee diseases) |
| `Cases` | Confirmed cases | `-` means missing, not zero |
| `Deaths` | Deaths from disease | `-` means missing, not zero |
| `Killed and disposed of` | Animals culled for disease control | `-` means missing, not zero |
| `Slaughtered` | Animals slaughtered (non-disease control) | `-` means missing, not zero |
| `Vaccinated` | Animals vaccinated | `-` means missing, not zero |

---

## Year Range Analysis

To determine the appropriate year range for the project, row counts per year were analysed using a pivot table on a spreadsheet across the full available dataset (2005–2025).

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

- Row counts are remarkably consistent across the full period, ranging between ~25,000 and ~36,000 rows per year.
- The dip in 2020 (27,787 rows) is consistent with COVID-19 disrupting global veterinary surveillance and reporting. 
- 2025 shows a lower row count (25,144) probably because the Jul-Dec 2025 semester has not yet been fully submitted by member countries given possible reporting lags. 2025 is therefore excluded from the project scope.

**Decision:** Year range set to **2005–2024**, giving a clean 20-year window of complete data.

---

## Data Quality Observations

### 1. `-` used for missing values, not null

Throughout the quantitative fields (`Cases`, `Deaths`, `Killed and disposed of`, `Slaughtered`, `Vaccinated`, `Susceptible`), missing data is represented as a hyphen (`-`) rather than an empty cell or null. This is the most obvious quality issue in the dataset.

**Implication:** The cleaning script will replace `-` with `NULL` before loading to BigQuery.

### 2. Two-tier row structure in SMR records

SMR records follow a pattern of one summary row (where `Species` is blank and most quantitative fields are `-`) followed by one or more species-level detail rows with actual counts. For example:

```
Albania | Anthrax | Both animal categories | Species: - | New outbreaks: 1 | Cases: -
Albania | Anthrax | Domestic | Sheep/goats  | New outbreaks: - | Cases: 3
Albania | Anthrax | Domestic | Cattle        | New outbreaks: - | Cases: 5
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

**Implication:** A `disease_categories` seed file will be created in dbt to map raw disease names to clean short names and broader categories (e.g. Avian, Livestock, Wildlife). This will be helpful for any aggregation by disease.

### 5. `Event_id` and `Outbreak_id` are blank for SMR records

SMR-sourced rows do not carry event or outbreak IDs, meaning they cannot be traced to a specific notifiable event.

**Implication:** Any analysis requiring event-level traceability must use IN/FUR records only. This will be reflected in the data quality mart model as a completeness metric.

---

## Decisions Made as a Result of Exploration

| Decision | Rationale |
|----------|-----------|
| Year range set to 2005–2024 | Row counts are consistent across the full period with no quality deterioration in earlier years. 2025 excluded as the Jul-Dec semester is probably not yet fully reported. |
| 2020 dip flagged as an anomaly | Row count drops to 27,787 in 2020, consistent with COVID-19 disrupting global veterinary surveillance. To be annotated on the dashboard. |
| Replace `-` with NULL in cleaning script | Prevents silent corruption of quantitative analysis |
| Filter to detail rows only for quantitative models | Summary rows duplicate outbreak counts already present in the detail rows, which would double count new_outbreaks. |
| Build `disease_categories` seed file in dbt | Raw disease names are too long and inconsistent for direct use. |
| API integration deprioritised | Adds complexity without improving the analytical output for this project |