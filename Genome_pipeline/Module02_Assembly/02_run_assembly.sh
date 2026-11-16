#!/bin/bash -l
source config.sh

echo "=== Genome Assembly & QC ==="
echo ""

# ── Sample sheet ──────────────────────────────────────────────────────────────
if [[ ! -f "$SAMPLE_SHEET" ]]; then
    echo "ERROR: Sample sheet not found at $SAMPLE_SHEET"
    exit 1
fi

NUM_JOBS=$(( $(wc -l < "$SAMPLE_SHEET") - 1 ))
if [[ "$NUM_JOBS" -lt 1 ]]; then
    echo "ERROR: No samples found in $SAMPLE_SHEET"
    exit 1
fi
echo "Samples to process: $NUM_JOBS"

# ── Check clean reads exist before submitting ─────────────────────────────────
echo "Checking clean reads from Module 01..."
MISSING_READS=0
while IFS=$'\t' read -r SAMPLE_ID READ1 READ2; do
    [[ "$SAMPLE_ID" == "sample_id" ]] && continue
    R1="$OUT_DIR/01_qc/trimming/${SAMPLE_ID}_clean_R1.fq.gz"
    R2="$OUT_DIR/01_qc/trimming/${SAMPLE_ID}_clean_R2.fq.gz"
    if [[ ! -f "$R1" || ! -f "$R2" ]]; then
        echo "  MISSING: $SAMPLE_ID"
        ((MISSING_READS++))
    fi
done < "$SAMPLE_SHEET"

if [[ "$MISSING_READS" -gt 0 ]]; then
    echo "ERROR: $MISSING_READS sample(s) are missing clean reads. Run 01_check_qc.sh first."
    exit 1
fi
echo "All clean reads found."

# ── Output and log directories ────────────────────────────────────────────────
[[ ! -d "$OUT_DIR" ]] && mkdir -p "$OUT_DIR"
[[ ! -d "$LOG_DIR" ]] && mkdir -p "$LOG_DIR"

# ── Submit 02a: assembly + coverage array ─────────────────────────────────────
echo ""
echo "Submitting assembly + coverage for $NUM_JOBS samples..."
JOB_ASS=$(sbatch \
    --job-name=02a_assembly_coverage \
    --partition="$PARTITION_ASSEMBLY" \
    --time="$TIME_ASSEMBLY" \
    --cpus-per-task="$CPUS_ASSEMBLY" \
    --mem-per-cpu="$MEM_PER_CPU_ASSEMBLY" \
    --output="$LOG_DIR/%x_%A_%a.out" \
    --error="$LOG_DIR/%x_%A_%a.err" \
    --array=1-${NUM_JOBS} \
    modules/02a_assembly_coverage.sh)
echo "$JOB_ASS"
JOB_ASS_ID=$(echo "$JOB_ASS" | awk '{print $NF}')

# ── Submit 02b: CheckM2 single job (depends on 02a) ───────────────────────────
echo ""
echo "Submitting CheckM2 (depends on 02a: $JOB_ASS_ID)..."
JOB_CHK=$(sbatch \
    --job-name=02b_checkm2 \
    --partition="$PARTITION_CHECKM2" \
    --time="$TIME_CHECKM2" \
    --cpus-per-task="$CPUS_CHECKM2" \
    --mem-per-cpu="$MEM_PER_CPU_CHECKM2" \
    --output="$LOG_DIR/%x_%A_%a.out" \
    --error="$LOG_DIR/%x_%A_%a.err" \
    --dependency=afterok:${JOB_ASS_ID} \
    modules/02b_checkm2.sh)
echo "$JOB_CHK"

echo ""
echo "When complete, run: bash 02_check_assembly.sh"
