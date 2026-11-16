#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err

source config.sh

echo "Job started"; hostname; date

# ── Directories ───────────────────────────────────────────────────────────────
DREP_DIR="$OUT_DIR/03_annotation/drep"
BAKTA_DIR="$OUT_DIR/03_annotation/bakta"
AGG_DIR="$OUT_DIR/00_final_results/03_annotation"
AGG_BAKTA_GFF="$AGG_DIR/gff3"
AGG_BAKTA_FAA="$AGG_DIR/faa"

[[ ! -d "$AGG_DIR" ]]          && mkdir -p "$AGG_DIR"
[[ ! -d "$AGG_BAKTA_GFF" ]]    && mkdir -p "$AGG_BAKTA_GFF"
[[ ! -d "$AGG_BAKTA_FAA" ]]    && mkdir -p "$AGG_BAKTA_FAA"

cp config.sh $AGG_DIR

# ── Copy dRep clustering results ──────────────────────────────────────────────
echo "Copying dRep results..."

if [[ ! -f "$DREP_DIR/data_tables/Cdb.csv" || ! -f "$DREP_DIR/data_tables/Widb.csv" ]]; then
    echo "ERROR: dRep output tables not found. Has 03a completed successfully?"
    exit 1
fi

cp "$DREP_DIR/data_tables/Cdb.csv"  "$AGG_DIR/drep_clusters.csv"
cp "$DREP_DIR/data_tables/Widb.csv" "$AGG_DIR/drep_representatives.csv"
echo "  drep_clusters.csv copied"
echo "  drep_representatives.csv copied"

# ── Copy Bakta outputs ────────────────────────────────────────────────────────
echo "Copying Bakta annotation outputs..."
GFF_COUNT=0
FAA_COUNT=0

while IFS=$'\t' read -r SAMPLE_ID READ1 READ2; do
    [[ "$SAMPLE_ID" == "sample_id" ]] && continue

    GFF="$BAKTA_DIR/${SAMPLE_ID}/${SAMPLE_ID}.gff3"
    FAA="$BAKTA_DIR/${SAMPLE_ID}/${SAMPLE_ID}.faa"

    if [[ -f "$GFF" ]]; then
        cp "$GFF" "$AGG_BAKTA_GFF/${SAMPLE_ID}.gff3"
        ((GFF_COUNT++))
    else
        echo "  WARNING: missing .gff3 for $SAMPLE_ID"
    fi

    if [[ -f "$FAA" ]]; then
        cp "$FAA" "$AGG_BAKTA_FAA/${SAMPLE_ID}.faa"
        ((FAA_COUNT++))
    else
        echo "  WARNING: missing .faa for $SAMPLE_ID"
    fi

done < "$SAMPLE_SHEET"

echo "  $GFF_COUNT .gff3 files copied"
echo "  $FAA_COUNT .faa files copied"

# ── Build combined summary table ──────────────────────────────────────────────
# Combines CheckM2 quality + coverage + dRep cluster assignment per sample
echo "Building combined summary table..."

CHECKM2_REPORT="$OUT_DIR/00_final_results/02_assembly/checkm2_quality_report.tsv"
COVERAGE_SUMMARY="$OUT_DIR/00_final_results/02_assembly/coverage_summary.tsv"
CDB="$AGG_DIR/drep_clusters.csv"
WIDB="$AGG_DIR/drep_representatives.csv"
SUMMARY="$AGG_DIR/assembly_annotation_summary.tsv"

if [[ ! -f "$CHECKM2_REPORT" ]]; then
    echo "ERROR: CheckM2 report not found at $CHECKM2_REPORT"
    exit 1
fi
if [[ ! -f "$COVERAGE_SUMMARY" ]]; then
    echo "ERROR: Coverage summary not found at $COVERAGE_SUMMARY"
    exit 1
fi

# Load coverage into associative array
declare -A COVERAGE
while IFS=$'\t' read -r sample_id mean_cov; do
    [[ "$sample_id" == "sample_id" ]] && continue
    COVERAGE["$sample_id"]="$mean_cov"
done < "$COVERAGE_SUMMARY"

# Load dRep cluster assignments into associative array
# Cdb.csv columns: genome, secondary_cluster (and others)
declare -A DREP_CLUSTER
declare -A DREP_REP
while IFS=',' read -r genome cluster rest; do
    [[ "$genome" == "genome" ]] && continue
    sample_id=$(basename "$genome" .fasta)
    DREP_CLUSTER["$sample_id"]="$cluster"
done < "$CDB"

# Load dRep representatives
while IFS=',' read -r genome rest; do
    [[ "$genome" == "genome" ]] && continue
    sample_id=$(basename "$genome" .fasta)
    DREP_REP["$sample_id"]="yes"
done < "$WIDB"

# Write summary
echo -e "sample_id\tcompleteness\tcontamination\tcontig_n50\tmean_coverage\tdrep_cluster\tdrep_representative" \
    > "$SUMMARY"


tail -n +2 "$CHECKM2_REPORT" | while IFS=$'\t' read -r name completeness contamination model transl coding_density n50 rest; do
    mean_cov="${COVERAGE[$name]:-NA}"
    cluster="${DREP_CLUSTER[$name]:-NA}"
    is_rep="${DREP_REP[$name]:-no}"
    echo -e "${name}\t${completeness}\t${contamination}\t${n50}\t${mean_cov}\t${cluster}\t${is_rep}"
done >> "$SUMMARY"

echo "Combined summary written to $SUMMARY"

echo ""
echo "======================================================================"
echo "Final annotation outputs ready in: $AGG_DIR"
echo ""
echo "Key outputs:"
echo "  dRep clusters       : $AGG_DIR/drep_clusters.csv"
echo "  dRep representatives: $AGG_DIR/drep_representatives.csv"
echo "  GFF3 annotations    : $AGG_BAKTA_GFF/"
echo "  FAA protein seqs    : $AGG_BAKTA_FAA/"
echo "  Combined summary    : $SUMMARY"
echo ""
echo "Review outputs, then run: bash 03_check_annotation.sh"
echo "======================================================================"

echo "Job done"; date
