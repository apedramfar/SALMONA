
#!/bin/bash -l

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MODULE06_SCRIPT_DIR="$HERE"

# Load configuration
if ! source "$HERE/config.sh"; then
    echo "ERROR: Could not load config.sh"
    exit 1
fi

echo "=== Module 06 — Prophage analysis ==="
echo "06A PHORAGER → handoff → 06B vConTACT3"
echo ""

# -----------------------------
# Check input assemblies
# -----------------------------

if [[ ! -d "$GENOME_DIR" ]]; then
    echo "ERROR: Genome directory not found:"
    echo "  $GENOME_DIR"
    exit 1
fi

ASSEMBLY_COUNT=$(find "$GENOME_DIR" -maxdepth 1 -type f \
    \( -name "*.fasta" -o -name "*.fa" -o -name "*.fna" \) | wc -l)

if [[ "$ASSEMBLY_COUNT" -eq 0 ]]; then
    echo "ERROR: No input assemblies found."
    exit 1
fi

# -----------------------------
# Create output directories
# -----------------------------

mkdir -p "$PHORAGER_DIR" "$HANDOFF_DIR" "$VCONTACT3_DIR" "$LOG_DIR" || exit 1

echo "Assemblies       : $ASSEMBLY_COUNT"
echo "PHORAGER output  : $PHORAGER_DIR"
echo "Handoff mode     : $PHORAGER_HANDOFF_MODE"
echo "vConTACT3 output : $VCONTACT3_DIR"
echo ""

# -----------------------------
# 06A — PHORAGER
# -----------------------------

echo "Submitting 06A PHORAGER..."

J6A=$(sbatch \
    --job-name=06a_phorager \
    --partition="$PARTITION_PHORAGER" \
    --time="$TIME_PHORAGER" \
    --cpus-per-task="$CPUS_PHORAGER" \
    --mem-per-cpu="$MEM_PER_CPU_PHORAGER" \
    --output="$LOG_DIR/%x_%j.out" \
    --error="$LOG_DIR/%x_%j.err" \
    "$HERE/modules/06a_phorager.sh")

if [[ "$J6A" != Submitted\ batch\ job\ * ]]; then
    echo "ERROR: PHORAGER job submission failed."
    echo "$J6A"
    exit 1
fi

J6A_ID=$(echo "$J6A" | awk '{print $NF}')
echo "$J6A"

# -----------------------------
# 06a2 — PHORAGER handoff
# -----------------------------

echo ""
echo "Submitting 06a2 handoff (after PHORAGER: $J6A_ID)..."

JHAND=$(sbatch \
    --job-name=06a2_phorager_handoff \
    --partition="$PARTITION_HANDOFF" \
    --time="$TIME_HANDOFF" \
    --cpus-per-task="$CPUS_HANDOFF" \
    --mem="$MEM_HANDOFF" \
    --output="$LOG_DIR/%x_%j.out" \
    --error="$LOG_DIR/%x_%j.err" \
    --dependency="afterok:$J6A_ID" \
    "$HERE/modules/06a2_prepare_vcontact3_input.sh")

if [[ "$JHAND" != Submitted\ batch\ job\ * ]]; then
    echo "ERROR: PHORAGER handoff job submission failed."
    echo "$JHAND"
    exit 1
fi

JHAND_ID=$(echo "$JHAND" | awk '{print $NF}')
echo "$JHAND"

# -----------------------------
# 06B — vConTACT3
# -----------------------------

echo ""
echo "Submitting 06B vConTACT3 (after handoff: $JHAND_ID)..."

J6B=$(sbatch \
    --job-name=06b_vcontact3 \
    --partition="$PARTITION_VCONTACT3" \
    --time="$TIME_VCONTACT3" \
    --cpus-per-task="$CPUS_VCONTACT3" \
    --mem-per-cpu="$MEM_PER_CPU_VCONTACT3" \
    --output="$LOG_DIR/%x_%j.out" \
    --error="$LOG_DIR/%x_%j.err" \
    --dependency="afterok:$JHAND_ID" \
    "$HERE/modules/06b_vcontact3.sh")

if [[ "$J6B" != Submitted\ batch\ job\ * ]]; then
    echo "ERROR: vConTACT3 job submission failed."
    echo "$J6B"
    exit 1
fi

J6B_ID=$(echo "$J6B" | awk '{print $NF}')
echo "$J6B"

# -----------------------------
# 06b2 — vConTACT3 summary
# -----------------------------

echo ""
echo "Submitting 06b2 summary (after vConTACT3: $J6B_ID)..."

JSUM=$(sbatch \
    --job-name=06b2_vcontact3_summary \
    --partition="$PARTITION_VCONTACT3_SUMMARY" \
    --time="$TIME_VCONTACT3_SUMMARY" \
    --cpus-per-task="$CPUS_VCONTACT3_SUMMARY" \
    --mem-per-cpu="$MEM_PER_CPU_VCONTACT3_SUMMARY" \
    --output="$LOG_DIR/%x_%j.out" \
    --error="$LOG_DIR/%x_%j.err" \
    --dependency="afterok:$J6B_ID" \
    "$HERE/modules/06b2_vcontact3_summary.sh")

if [[ "$JSUM" != Submitted\ batch\ job\ * ]]; then
    echo "ERROR: vConTACT3 summary job submission failed."
    echo "$JSUM"
    exit 1
fi

JSUM_ID=$(echo "$JSUM" | awk '{print $NF}')
echo "$JSUM"

# -----------------------------
# Final summary
# -----------------------------

echo ""
echo "Submitted jobs:"
echo "  06A PHORAGER       : $J6A_ID"
echo "  06a2 handoff       : $JHAND_ID"
echo "  06B vConTACT3      : $J6B_ID"
echo "  06b2 summary       : $JSUM_ID"

echo ""
echo "Dependency chain:"
echo "  PHORAGER → handoff → vConTACT3 → summary"

echo ""
echo "Monitor jobs with:"
echo "  squeue -u $USER"

echo ""
echo "When all jobs have completed, run:"
echo "  bash 06_check_prophage.sh"
