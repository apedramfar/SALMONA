#!/bin/bash

# Input directory containing paired-end FASTQ files
  READS_DIR="/path/to/your/reads"

# Output sample sheet
 OUTPUT="/path/to/output/samples.tsv"

R1_SUFFIX="_R1_001.fastq.gz"
R2_SUFFIX="_R2_001.fastq.gz"

# Check input directory
if [[ ! -d "$READS_DIR" ]]; then
    echo "ERROR: Input directory does not exist: $READS_DIR"
    exit 1
fi

# Create output directory if needed
mkdir -p "$(dirname "$OUTPUT")"

# Write sample sheet header
printf "sample_id\tread1\tread2\n" > "$OUTPUT"

# Find paired-end FASTQ files
while IFS= read -r -d '' R1; do

    SAMPLE_ID=$(basename "$R1" "$R1_SUFFIX")
    SAMPLE_DIR=$(dirname "$R1")
    R2="${SAMPLE_DIR}/${SAMPLE_ID}${R2_SUFFIX}"

    # Check for matching R2
    if [[ ! -f "$R2" ]]; then
        echo "WARNING: No R2 found for sample $SAMPLE_ID, skipping"
        continue
    fi

    # Add sample to TSV
    printf "%s\t%s\t%s\n" \
        "$SAMPLE_ID" "$R1" "$R2" >> "$OUTPUT"

done < <(
    find "$READS_DIR" \
        -mindepth 2 -maxdepth 2 \
        -type f -name "*${R1_SUFFIX}" \
        -print0 | sort -zV
)

# Report results
echo "Sample sheet written to $OUTPUT"
echo "$(($(wc -l < "$OUTPUT") - 1)) samples found"