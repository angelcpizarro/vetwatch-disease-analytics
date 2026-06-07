# Data Source Exploration Notes

## Table of Contents
 
1. [Overview](#overview)
2. [Data Representation](#data-representation)
3. [Row Grain](#row-grain)
4. [Column Exploration](#column-exploration)
5. [Year Range Analysis](#year-range-analysis)
6. [Data Quality Observations](#data-quality-observations)
7. [Decisions Made as a Result of Exploration](#decisions-made-as-a-result-of-exploration)


## Overview

This document records the initial exploration of the WAHIS (World Animal Health Information System) dataset used in this project. It covers the structure of the CSV export, known data quality issues, and decisions made as a result of exploration.

---

## Data Representation

The WAHIS quantitative export combines records from two underlying report types, identifiable via the `Outbreak_id` column:

- **Six-monthly reports (SMR):** `Outbreak_id` is blank (`-`). These are aggregated summaries submitted by member countries every six months.
- **Immediate notifications and follow-up reports (IN/FUR):** `Outbreak_id` is populated. These are event-level records submitted in real-time when a notifiable disease event occurs.

To avoid duplication of outbreaks in IN/FUR, only one species in an outbreak contains the “new outbreak” count while the rest show “0”. This does not affect the summation of outbreaks nor the other quantitative data (Susceptible, Cases, etc.).

**`New outbreaks` count behaviour:**
- **IN/FUR:** Only one species row per outbreak carries the count `1` — the remaining rows show `0`
- **SMR:** The count appears on the summary row — detail-level rows show `-`. Summary rows contain `New outbreaks` for aggregation later in the analysis.

Both IN/FUR rows and detailed SMR rows contain the quantitative data (species level) for more in detail quantitative analysis.

---

## Column Exploration

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
- The dip in 2020 (27,787 rows) could be consistent with COVID-19 disrupting global veterinary surveillance and reporting. 
- 2025 shows a lower row count (25,144) probably because the Jul-Dec 2025 semester has not yet been fully submitted by member countries given possible reporting lags. 2025 is therefore excluded from the project scope.

**Decision:** Year range set to **2005–2024**, giving a clean 20-year window of complete data.

---

## Data Quality Observations

### 1. `-` used for missing values, not null

Throughout the quantitative fields (`Cases`, `Deaths`, `Killed and disposed of`, `Slaughtered`, `Vaccinated`, `Susceptible`), missing data is represented as a hyphen (`-`) rather than an empty cell or null. This is the most obvious quality issue in the dataset.

**Implication:** The ingestion script will replace `-` with `NULL` before loading to BigQuery.

### 2. Two-tier row structure in SMR records

SMR records follow a pattern of one summary row (where `Species` is blank) followed by one or more species-level detail rows with actual counts. For example:

```
Albania | Anthrax | Both animal categories | Species: - | New outbreaks: 1 | Cases: -
Albania | Anthrax | Domestic | Sheep/goats  | New outbreaks: - | Cases: 3
Albania | Anthrax | Domestic | Cattle        | New outbreaks: - | Cases: 5
```

**Implication:** The intermediate model should distinguish between summary rows and detail rows. For detailed quantitative analysis, only detail rows (where `Species` is populated) should be used. Summary rows are useful only for outbreak counts.

### 3. No exact dates — semester granularity only

The finest time resolution available is a six-month semester (e.g. `Jan-Jun 2023`). Exact outbreak start and end dates are not available in the CSV export.

**Implication:** Time analysis in this project will be at annual level.

### 4. Disease names are long and unstandardised

Disease names use the full WAHIS formal nomenclature, including taxonomic qualifiers and year suffixes. For example:

```
Influenza A viruses of high pathogenicity (Inf. with) (non-poultry including wild birds) (2017-)
```

**Implication:** A `disease_categories` seed file will be created in dbt to map raw disease names to clean short names and broader categories (e.g. Avian, Livestock, Wildlife). This will be helpful for any aggregation by disease and also for a clearer visualisation in a dashboard.

---

## Decisions Made as a Result of Exploration

| Decision | Rationale |
|----------|-----------|
| Year range set to 2005–2024 | Row counts are consistent across the full period with no quality deterioration in earlier years. 2025 excluded as the Jul-Dec semester is probably not yet fully reported. |
| Replace `-` with NULL in the ingestion script | Prepares the data before loading to BigQuery |
| Filter to detail rows only for detailed quantitative models | SMR summary rows only for outbreak counts and detailed rows for more detailed quantitative analysis. |
| Build `disease_categories` seed file in dbt | Raw disease names are too long and inconsistent for direct use. |
| API integration deprioritised | Adds complexity without improving the analytical output for this project |