
#!/bin/bash -l

source config.sh

source package "$PKG_SISTR"
LINE=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$SAMPLE_SHEET")
SAMPLE_ID=$(echo "$LINE" | cut -f1)

FASTA="$ASSEMBLY_DIR/${SAMPLE_ID}.fasta"
OUT_SAMPLE="$SISTR_DIR/${SAMPLE_ID}"

mkdir -p "$OUT_SAMPLE"

echo "Running SISTR for $SAMPLE_ID"
echo "Input : $FASTA"
echo "Output: $OUT_SAMPLE"

sistr \
    -o "$OUT_SAMPLE/${SAMPLE_ID}_sistr.csv" \
    -f csv \
    "$FASTA"
