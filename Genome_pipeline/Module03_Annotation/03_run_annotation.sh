#!/bin/bash -l
source config.sh

echo "=== Dereplication & Annotation ==="
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

# ── Check assemblies exist before submitting ──────────────────────────────────
echo "Checking assemblies from Module 02..."
MISSING_ASS=0
while IFS=$'\t' read -r SAMPLE_ID READ1 READ2; do
    [[ "$SAMPLE_ID" == "sample_id" ]] && continue
    FASTA="$OUT_DIR/02_assembly/fasta/${SAMPLE_ID}.fasta"
    if [[ ! -f "$FASTA" ]]; then
        echo "  MISSING: $SAMPLE_ID"
        ((MISSING_ASS++))
    fi
done < "$SAMPLE_SHEET"

if [[ "$MISSING_ASS" -gt 0 ]]; then
    echo "ERROR: $MISSING_ASS assembly/assemblies missing. Run 02_check_assembly.sh first."
    exit 1
fi
echo "All assemblies found."

# ── Check CheckM2 report exists ───────────────────────────────────────────────
CHECKM2_REPORT="$OUT_DIR/00_final_results/02_assembly/checkm2_quality_report.tsv"
if [[ ! -f "$CHECKM2_REPORT" ]]; then
    echo "ERROR: CheckM2 report not found at $CHECKM2_REPORT"
    echo "       Has 02b_checkm2 completed successfully?"
    exit 1
fi

# ── Output and log directories ────────────────────────────────────────────────
[[ ! -d "$OUT_DIR" ]] && mkdir -p "$OUT_DIR"
[[ ! -d "$LOG_DIR" ]] && mkdir -p "$LOG_DIR"

echo ""
echo "Settings:"
echo "  dRep ANI threshold : $DREP_ANI"
echo "  Bakta species      : $BAKTA_SPECIES"
echo ""

# ── Submit 03a: dRep ──────────────────────────────────────────────────────────
echo "Submitting dRep..."
JOB_DREP=$(sbatch \
    --job-name=03a_drep \
    --partition="$PARTITION_DREP" \
    --time="$TIME_DREP" \
    --cpus-per-task="$CPUS_DREP" \
    --mem-per-cpu="$MEM_PER_CPU_DREP" \
    --output="$LOG_DIR/%x_%A_%a.out" \
    --error="$LOG_DIR/%x_%A_%a.err" \
    modules/03a_drep.sh)
echo "$JOB_DREP"
JOB_DREP_ID=$(echo "$JOB_DREP" | awk '{print $NF}')

# ── Submit 03b: Bakta array (depends on 03a) ──────────────────────────────────
echo ""
echo "Submitting Bakta annotation for $NUM_JOBS samples (depends on 03a: $JOB_DREP_ID)..."
JOB_BAKTA=$(sbatch \
    --job-name=03b_bakta \
    --partition="$PARTITION_BAKTA" \
    --time="$TIME_BAKTA" \
    --cpus-per-task="$CPUS_BAKTA" \
    --mem-per-cpu="$MEM_PER_CPU_BAKTA" \
    --output="$LOG_DIR/%x_%A_%a.out" \
    --error="$LOG_DIR/%x_%A_%a.err" \
    --array=1-${NUM_JOBS} \
    --dependency=afterok:${JOB_DREP_ID} \
    modules/03b_bakta.sh)
echo "$JOB_BAKTA"
JOB_BAKTA_ID=$(echo "$JOB_BAKTA" | awk '{print $NF}')

# ── Submit 03c: merge (depends on 03b) ────────────────────────────────────────
echo ""
echo "Submitting merge (depends on 03b: $JOB_BAKTA_ID)..."
JOB_MERGE=$(sbatch \
    --job-name=03c_merge \
    --partition="$PARTITION_MERGE_ANN" \
    --time="$TIME_MERGE_ANN" \
    --cpus-per-task=2 \
    --mem-per-cpu="4G" \
    --output="$LOG_DIR/%x_%A_%a.out" \
    --error="$LOG_DIR/%x_%A_%a.err" \
    --dependency=afterok:${JOB_BAKTA_ID} \
    modules/03c_merge.sh)
echo "$JOB_MERGE"

echo ""
echo "When complete, run: bash 03_check_annotation.sh"
