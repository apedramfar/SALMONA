#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

source config.sh

set +eu
source package $PKG_CHEWBBACA
set -eu

echo "Job started"; hostname; date

TYPING_DIR="$OUT_DIR/07_typing"
CUSTOM_DIR="$TYPING_DIR/02_custom320"
CUSTOM_CALL_DIR="$CUSTOM_DIR/01_core_allele_call"
CUSTOM_REPORT_DIR="$CUSTOM_DIR/02_allelecall_report"
MANIFEST="$TYPING_DIR/00_inputs/study_genomes.list"

if [[ ! -s "$MANIFEST" ]]; then
    echo "ERROR: manifest not found at $MANIFEST"
    exit 1
fi

if [[ ! -s "$CHEW_CUSTOM_CORE" ]]; then
    echo "ERROR: custom core locus list not found at $CHEW_CUSTOM_CORE"
    exit 1
fi

echo "chewBBACA version: $(chewBBACA.py --version)"
echo "Genomes in manifest: $(wc -l < "$MANIFEST")"
echo "Custom schema: $CHEW_CUSTOM_SCHEMA"
echo "Custom core loci: $(wc -l < "$CHEW_CUSTOM_CORE")"

# ── Step 1: custom-320 AlleleCall ─────────────────────────────────────────────
echo ""
echo "--- Step 1/2: custom-320 AlleleCall ---"
date

rm -rf "$CUSTOM_CALL_DIR"
mkdir -p "$CUSTOM_CALL_DIR"

chewBBACA.py AlleleCall \
    -i "$MANIFEST" \
    -g "$CHEW_CUSTOM_SCHEMA" \
    --gl "$CHEW_CUSTOM_CORE" \
    -o "$CUSTOM_CALL_DIR" \
    --cpu "$SLURM_CPUS_PER_TASK"

CUSTOM_RESULTS=$(find "$CUSTOM_CALL_DIR" -maxdepth 1 -type d -name "results_*" | sort | tail -1)
if [[ -z "$CUSTOM_RESULTS" || ! -s "$CUSTOM_RESULTS/results_alleles.tsv" ]]; then
    echo "ERROR: custom-320 AlleleCall did not produce results_alleles.tsv"
    exit 1
fi
echo "Custom-320 results: $CUSTOM_RESULTS"
echo "Profiles: $(( $(wc -l < "$CUSTOM_RESULTS/results_alleles.tsv") - 1 ))"

# ── Step 2: AlleleCallEvaluator ───────────────────────────────────────────────
echo ""
echo "--- Step 2/2: AlleleCallEvaluator ---"
date

rm -rf "$CUSTOM_REPORT_DIR"
chewBBACA.py AlleleCallEvaluator \
    -i "$CUSTOM_RESULTS" \
    -g "$CHEW_CUSTOM_SCHEMA" \
    -o "$CUSTOM_REPORT_DIR" \
    --cpu "$SLURM_CPUS_PER_TASK"

if [[ ! -d "$CUSTOM_REPORT_DIR" ]]; then
    echo "ERROR: AlleleCallEvaluator did not produce report directory"
    exit 1
fi

echo ""
echo "Custom-320 workflow complete"
echo "  Results : $CUSTOM_RESULTS"
echo "  Report  : $CUSTOM_REPORT_DIR"
echo "Job done"; date
