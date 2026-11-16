#!/bin/bash -l
source config.sh

echo "=== Module 04: Salmonella serotyping ==="
echo ""

# -----------------------------
# Check sample sheet
# -----------------------------
if [[ ! -f "$SAMPLE_SHEET" ]]; then
    echo "ERROR: Sample sheet not found:"
    echo "$SAMPLE_SHEET"
    exit 1
fi

NUM_JOBS=$(( $(wc -l < "$SAMPLE_SHEET") - 1 ))

if [[ "$NUM_JOBS" -lt 1 ]]; then
    echo "ERROR: No samples found in sample sheet"
    exit 1
fi

echo "Samples to process: $NUM_JOBS"
echo ""

# -----------------------------
# Check assembly FASTA files
# -----------------------------
echo "Checking assembly FASTA files..."

MISSING=0

while IFS=$'\t' read -r SAMPLE_ID READ1 READ2; do

    [[ "$SAMPLE_ID" == "sample_id" ]] && continue

    FASTA="$ASSEMBLY_DIR/${SAMPLE_ID}.fasta"

    if [[ ! -f "$FASTA" ]]; then
        echo "  MISSING: $SAMPLE_ID"
        echo "           $FASTA"
        ((MISSING++))
    fi

done < "$SAMPLE_SHEET"

if [[ "$MISSING" -gt 0 ]]; then
    echo ""
    echo "ERROR: $MISSING assembly FASTA file(s) missing"
    echo "Run Module 02 assembly first"
    exit 1
fi

# -----------------------------
# Create output directories
# -----------------------------
mkdir -p \
    "$SEQSERO2_DIR" \
    "$SISTR_DIR" \
    "$LOG_DIR"

# -----------------------------
# Submit SeqSero2
# -----------------------------
echo ""
echo "Submitting SeqSero2 array..."

JOB_SEQSERO2=$(sbatch \
    --job-name=04a_seqsero2 \
    --partition="$PARTITION_SEQSERO2" \
    --time="$TIME_SEQSERO2" \
    --cpus-per-task="$CPUS_SEQSERO2" \
    --mem-per-cpu="$MEM_PER_CPU_SEQSERO2" \
    --output="$LOG_DIR/%x_%A_%a.out" \
    --error="$LOG_DIR/%x_%A_%a.err" \
    --array=1-"${NUM_JOBS}" \
    modules/04a_seqsero2.sh)

echo "$JOB_SEQSERO2"

if [[ "$JOB_SEQSERO2" != Submitted\ batch\ job* ]]; then
    echo "ERROR: SeqSero2 sbatch submission failed"
    exit 1
fi

JOB_SEQSERO2_ID=$(echo "$JOB_SEQSERO2" | awk '{print $NF}')

# -----------------------------
# Submit SISTR
# -----------------------------
echo ""
echo "Submitting SISTR array..."

JOB_SISTR=$(sbatch \
    --job-name=04b_sistr \
    --partition="$PARTITION_SISTR" \
    --time="$TIME_SISTR" \
    --cpus-per-task="$CPUS_SISTR" \
    --mem-per-cpu="$MEM_PER_CPU_SISTR" \
    --output="$LOG_DIR/%x_%A_%a.out" \
    --error="$LOG_DIR/%x_%A_%a.err" \
    --array=1-"${NUM_JOBS}" \
    modules/04b_sistr.sh)

echo "$JOB_SISTR"

if [[ "$JOB_SISTR" != Submitted\ batch\ job* ]]; then
    echo "ERROR: SISTR sbatch submission failed"
    exit 1
fi

JOB_SISTR_ID=$(echo "$JOB_SISTR" | awk '{print $NF}')

# -----------------------------
# Final summary
# -----------------------------
echo ""
echo "Submitted jobs:"
echo "  SeqSero2 : $JOB_SEQSERO2_ID"
echo "  SISTR    : $JOB_SISTR_ID"

echo ""
echo "Monitor jobs with:"
echo "  squeue -u \$USER"

echo ""
echo "When complete, run:"
echo "  bash 04_check_serotyping.sh"