# Naming Conventions

This document outlines the naming conventions used across the WAHIS Animal Disease Analytics project, covering BigQuery objects, dbt models, Python scripts, columns, and Git branches.

## Table of Contents

1. [General Principles](#general-principles)
2. [BigQuery Dataset Naming](#bigquery-dataset-naming)
3. [dbt Model Naming](#dbt-model-naming)
   - [Staging Layer](#staging-layer)
   - [Intermediate Layer](#intermediate-layer)
   - [Mart Layer](#mart-layer)
4. [dbt Seeds](#dbt-seeds)
5. [dbt Tests](#dbt-tests)
6. [dbt Sources](#dbt-sources)
7. [Column Naming Conventions](#column-naming-conventions)
   - [General Column Rules](#general-column-rules)
   - [Keys and IDs](#keys-and-ids)
   - [Date and Time Columns](#date-and-time-columns)
   - [Boolean Columns](#boolean-columns)
   - [Metric Columns](#metric-columns)
8. [Python Script Naming](#python-script-naming)
9. [Git Branch Naming](#git-branch-naming)
10. [Commit Message Conventions](#commit-message-conventions)

---

## General Principles

- **Naming style:** Use `snake_case` throughout — lowercase letters and underscores to separate words. No camelCase, no hyphens in object names.
- **Language:** English for all names.
- **Clarity over brevity:** Prefer descriptive names over abbreviations. `outbreak_case_count` is better than `ob_cnt`.
- **Avoid reserved words:** Do not use SQL or BigQuery reserved words as object or column names (e.g. `date`, `year`, `table`, `select`).
- **Consistency:** The same concept should always be named the same way across all layers. If it is `country_name` in staging, it is `country_name` in the mart.

---

## BigQuery Dataset Naming

BigQuery datasets represent layers in the pipeline. Each dataset maps to a stage in the transformation flow.

| Dataset | Purpose |
|---------|---------|
| `wahis_raw` | Raw data loaded directly from the CSV — no transformations |
| `wahis_dev` | dbt development environment output |
| `wahis_prod` | dbt production environment output |

**Pattern:** `<project>_<environment>`

The dbt staging, intermediate, and mart models all write to either `wahis_dev` or `wahis_prod` depending on the target environment. The `wahis_raw` dataset is written to by the Python ingestion scripts only and is never modified by dbt.

---

## dbt Model Naming

### Staging Layer

Staging models sit directly on top of raw source tables. They rename columns, cast types, and standardise values. No business logic or joins.

**Pattern:** `stg_<source>__<entity>.sql`

- `<source>`: the source system or dataset name (e.g. `wahis`)
- `<entity>`: the entity being staged (e.g. `outbreaks`)
- Double underscore (`__`) separates source from entity — this is dbt convention and makes it immediately clear which source a model belongs to

**Examples:**

| Model | Description |
|-------|-------------|
| `stg_wahis__outbreaks.sql` | Staged outbreak records from the raw CSV |
| `stg_wahis__diseases.sql` | Staged disease reference data (if separated) |

---

### Intermediate Layer

Intermediate models contain business logic — joins, enrichment, derived fields. They are not intended to be queried directly by analysts or dashboards.

**Pattern:** `int_<entity>_<transformation>.sql`

- `<entity>`: the primary entity being transformed
- `<transformation>`: a short description of what the model does

**Examples:**

| Model | Description |
|-------|-------------|
| `int_outbreaks_enriched.sql` | Outbreaks joined to disease categories and region metadata |
| `int_country_reporting_quality.sql` | Per-country completeness metrics derived from outbreak records |

---

### Mart Layer

Mart models are wide, flat, analysis-ready tables. They are the final output of the dbt project and the direct data source for Looker Studio.

**Pattern:** `mart_<entity>.sql`

- `<entity>`: a descriptive name aligned with the analytical question the model answers

**Examples:**

| Model | Description |
|-------|-------------|
| `mart_disease_trends.sql` | Outbreak counts by disease, species, and semester — feeds the trend dashboard page |
| `mart_country_summary.sql` | Per-country outbreak totals and reporting quality score — feeds the geographic and data quality pages |
| `mart_outbreak_detail.sql` | Flat, analysis-ready record of all outbreak events |

---

## dbt Seeds

Seeds are static CSV reference files stored in `/dbt/seeds/` and loaded into BigQuery with `dbt seed`.

**Pattern:** `<entity>.csv`

No prefix needed — seeds are small reference tables and their location in `/seeds/` makes their nature clear.

**Examples:**

| Seed file | Description |
|-----------|-------------|
| `disease_categories.csv` | Maps raw WAHIS disease names to clean short names and category groups |

---

## dbt Tests

Generic tests (not_null, unique, accepted_values) are defined in `schema.yml` files alongside model definitions. Custom tests live in `/dbt/tests/` as `.sql` files.

**Pattern for custom tests:** `test_<what_is_being_tested>.sql`

**Examples:**

| Test file | Description |
|-----------|-------------|
| `test_semester_year_not_null.sql` | Confirms year and semester are always populated |
| `test_new_outbreaks_not_negative.sql` | Confirms new outbreak counts are never negative |

---

## dbt Sources

Sources are declared in `sources.yml` within the staging folder. The source name should match the BigQuery dataset name.

**Pattern:**
```yaml
sources:
  - name: wahis_raw
    tables:
      - name: outbreaks
```

Referenced in models as `{{ source('wahis_raw', 'outbreaks') }}`.

---

## Column Naming Conventions

### General Column Rules

- All column names in `snake_case`
- Column names should describe what the value is, not the table it came from
- Boolean columns should read as a true/false statement (see below)
- Units of measurement should be included in the column name where ambiguous (e.g. `duration_days` not just `duration`)

---

### Keys and IDs

Use the suffix `_id` for natural keys from the source system. Use the suffix `_key` for any surrogate keys generated in the warehouse.

| Pattern | Use | Example |
|---------|-----|---------|
| `<entity>_id` | Natural key from source | `outbreak_id`, `event_id` |
| `<entity>_key` | Surrogate key generated in warehouse | `outbreak_key` |

---

### Date and Time Columns

Use the suffix `_date` for date columns and `_at` for timestamps.

| Pattern | Use | Example |
|---------|-----|---------|
| `<event>_date` | A calendar date | `outbreak_start_date` |
| `<event>_at` | A timestamp with time | `created_at`, `loaded_at` |
| `<period>_year` | A year value | `report_year` |
| `<period>_semester` | A semester label | `report_semester` |

---

### Boolean Columns

Boolean columns should be named so they read naturally as a true/false statement. Always use the prefix `is_` or `has_`.

| Pattern | Example |
|---------|---------|
| `is_<condition>` | `is_domestic`, `is_zoonotic` |
| `has_<field>` | `has_case_count`, `has_end_date` |

---

### Metric Columns

Metric columns (counts, sums, rates) should include a descriptive suffix indicating what is being measured.

| Pattern | Example |
|---------|---------|
| `<entity>_count` | `outbreak_count`, `case_count`, `death_count` |
| `<metric>_pct` | `case_count_completeness_pct` |
| `<metric>_score` | `composite_quality_score` |
| `<duration>_days` | `outbreak_duration_days` |

---

## Python Script Naming

Python scripts in `/ingestion/` are named to describe their single responsibility clearly.

**Pattern:** `<verb>_<subject>.py`

| Script | Description |
|--------|-------------|
| `fetch_wahis.py` | Downloads the raw CSV from the WAHIS portal |
| `clean_wahis.py` | Standardises columns, handles nulls, classifies row types |
| `load_to_bigquery.py` | Loads the clean CSV into the BigQuery raw dataset |

Scripts are designed to be run in order: fetch → clean → load. Each script has one job and can be run independently if needed.

---

## Git Branch Naming

**Pattern:** `<type>/<short-description>`

All words in the description are hyphen-separated. Branch names should be short but descriptive enough to understand without opening the branch.

| Type | Use | Example |
|------|-----|---------|
| `feature/` | New model, script, or dashboard page | `feature/staging-outbreaks` |
| `fix/` | Correcting a bug or broken test | `fix/null-case-count-handling` |
| `chore/` | Setup, configuration, repo structure | `chore/init-repo-structure` |
| `docs/` | Documentation updates | `docs/update-exploration-notes` |
| `refactor/` | Restructuring without changing output | `refactor/intermediate-layer` |

---

## Commit Message Conventions

Commit messages follow the Conventional Commits standard.

**Pattern:** `<type>: <short description in imperative mood>`

- Keep the description under 72 characters
- Use the imperative mood — "add model" not "added model" or "adds model"
- Be specific enough that the commit history tells a readable story

| Type | Use | Example |
|------|-----|---------|
| `feat:` | New model, script, or feature | `feat: add staging model for outbreaks` |
| `fix:` | Bug fix or broken test | `fix: handle null values in case_count field` |
| `chore:` | Setup or configuration | `chore: initialise repo structure` |
| `docs:` | Documentation only | `docs: add data exploration notes` |
| `refactor:` | Restructure without behaviour change | `refactor: split enrichment into two intermediate models` |
| `test:` | Adding or fixing tests | `test: add not_null test on outbreak_id` |
| `seed:` | Adding or updating seed files | `seed: add disease_categories reference table` |
