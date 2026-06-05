# VetWatch: Global Animal Disease Analytics

VetWatch is a data engineering and analytics portfolio project that analyses 20 years of animal disease outbreak data from WAHIS (World Animal Health Information System), covering 201 countries and 172 diseases. This project intends to go beyond analysis and highlights the importance of data quality by building a model that quantifies reporting completeness of data by country and region alongside the outbreak patterns. The result is a project that explores not just what the data shows, but how much we can trust it.

The project is structured around three questions:

**🦠 Disease Trends** — Which diseases and disease categories show the highest outbreak reporting, and how has that changed over 20 years?

**🌍 Geographic Breakdown** — How are reported outbreaks distributed globally across regions and countries?

**🔍 Data Quality** — Which countries and regions show the highest data completeness, and what does that reveal about the reliability of global disease reporting?

---

## 🛠️ Stack

| Layer | Tool |
|-------|------|
| Ingestion & minimal cleaning | Python |
| Data warehouse | BigQuery |
| Transformation & modelling | dbt |
| Visualisation | Looker Studio |
| Version control | Git + GitHub |

---

## 🗂️ Data Source

The project ingests the WAHIS quantitative six-monthly report from 2005 to 2024. This is a publicly available CSV export from the World Organisation for Animal Health of animal disease outbreak events globally.

The data is available at [wahis.woah.org](https://wahis.woah.org) under **Six-monthly reports → Quantitative data**. No account is required to download it.

An API integration was considered to simulate how production pipelines work with multiple source types simultaneously, but was deprioritised in favour of building robust transformation and data quality layers.

> For detailed notes on the data source and its structure, quality issues found, and decisions made during initial exploration — see [`docs/data_exploration_notes.md`](docs/data_exploration_notes.md).

---

## 📐 Data Architecture

The data management approach follows a modern analytics engineering pattern, with a layered dbt architecture (staging → intermediate → marts) respecting Separation of Concerns.

![architecture_diagram.png]()

---

## 📁 Project Structure

```
vetwatch-disease-analytics/
│
├── ingestion/                   # Python ingestion scripts
│   ├── fetch_wahis.py
│   └── load_to_bigquery.py
│
├── dbt/                         # dbt project
│   ├── models/
│   │   ├── staging/
│   │   │   ├── schema.yml
│   │   │   ├── sources.yml
│   │   │   └── stg_wahis__outbreaks.sql
│   │   ├── intermediate/
│   │   │   ├── schema.yml
│   │   │   ├── int_outbreaks_enriched.sql
│   │   │   └── int_country_reporting_quality.sql
│   │   └── marts/
│   │       ├── schema.yml
│   │       ├── mart_disease_trends.sql
│   │       └── mart_data_quality_summary.sql
│   ├── seeds/
│   │   └── disease_categories.csv
│   └── tests/
│       ├── test_boolean_flags_valid.sql
│       ├── test_no_unmatched_diseases.sql
│       ├── test_quality_score_range.sql
│       ├── test_report_year_in_range.sql
│       └── test_quantitative_not_negative.sql
│
├── docs/                        # Project documentation
│   ├── data_exploration_notes.md
│   ├── naming_conventions.md
│   ├── architecture_diagram.png
│   ├── how_to_run.md
│   ├── analytical_findings.md
│   ├── problems_and_solutions.md
│   └── lineage_dag.png
│
├── dashboards/                  # Dashboard screenshots
│   ├── screenshot_disease_trends.png
│   ├── screenshot_geographic_breakdown.png
│   └── screenshot_data_quality.png
│
├── .env.example                 # Example environment variables (no secrets)
├── .gitignore
├── requirements.txt
├── dbt_project.yml
└── README.md
```

---

## ⚙️ How to Run

> Full setup and run instructions are available in [`docs/how_to_run.md`](docs/how_to_run.md).

---

## 📊 Dashboard

[VetWatch Dashboard](https://datastudio.google.com/reporting/0e63afda-0f13-45cf-bce7-31d5d90c8737) — Interactive dashboard with three pages covering disease trends, geographic breakdown, and data quality analysis.

### *Preview of the dashboard: Disease Trends (page 1)*
![screenshot_disease_trends.png]()

---

## 💡 Key Findings

The analysis of 4,126,257 animal disease outbreak records across 201 countries and 20 years reveals three headline findings:

**Disease trends**
Livestock diseases dominate global outbreak reporting (48.9%), led by Brucellosis, Echinococcus granulosus, and Bovine TB. Two significant events stand out: a severe FMD outbreak in Indonesia in 2022 ended the country's FMD-free status maintained since 1990, and Chile's Echinococcus granulosus reporting surged from 0 to 105,394 between 2018–2020 before returning to 0 — likely reflecting a reporting methodology change rather than a genuine disease emergence considering Echinococcus granulosus is an endemic disease in Chile.

**Geographic distribution**
The Americas, Europe, and Asia account for over 74% of all reported outbreaks. Iran leads globally with 435,700 outbreaks, followed by China and Chile. Whether high outbreak counts reflect genuine disease burden or strong reporting infrastructure cannot be determined from reporting data alone.

**Data quality**
The global average composite quality score is 71.5%, but varies significantly by region. Counterintuitively, the Middle East and Africa lead on data quality (78.6% and 78.5%) despite not being the highest outbreak-reporting regions — directly demonstrating that outbreak volume and reporting quality are not correlated. Vaccination reporting is the weakest metric globally (51.2%), compared to case reporting (87.8%) and death reporting (75.5%).

> Full findings with data points and limitations are available in [`docs/analytical_findings.md`](docs/analytical_findings.md).
> For a detailed report of technical problems found during the build and how they were resolved — see [`docs/problems_and_solutions.md`](docs/problems_and_solutions.md).

---

## 🛡️ License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 🔗 More About Me

Check out more of my work on my [GitHub profile](https://github.com/angelcpizarro) or connect with me on [LinkedIn](https://linkedin.com/in/angelcpizarro).

Thanks for visiting! 😸
