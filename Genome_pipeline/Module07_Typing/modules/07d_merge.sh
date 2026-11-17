#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

source config.sh

echo "Job started"; hostname; date

TYPING_DIR="$OUT_DIR/07_typing"
AGG_DIR="$OUT_DIR/00_final_results/07_typing"
[[ ! -d "$AGG_DIR" ]] && mkdir -p "$AGG_DIR"

# ── Copy chewBBACA existing schema core profiles ──────────────────────────────
echo "Copying chewBBACA existing schema output..."
EXISTING_RESULTS=$(find "$TYPING_DIR/01_existing_schema/core_call" \
    -maxdepth 2 -type f -name "results_alleles.tsv" | sort | tail -1)
if [[ -s "$EXISTING_RESULTS" ]]; then
    cp "$EXISTING_RESULTS" "$AGG_DIR/existing_schema_core_results_alleles.tsv"
    echo "  existing schema core profiles copied"
else
    echo "  WARNING: existing schema results_alleles.tsv not found"
fi

# ── Copy chewBBACA custom-320 core profiles ───────────────────────────────────
echo "Copying chewBBACA custom-320 output..."
CUSTOM_RESULTS=$(find "$TYPING_DIR/02_custom320/01_core_allele_call" \
    -maxdepth 2 -type f -name "results_alleles.tsv" | sort | tail -1)
if [[ -s "$CUSTOM_RESULTS" ]]; then
    cp "$CUSTOM_RESULTS" "$AGG_DIR/custom320_core_results_alleles.tsv"
    echo "  custom-320 core profiles copied"
else
    echo "  WARNING: custom-320 results_alleles.tsv not found"
fi

# ── Copy MLST outputs ─────────────────────────────────────────────────────────
echo "Copying MLST outputs..."
for FILE in \
    "$TYPING_DIR/03_mlst/mlst_results.tsv" \
    "$TYPING_DIR/03_mlst/st_summary.tsv"; do
    if [[ -s "$FILE" ]]; then
        cp "$FILE" "$AGG_DIR/$(basename $FILE)"
        echo "  $(basename $FILE) copied"
    else
        echo "  WARNING: $(basename $FILE) not found"
    fi
done

echo ""
echo "======================================================================"
echo "Module 07 outputs ready in: $AGG_DIR"
echo ""
echo "Key outputs:"
echo "  existing schema profiles : $AGG_DIR/existing_schema_core_results_alleles.tsv"
echo "  custom-320 profiles      : $AGG_DIR/custom320_core_results_alleles.tsv"
echo "  MLST results             : $AGG_DIR/mlst_results.tsv"
echo "  ST summary               : $AGG_DIR/st_summary.tsv"
echo ""
echo "Review outputs, then run: bash 07_check_chewBBACA.sh"
echo "======================================================================"

echo "Job done"; date
