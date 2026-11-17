#!/bin/bash -l

source config.sh

mkdir -p "$LOG_DIR"

echo "=== Module 07 — PrepExternalSchema (run once) ==="
echo ""

if [[ ! -d "$CHEW_EXISTING_SCHEMA" ]]; then
    echo "ERROR: existing schema not found at $CHEW_EXISTING_SCHEMA"
    exit 1
fi

echo "Input schema  : $CHEW_EXISTING_SCHEMA"
echo "Input loci    : $(find "$CHEW_EXISTING_SCHEMA" -maxdepth 1 -type f -name "*.fasta" | wc -l)"
echo "Output schema : $CHEW_PREPARED_SCHEMA"
echo ""

if [[ -d "$CHEW_PREPARED_SCHEMA" ]]; then
    echo "Prepared schema already exists at $CHEW_PREPARED_SCHEMA"
    echo "Delete it first if you want to re-run preparation."
    exit 0
fi

echo "Submitting PrepExternalSchema..."
JOB=$(sbatch \
    --job-name=07_prep_schema \
    --partition="$PARTITION_CHEWBBACA" \
    --time="$TIME_CHEWBBACA" \
    --cpus-per-task="$CPUS_CHEWBBACA" \
    --mem-per-cpu="$MEM_PER_CPU_CHEWBBACA" \
    --output="$LOG_DIR/%x_%j.out" \
    --error="$LOG_DIR/%x_%j.err" \
    modules/07_prep_schema_job.sh)
echo "$JOB"

echo ""
echo "When complete, verify $CHEW_PREPARED_SCHEMA exists before running:"
echo "  bash 07_run_chewBBACA.sh"
