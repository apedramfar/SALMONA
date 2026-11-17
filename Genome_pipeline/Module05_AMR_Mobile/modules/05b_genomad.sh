#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err

source config.sh

# ── Load environment ──────────────────────────────────────────────────────────
source package "$PKG_GENOMAD"

echo "Job started"; hostname; date

# ── Parse sample sheet ────────────────────────────────────────────────────────
LINE=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" $SAMPLE_SHEET)
SAMPLE_ID=$(echo "$LINE" | awk '{print $1}')

echo "Processing sample: $SAMPLE_ID"

# ── Input assembly ────────────────────────────────────────────────────────────
FASTA="$OUT_DIR/02_assembly/fasta/${SAMPLE_ID}.fasta"
if [[ ! -f "$FASTA" ]]; then
    echo "ERROR: Assembly not found for $SAMPLE_ID at $FASTA"
    exit 1
fi

# ── Output directory ──────────────────────────────────────────────────────────
GENOMAD_OUT="$OUT_DIR/05_mobile_amr/genomad/${SAMPLE_ID}"
[[ ! -d "$GENOMAD_OUT" ]] && mkdir -p "$GENOMAD_OUT"

# ── Run geNomad ───────────────────────────────────────────────────────────────
echo "Running geNomad (plasmid mode) for $SAMPLE_ID"
genomad end-to-end \
    "$FASTA" \
    "$GENOMAD_OUT" \
    "$GENOMAD_DB" \
    --threads "$CPUS_GENOMAD" \
    --disable-find-proviruses \
    --cleanup

# ── Sanity check ──────────────────────────────────────────────────────────────
# geNomad places summary outputs in a _summary subdirectory
SUMMARY_DIR="$GENOMAD_OUT/${SAMPLE_ID}_summary"
PLASMID_SUMMARY="$SUMMARY_DIR/${SAMPLE_ID}_plasmid_summary.tsv"

if [[ ! -d "$SUMMARY_DIR" ]]; then
    echo "ERROR: geNomad summary directory not found at $SUMMARY_DIR"
    exit 1
fi

if [[ ! -f "$PLASMID_SUMMARY" ]]; then
    echo "ERROR: geNomad did not produce plasmid summary for $SAMPLE_ID"
    exit 1
fi

# ── Quick summary ─────────────────────────────────────────────────────────────
PLASMID_COUNT=$(tail -n +2 "$PLASMID_SUMMARY" | wc -l)

if [[ "$PLASMID_COUNT" -eq 0 ]]; then
    echo "No plasmids detected for $SAMPLE_ID"
else
    TOTAL_LENGTH=$(tail -n +2 "$PLASMID_SUMMARY" | \
        awk -F'\t' '{sum += $2} END {print sum}')
    echo "geNomad summary for $SAMPLE_ID:"
    echo "  Plasmids detected : $PLASMID_COUNT"
    echo "  Total length (bp) : $TOTAL_LENGTH"
fi

echo "Output written to: $SUMMARY_DIR"
echo "Job done"; date
