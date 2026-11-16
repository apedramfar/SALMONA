#!/bin/bash -l
source config.sh

echo "=== QC + Host Removal + MetaPhlAn Profiling ==="
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

# ── Sequencing type ───────────────────────────────────────────────────────────
if [[ -z "$TYPE" ]]; then
    echo "ERROR: TYPE is not set in config.sh"
    exit 1
fi
TYPE_LOWER=$(echo "$TYPE" | tr '[:upper:]' '[:lower:]')
if [[ "$TYPE_LOWER" != "illumina" && "$TYPE_LOWER" != "mgi" ]]; then
    echo "ERROR: TYPE must be 'illumina' or 'mgi'. Current value: $TYPE"
    exit 1
fi
echo "Sequencing type: $TYPE"

# ── Host reference ────────────────────────────────────────────────────────────
if [[ -z "$HOST_REF" ]]; then
    echo "ERROR: HOST_REF is not set in config.sh"
    exit 1
fi
if [[ "$HOST_REF" != "human" && "$HOST_REF" != "mouse" ]]; then
    echo "ERROR: HOST_REF must be 'human' or 'mouse'. Current value: $HOST_REF"
    exit 1
fi
echo "Host reference: $HOST_REF"

# ── Output and log directories ────────────────────────────────────────────────
[[ ! -d "$OUT_DIR" ]] && mkdir -p "$OUT_DIR"
[[ ! -d "$LOG_DIR" ]] && mkdir -p "$LOG_DIR"

# ── Submit 01a: QC + host removal array ──────────────────────────────────────
echo ""
echo "Submitting QC + host removal for $NUM_JOBS samples..."
JOB_QC=$(sbatch \
    --job-name=01a_qc_host \
    --partition="$PARTITION_QC" \
    --time="$TIME_QC" \
    --cpus-per-task="$CPUS_QC" \
    --mem-per-cpu="$MEM_PER_CPU_QC" \
    --output="$LOG_DIR/%x_%A_%a.out" \
    --error="$LOG_DIR/%x_%A_%a.err" \
    --array=1-${NUM_JOBS} \
    modules/01a_qc_host_removal.sh)
echo "$JOB_QC"
JOB_QC_ID=$(echo "$JOB_QC" | awk '{print $NF}')

# ── Submit 01b: MetaPhlAn profiling array (depends on 01a) ───────────────────
echo ""
echo "Submitting MetaPhlAn profiling for $NUM_JOBS samples (depends on 01a: $JOB_QC_ID)..."
JOB_MET=$(sbatch \
    --job-name=01b_metaphlan \
    --partition="$PARTITION_METAPHLAN" \
    --time="$TIME_METAPHLAN" \
    --cpus-per-task="$CPUS_METAPHLAN" \
    --mem-per-cpu="$MEM_PER_CPU_METAPHLAN" \
    --output="$LOG_DIR/%x_%A_%a.out" \
    --error="$LOG_DIR/%x_%A_%a.err" \
    --array=1-${NUM_JOBS} \
    --dependency=afterok:${JOB_QC_ID} \
    modules/01b_metaphlan_profiling.sh)
echo "$JOB_MET"
JOB_MET_ID=$(echo "$JOB_MET" | awk '{print $NF}')

# ── Submit 01c: merge + contamination summary (depends on 01b) ───────────────
echo ""
echo "Submitting QC merge + contamination summary (depends on 01b: $JOB_MET_ID)..."
JOB_MERGE=$(sbatch \
    --job-name=01c_qc_merge \
    --partition="$PARTITION_MERGE" \
    --time="$TIME_MERGE" \
    --cpus-per-task=2 \
    --mem-per-cpu="4G" \
    --output="$LOG_DIR/%x_%A_%a.out" \
    --error="$LOG_DIR/%x_%A_%a.err" \
    --dependency=afterok:${JOB_MET_ID} \
    modules/01c_qc_merge.sh)
echo "$JOB_MERGE"

echo ""
echo "When complete, run: bash 01_check_qc.sh"
