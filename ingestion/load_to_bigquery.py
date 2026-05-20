import os
import pandas as pd
from google.cloud import bigquery
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configuration
PROJECT_ID = os.getenv("GCP_PROJECT_ID")
DATASET_ID = os.getenv("BQ_DATASET")
TABLE_ID = "outbreaks"
INPUT_PATH = "data/wahis_raw.csv"

def load_data(path):
    """Load the prepared CSV file."""
    print(f"Loading data from {path}...")
    df = pd.read_csv(path, encoding="utf-8")
    print(f"✓ Loaded {len(df):,} rows and {len(df.columns)} columns")
    return df

def upload_to_bigquery(df, project_id, dataset_id, table_id):
    """Upload dataframe to BigQuery."""
    client = bigquery.Client(project=project_id)
    
    table_ref = f"{project_id}.{dataset_id}.{table_id}"
    print(f"Uploading to {table_ref}...")

    job_config = bigquery.LoadJobConfig(
        write_disposition="WRITE_TRUNCATE",  # replace table if exists
        autodetect=True                      # auto-detect schema (data types)
    )

    job = client.load_table_from_dataframe(
        df, table_ref, job_config=job_config
    )
    job.result()  # wait for job to complete

    table = client.get_table(table_ref)
    print(f"✓ Loaded {table.num_rows:,} rows to {table_ref}")

def main():
    print("=== VetWatch — BigQuery Load ===\n")
    
    # Validate environment variables
    if not PROJECT_ID or not DATASET_ID:
        raise ValueError("Missing environment variables — check your .env file")
    
    print(f"Project: {PROJECT_ID}")
    print(f"Dataset: {DATASET_ID}")
    print(f"Table:   {TABLE_ID}\n")
    
    df = load_data(INPUT_PATH)
    upload_to_bigquery(df, PROJECT_ID, DATASET_ID, TABLE_ID)
    
    print("\n=== Load complete ===")
    print(f"Table: {PROJECT_ID}.{DATASET_ID}.{TABLE_ID}")
    print(f"Rows: {len(df):,}")

if __name__ == "__main__":
    main()