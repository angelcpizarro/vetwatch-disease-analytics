# VetWatch: Global Animal Disease Analytics
*In progress*

VetWatch is a data engineering and analytics portfolio project that analyses 20 years of animal disease outbreak data from WAHIS (World Organisation for Animal Health), covering 180+ countries and 100+ diseases. The central analytical question is: *What do 20 years of global animal disease surveillance data reveal about outbreak reporting patterns, and how reliable is the data behind them?*

Most analytical projects treat data quality as a constraint to work around. This project highlights the importance of data quality and governance. To do so, a data quality layer is built directly into the dbt mart models, reporting completeness by country and region.

The project is structured around three questions:

**🦠 Disease Trends** — Which diseases and disease categories show the highest outbreak reporting, and how has that changed over 20 years?

**🌍 Goegraphic Breakdown** — How are reported outbreaks distributed globally across regions and countries?

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

> For detailed notes on the data source and its structure, quality issues found, and decisions made during initial exploration, see [`docs/data_exploration_notes.md`](docs/data_exploration_notes.md).

---

## 📐 Data Architecture

The data management approach follows a modern analytics engineering pattern, with a layered dbt architecture (staging → intermediate → marts) respecting Separation of Concerns.

*Architecture diagram coming soon*

```
Dataset:       wahis.woah.org (CSV)
                      │
                      ▼
Ingestion:     Python scripts
               ├── fetch_wahis.py       — download raw CSV, standardise column names and handle null values
               └── load_to_bigquery.py  — load data to BigQuery
                      │
                      ▼
Warehouse:     BigQuery (wahis_raw)
                      │
                      ▼
Transform:     dbt project (wahis_analytics)
               ├── Staging              — trim and cast
               ├── Intermediate         — enriched, quality metrics (aggregations)
               ├── Marts                — analysis-ready tables for the dashboard
               └── Tests                — Built-in and custom tests
                      │
                      ▼
Serve:         Looker Studio dashboard
               ├── Page 1 — Disease Trends
               ├── Page 2 — Geographic Breakdown
               └── Page 3 — Data Quality
```

---

## 📁 Project Structure

```
vetwatch-global-animal-disease-analytics/
│
├── ingestion/                   # Python ingestion scripts
│   ├── fetch_wahis.py
│   └── load_to_bigquery.py
│
├── dbt/                         # dbt project
│   ├── models/
│   │   ├── staging/
│   │   ├── intermediate/
│   │   └── marts/
│   ├── seeds/
│   │   └── disease_categories.csv
│   └── tests/
│
├── docs/                        # Project documentation
│   ├── data_exploration_notes.md
│   ├── naming_conventions.md
│   ├── architecture_diagram.png
│   └── lineage_dag.png
│
├── dashboards/                  # Dashboard screenshots and exports
│
├── .env.example                 # Example environment variables (no secrets)
├── .gitignore
├── requirements.txt
└── README.md
```

---

## ⚙️ How to Run

### Prerequisites

- Python 3.9+
- A Google Cloud project with BigQuery enabled
- A service account with BigQuery Admin role
- dbt-bigquery installed

### 1. Clone the repo

```bash
git clone https://github.com/angelcpizarro/wahis-animal-disease-analytics.git
cd wahis-animal-disease-analytics
```

### 2. Set up Python environment

```bash
python -m venv venv
source venv/bin/activate        # Mac/Linux
venv\Scripts\activate           # Windows
pip install -r requirements.txt
```

### 3. Configure credentials

Copy `.env.example` to `.env` and fill in your Google Cloud details:

```bash
cp .env.example .env
```

Then open `.env` and add your credentials:

```
GOOGLE_APPLICATION_CREDENTIALS=path/to/your/service-account-key.json
GCP_PROJECT_ID=your-gcp-project-id
BQ_DATASET=wahis_raw
```

### 4. Run the ingestion pipeline

```bash
python ingestion/fetch_wahis.py
python ingestion/clean_wahis.py
python ingestion/load_to_bigquery.py
```

### 5. Run dbt

```bash
cd dbt
dbt seed          # load reference data
dbt build         # run models and tests
dbt docs generate # generate documentation
dbt docs serve    # view documentation in browser
```

---

## 📊 Dashboard

*Link to be added once the dashboard is published.*

---

## 💡 Key Findings

*To be completed once analysis is finalised.*

---

## ☑️ Skills Demonstrated

*To be completed once the project is finished.*

---

## 🛡️ License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 🔗 More About Me

Check out more of my work on my [GitHub profile](https://github.com/angelcpizarro) or connect with me on [LinkedIn](https://linkedin.com/in/angelcpizarro).

Thanks for visiting! 😸
