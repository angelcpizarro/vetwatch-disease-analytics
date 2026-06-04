# How to run the project

## Prerequisites

- Python 3.9+
- A Google Cloud project with BigQuery
- A service account with BigQuery to be able to connect with dbt. Download key as JSON file
- A dbt account and a dbt project 
- During project creation, select BigQuery as the data warehouse and upload the JSON service account key downloaded from BigQuery
- Connect to GitHub repository for automatic version control

## 0. Download the data

Download the WAHIS quantitative export from [wahis.woah.org](https://wahis.woah.org):
- Navigate to **Six-monthly reports → Quantitative data**
- Select all regions, years 2005–2024
- Download as CSV and save to `data/raw/wahis_quantitative_data.csv`

## 1. Clone the repo

```bash
git clone https://github.com/angelcpizarro/vetwatch-disease-analytics.git
cd vetwatch-disease-analytics
```

## 2. Set up Python environment

```bash
python -m venv venv
source venv/bin/activate        # Mac/Linux
venv\Scripts\activate           # Windows
pip install -r requirements.txt
```

## 3. Configure credentials

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

## 4. Run the ingestion pipeline

```bash
python ingestion/fetch_wahis.py
python ingestion/load_to_bigquery.py
```

## 5. Run dbt

```bash
cd dbt/project_name
dbt seed          # load reference data
dbt build         # run models and tests
```