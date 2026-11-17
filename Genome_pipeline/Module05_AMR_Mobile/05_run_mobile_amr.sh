#!/bin/bash -l
source config.sh

echo "=== Mobile Elements & AMR Detection ==="
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

# ── Check at least one module is enabled ──────────────────────────────────────
if [[ "$RUN_AMRFINDER" != true && \
      "$RUN_GENOMAD" != true && \
      "$RUN_RESFINDER" != true ]]; then
    echo "ERROR: All modules are disabled. Enable at least one in config.sh"
    exit 1
fi

# ── Check assemblies exist ────────────────────────────────────────────────────
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

# ── Output and log directories ────────────────────────────────────────────────
[[ ! -d "$OUT_DIR" ]] && mkdir -p "$OUT_DIR"
[[ ! -d "$LOG_DIR" ]] && mkdir -p "$LOG_DIR"

echo ""
echo "Settings:"
echo "  AMRfinderplus : $RUN_AMRFINDER (organism: $AMRFINDER_ORGANISM)"
echo "  geNomad       : $RUN_GENOMAD"
echo ""

# ── Track submitted job IDs for merge dependency ──────────────────────────────
DEP_IDS=()

# ── Submit 05a: AMRfinderplus ─────────────────────────────────────────────────
if [[ "$RUN_AMRFINDER" == true ]]; then
    echo "Submitting AMRfinderplus for $NUM_JOBS samples..."
    JOB_AMR=$(sbatch \
        --job-name=05a_amrfinder \
        --partition="$PARTITION_AMRFINDER" \
        --time="$TIME_AMRFINDER" \
        --cpus-per-task="$CPUS_AMRFINDER" \
        --mem-per-cpu="$MEM_PER_CPU_AMRFINDER" \
        --output="$LOG_DIR/%x_%A_%a.out" \
        --error="$LOG_DIR/%x_%A_%a.err" \
        --array=1-${NUM_JOBS} \
        modules/05a_amrfinder.sh)
    echo "$JOB_AMR"
    DEP_IDS+=( $(echo "$JOB_AMR" | awk '{print $NF}') )
fi

# ── Submit 05b: geNomad ───────────────────────────────────────────────────────
if [[ "$RUN_GENOMAD" == true ]]; then
    echo ""
    echo "Submitting geNomad for $NUM_JOBS samples..."
    JOB_GEN=$(sbatch \
        --job-name=05b_genomad \
        --partition="$PARTITION_GENOMAD" \
        --time="$TIME_GENOMAD" \
        --cpus-per-task="$CPUS_GENOMAD" \
        --mem-per-cpu="$MEM_PER_CPU_GENOMAD" \
        --output="$LOG_DIR/%x_%A_%a.out" \
        --error="$LOG_DIR/%x_%A_%a.err" \
        --array=1-${NUM_JOBS} \
        modules/05b_genomad.sh)
    echo "$JOB_GEN"
    DEP_IDS+=( $(echo "$JOB_GEN" | awk '{print $NF}') )
fi

# ── Submit 05b: resFinder ───────────────────────────────────────────────────────

if [[ "$RUN_RESFINDER" == true ]]; then
    echo ""
    echo "Submitting ResFinder for $NUM_JOBS samples..."

    JOB_RES=$(sbatch \
        --job-name=05c_resfinder \
        --partition="$PARTITION_RESFINDER" \
        --time="$TIME_RESFINDER" \
        --cpus-per-task="$CPUS_RESFINDER" \
        --mem-per-cpu="$MEM_PER_CPU_RESFINDER" \
        --output="$LOG_DIR/%x_%A_%a.out" \
        --error="$LOG_DIR/%x_%A_%a.err" \
        --array=1-${NUM_JOBS} \
        modules/05c_resfinder.sh)

    echo "$JOB_RES"
    DEP_IDS+=( $(echo "$JOB_RES" | awk '{print $NF}') )
fi

# ── Submit 05d: merge (depends on all enabled jobs) ───────────────────────────
if [[ "${#DEP_IDS[@]}" -gt 0 ]]; then
    DEP_STRING="afterok:$(IFS=':'; echo "${DEP_IDS[*]}")"
    echo ""
    echo "Submitting merge (depends on: ${DEP_IDS[*]})..."

    JOB_MERGE=$(sbatch \
        --job-name=05d_merge \
        --partition="$PARTITION_MERGE_MOB" \
        --time="$TIME_MERGE_MOB" \
        --cpus-per-task=2 \
        --mem-per-cpu="4G" \
        --output="$LOG_DIR/%x_%A.out" \
        --error="$LOG_DIR/%x_%A.err" \
        --dependency="$DEP_STRING" \
        modules/05d_merge.sh)

    echo "$JOB_MERGE"
fi

echo ""
echo "When complete, run: bash 05_check_mobile_amr.sh"
