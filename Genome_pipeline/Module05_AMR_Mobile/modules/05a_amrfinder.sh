#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err

source config.sh

# ── Load environment ──────────────────────────────────────────────────────────
source package "$PKG_AMRFINDER"

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
AMR_DIR="$OUT_DIR/05_mobile_amr/amrfinder"
[[ ! -d "$AMR_DIR" ]] && mkdir -p "$AMR_DIR"

# ── Build organism flag ───────────────────────────────────────────────────────
ORGANISM_FLAG=""
if [[ -n "$AMRFINDER_ORGANISM" && "$AMRFINDER_ORGANISM" != "mixed" ]]; then
    ORGANISM_FLAG="--organism $AMRFINDER_ORGANISM"
    echo "Organism flag: $ORGANISM_FLAG"
else
    echo "AMRFINDER_ORGANISM=mixed — running without organism flag"
fi

# ── Run AMRfinderplus ─────────────────────────────────────────────────────────
echo "Running AMRfinderplus for $SAMPLE_ID"
amrfinder \
    --nucleotide "$FASTA" \
    --database "$AMRFINDER_DB" \
    --threads "$CPUS_AMRFINDER" \
    --plus \
    $ORGANISM_FLAG \
    --output "$AMR_DIR/${SAMPLE_ID}_amrfinder.tsv"

# ── Sanity check ──────────────────────────────────────────────────────────────
if [[ ! -f "$AMR_DIR/${SAMPLE_ID}_amrfinder.tsv" ]]; then
    echo "ERROR: AMRfinderplus did not produce output for $SAMPLE_ID"
    exit 1
fi

# ── Quick summary ─────────────────────────────────────────────────────────────
# AMRfinderplus output has a header line; count findings by type
TOTAL=$(tail -n +2 "$AMR_DIR/${SAMPLE_ID}_amrfinder.tsv" | wc -l)
AMR_COUNT=$(tail -n +2 "$AMR_DIR/${SAMPLE_ID}_amrfinder.tsv" | \
    awk -F'\t' '$9=="AMR"' | wc -l)
VIRULENCE_COUNT=$(tail -n +2 "$AMR_DIR/${SAMPLE_ID}_amrfinder.tsv" | \
    awk -F'\t' '$9=="VIRULENCE"' | wc -l)
STRESS_COUNT=$(tail -n +2 "$AMR_DIR/${SAMPLE_ID}_amrfinder.tsv" | \
    awk -F'\t' '$9=="STRESS"' | wc -l)

echo "AMRfinderplus summary for $SAMPLE_ID:"
echo "  Total findings  : $TOTAL"
echo "  AMR genes       : $AMR_COUNT"
echo "  Virulence genes : $VIRULENCE_COUNT"
echo "  Stress genes    : $STRESS_COUNT"

echo "Output written to: $AMR_DIR/${SAMPLE_ID}_amrfinder.tsv"
echo "Job done"; date
