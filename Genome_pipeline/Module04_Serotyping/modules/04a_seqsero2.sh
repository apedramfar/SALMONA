#!/bin/bash -l
source config.sh

source package "$PKG_SEQSERO2"

LINE_NUM=$((SLURM_ARRAY_TASK_ID + 1))
IFS=$'\t' read -r SAMPLE_ID READ1 READ2 < <(sed -n "${LINE_NUM}p" "$SAMPLE_SHEET")

FASTA="$ASSEMBLY_DIR/${SAMPLE_ID}.fasta"
OUT="$SEQSERO2_DIR/${SAMPLE_ID}"

mkdir -p "$OUT"

echo "Sample: $SAMPLE_ID"
echo "FASTA: $FASTA"
echo "OUT: $OUT"
echo "CPUS: $SLURM_CPUS_PER_TASK"
date

SeqSero2_package.py \
    -t 4 \
    -m k \
    -i "$FASTA" \
    -n "$SAMPLE_ID" \
    -d "$OUT" \
    -p "$SLURM_CPUS_PER_TASK"

STATUS=$?
echo "SeqSero2 exit status: $STATUS"
date

exit $STATUS