#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err

source config.sh

# ── Load environment ──────────────────────────────────────────────────────────
source package $PKG_CHECKM2
export CHECKM2DB="$CHECKM2DB"

echo "Job started"; hostname; date

# ── Directories ───────────────────────────────────────────────────────────────
FASTA_DIR="$OUT_DIR/02_assembly/fasta"
CHECKM2_DIR="$OUT_DIR/02_assembly/checkm2"
AGG_DIR="$OUT_DIR/00_final_results/02_assembly"

[[ ! -d "$CHECKM2_DIR" ]] && mkdir -p "$CHECKM2_DIR"
[[ ! -d "$AGG_DIR" ]]     && mkdir -p "$AGG_DIR"

cp config.sh $AGG_DIR

# ── Sanity check ──────────────────────────────────────────────────────────────
FASTA_COUNT=$(find "$FASTA_DIR" -name "*.fasta" | wc -l)
if [[ "$FASTA_COUNT" -eq 0 ]]; then
    echo "ERROR: No .fasta files found in $FASTA_DIR"
    exit 1
fi
echo "Found $FASTA_COUNT assemblies to assess"

# ── CheckM2 ───────────────────────────────────────────────────────────────────
echo "Running CheckM2..."
checkm2 predict \
    --threads "$CPUS_CHECKM2" \
    --input "$FASTA_DIR" \
    --extension fasta \
    --output-directory "$CHECKM2_DIR" \
    --force

if [[ ! -f "$CHECKM2_DIR/quality_report.tsv" ]]; then
    echo "ERROR: CheckM2 did not produce quality_report.tsv"
    exit 1
fi
echo "CheckM2 complete"

# ── Merge CoverM outputs ──────────────────────────────────────────────────────
echo "Merging CoverM coverage files..."
COVERM_DIR="$OUT_DIR/02_assembly/coverage"
COVERAGE_MERGED="$AGG_DIR/coverage_summary.tsv"

COVERM_COUNT=$(find "$COVERM_DIR" -name "*_coverage.tsv" | wc -l)
if [[ "$COVERM_COUNT" -eq 0 ]]; then
    echo "ERROR: No CoverM output files found in $COVERM_DIR"
    exit 1
fi

echo -e "sample_id\tmean_coverage" > "$COVERAGE_MERGED"
for cov_file in "$COVERM_DIR"/*_coverage.tsv; do
    sample_id=$(basename "$cov_file" _coverage.tsv)
    # Skip header and unmapped row, extract mean coverage (column 2)
    mean_cov=$(grep -v "^Genome" "$cov_file" | grep -v "^unmapped" | awk -F'\t' '{print $2}')
    echo -e "${sample_id}\t${mean_cov}" >> "$COVERAGE_MERGED"
done

echo "Coverage summary written to $COVERAGE_MERGED"

# ── Copy key outputs to aggregated folder ─────────────────────────────────────
cp "$CHECKM2_DIR/quality_report.tsv" "$AGG_DIR/checkm2_quality_report.tsv"
echo "CheckM2 report copied to $AGG_DIR/checkm2_quality_report.tsv"

echo ""
echo "======================================================================"
echo "Assembly QC outputs ready in: $AGG_DIR"
echo ""
echo "Key outputs:"
echo "  CheckM2 report  : $AGG_DIR/checkm2_quality_report.tsv"
echo "  Coverage summary: $COVERAGE_MERGED"
echo ""
echo "Review assembly quality, then run: bash 02_check_assembly.sh"
echo "======================================================================"

echo "Job done"; date
