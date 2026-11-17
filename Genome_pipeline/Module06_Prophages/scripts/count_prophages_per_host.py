#!/usr/bin/env python3

import pandas as pd

input_file = "prophage_table.tsv"
output_file = "prophage_counts_per_host.tsv"

df = pd.read_csv(input_file, sep="\t")

# Count total prophages per bacterial host
counts = (
    df.groupby("Bacterial_host")
      .agg(
          prophage_count=("Prophage_name", "count"),
          unique_prophage_clusters=("Cluster_representative", "nunique"),
          complete=("CheckV_quality", lambda x: (x == "Complete").sum()),
          high_quality=("CheckV_quality", lambda x: (x == "High-quality").sum()),
          medium_quality=("CheckV_quality", lambda x: (x == "Medium-quality").sum()),
          mean_phage_length=("Phage_length", "mean")
      )
      .reset_index()
      .sort_values("prophage_count", ascending=False)
)

counts["mean_phage_length"] = counts["mean_phage_length"].round(0).astype(int)

counts.to_csv(output_file, sep="\t", index=False)

print(f"Saved: {output_file}")
print(counts.head(20))
