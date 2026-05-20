import pandas as pd
import os

# Paths
RAW_DATA_PATH = "data/wahis_quantitative_data.csv"
OUTPUT_PATH = "data/wahis_raw.csv"

def load_raw_data(path):
    """Load the raw WAHIS CSV file."""
    print(f"Loading raw data from {path}...")
    df = pd.read_csv(path, encoding="utf-8") # Use of encoding as safer for international data
    print(f"✓ Loaded {len(df):,} rows and {len(df.columns)} columns") # Use of ":," to make numbers more readable
    return df

def rename_columns(df):
    """Rename columns to snake_case for BigQuery compatibility."""
    print("Renaming columns to snake_case...")
    df.columns = (
        df.columns
        .str.strip()
        .str.lower()
        .str.replace(" ", "_")
        .str.replace("/", "_")
    )
    print(f"✓ Columns renamed: {list(df.columns)}")
    return df

def replace_missing_values(df):
    """Replace '-' with None (NULL in BigQuery)."""
    print("Replacing '-' with NULL...")
    df = df.replace("-", None)
    print("✓ Missing values standardised")
    return df

def save_data(df, path):
    """Save the prepared dataframe to CSV."""
    print(f"Saving prepared data to {path}...")
    os.makedirs(os.path.dirname(path), exist_ok=True) # Create directory from path if it doesn't exist
    df.to_csv(path, index=False, encoding="utf-8")
    print(f"✓ Saved {len(df):,} rows to {path}")

def main():
    print("=== VetWatch — WAHIS Data Fetch ===\n")
    df = load_raw_data(RAW_DATA_PATH)
    df = rename_columns(df)
    df = replace_missing_values(df)
    save_data(df, OUTPUT_PATH)
    print("\n=== Fetch complete ===")
    print(f"Output: {OUTPUT_PATH}")
    print(f"Rows: {len(df):,}")
    print(f"Columns: {len(df.columns)}")
    print(f"Nulls in case_count: {df['cases'].isna().sum():,}")

if __name__ == "__main__": # Run the main() function if the script is being run directly
    main()