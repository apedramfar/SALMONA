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
EXISTING_DIR="$TYPING_DIR/01_existing_schema"
WG_DIR="$EXISTING_DIR/wg_call"
CORE_DIR="$EXISTING_DIR/cgMLST"
CORE_CALL_DIR="$EXISTING_DIR/core_call"
REPORT_DIR="$EXISTING_DIR/report"
MANIFEST="$TYPING_DIR/00_inputs/study_genomes.list"

if [[ ! -s "$MANIFEST" ]]; then
    echo "ERROR: manifest not found at $MANIFEST"
    exit 1
fi

if [[ ! -d "$CHEW_PREPARED_SCHEMA" ]]; then
    echo "ERROR: prepared schema not found at $CHEW_PREPARED_SCHEMA"
    echo "Run bash 07_prep_schema.sh first."
    exit 1
fi

[[ ! -d "$EXISTING_DIR" ]] && mkdir -p "$EXISTING_DIR"

echo "chewBBACA version  : $(chewBBACA.py --version)"
echo "Genomes in manifest: $(wc -l < "$MANIFEST")"
echo "Prepared schema    : $CHEW_PREPARED_SCHEMA"
echo "Prepared loci      : $(find "$CHEW_PREPARED_SCHEMA" -maxdepth 1 -type f -name "*.fasta" | wc -l)"

# ── Step 1: full wgMLST AlleleCall ────────────────────────────────────────────
echo ""
echo "--- Step 1/4: full wgMLST AlleleCall ---"
date

rm -rf "$WG_DIR"
mkdir -p "$WG_DIR"

chewBBACA.py AlleleCall \
    -i "$MANIFEST" \
    -g "$CHEW_PREPARED_SCHEMA" \
    -o "$WG_DIR" \
    --cpu "$SLURM_CPUS_PER_TASK"

WG_RESULTS=$(find "$WG_DIR" -maxdepth 1 -type d -name "results_*" | sort | tail -1)
if [[ -z "$WG_RESULTS" || ! -s "$WG_RESULTS/results_alleles.tsv" ]]; then
    echo "ERROR: wgMLST AlleleCall did not produce results_alleles.tsv"
    exit 1
fi
echo "wgMLST results: $WG_RESULTS"

# ── Step 2: ExtractCgMLST ─────────────────────────────────────────────────────
echo ""
echo "--- Step 2/4: ExtractCgMLST ---"
date

rm -rf "$CORE_DIR"
chewBBACA.py ExtractCgMLST \
    -i "$WG_RESULTS/results_alleles.tsv" \
    -o "$CORE_DIR"

if [[ ! -s "$CORE_DIR/cgMLSTschema95.txt" || ! -s "$CORE_DIR/cgMLST95.tsv" ]]; then
    echo "ERROR: ExtractCgMLST did not produce expected output files"
    exit 1
fi
echo "Study cgMLST95 loci: $(wc -l < "$CORE_DIR/cgMLSTschema95.txt")"

# ── Step 3: core AlleleCall ───────────────────────────────────────────────────
echo ""
echo "--- Step 3/4: core AlleleCall ---"
date

rm -rf "$CORE_CALL_DIR"
mkdir -p "$CORE_CALL_DIR"

chewBBACA.py AlleleCall \
    -i "$MANIFEST" \
    -g "$CHEW_PREPARED_SCHEMA" \
    --gl "$CORE_DIR/cgMLSTschema95.txt" \
    -o "$CORE_CALL_DIR" \
    --cpu "$SLURM_CPUS_PER_TASK"

CORE_RESULTS=$(find "$CORE_CALL_DIR" -maxdepth 1 -type d -name "results_*" | sort | tail -1)
if [[ -z "$CORE_RESULTS" || ! -s "$CORE_RESULTS/results_alleles.tsv" ]]; then
    echo "ERROR: core AlleleCall did not produce results_alleles.tsv"
    exit 1
fi
echo "Core AlleleCall results: $CORE_RESULTS"

# ── Step 4: AlleleCallEvaluator ───────────────────────────────────────────────
echo ""
echo "--- Step 4/4: AlleleCallEvaluator ---"
date

rm -rf "$REPORT_DIR"
chewBBACA.py AlleleCallEvaluator \
    -i "$CORE_RESULTS" \
    -g "$CHEW_PREPARED_SCHEMA" \
    -o "$REPORT_DIR" \
    --cpu "$SLURM_CPUS_PER_TASK"

if [[ ! -d "$REPORT_DIR" ]]; then
    echo "ERROR: AlleleCallEvaluator did not produce report directory"
    exit 1
fi

echo ""
echo "Existing-schema workflow complete"
echo "  Prepared schema : $CHEW_PREPARED_SCHEMA"
echo "  Core loci       : $(wc -l < "$CORE_DIR/cgMLSTschema95.txt")"
echo "  Core results    : $CORE_RESULTS"
echo "  Report          : $REPORT_DIR"
echo "Job done"; date
