#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err

source config.sh

# ── Load environment ──────────────────────────────────────────────────────────
source package "$PKG_RESFINDER"

echo "Job started"; hostname; date

# ── Parse sample sheet ────────────────────────────────────────────────────────
LINE=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "$SAMPLE_SHEET")
SAMPLE_ID=$(echo "$LINE" | awk '{print $1}')

echo "Processing sample: $SAMPLE_ID"

# ── Input assembly ────────────────────────────────────────────────────────────
FASTA="$OUT_DIR/02_assembly/fasta/${SAMPLE_ID}.fasta"

if [[ ! -f "$FASTA" ]]; then
    echo "ERROR: Assembly not found for $SAMPLE_ID at $FASTA"
    exit 1
fi

# ── ResFinder databases ───────────────────────────────────────────────────────

# ResFinder database location
DB_DIR="$RESFINDER_DB"

export CGE_RESFINDER_RESGENE_DB="$DB_DIR/resfinder_db"
export CGE_RESFINDER_RESPOINT_DB="$DB_DIR/pointfinder_db"
export CGE_DISINFINDER_DB="$DB_DIR/disinfinder_db"

# Needed for ResFinder dependencies on QIB system
export PATH="$PATH:/your/path/users/phorager_v0.3.0-beta"

# ── Output directory ──────────────────────────────────────────────────────────
RESFINDER_OUT="$OUT_DIR/05_mobile_amr/resfinder/${SAMPLE_ID}"
mkdir -p "$RESFINDER_OUT"

# ── Run ResFinder ─────────────────────────────────────────────────────────────
echo "Running ResFinder for $SAMPLE_ID"

resfinder \
    -o "$RESFINDER_OUT" \
    -l 0.6 \
    -t 0.8 \
    --acquired \
    -ifa "$FASTA"

# ── Sanity check ──────────────────────────────────────────────────────────────
RESULT_FILE="$RESFINDER_OUT/ResFinder_results_tab.txt"

if [[ ! -f "$RESULT_FILE" ]]; then
    echo "ERROR: ResFinder did not produce output for $SAMPLE_ID"
    echo "Expected: $RESULT_FILE"
    exit 1
fi

# ── Quick summary ─────────────────────────────────────────────────────────────
TOTAL=$(tail -n +2 "$RESULT_FILE" | wc -l)

echo "ResFinder summary for $SAMPLE_ID:"
echo "  Acquired AMR hits : $TOTAL"

echo "Output written to: $RESFINDER_OUT"
echo "Job done"; date
