#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err

source config.sh

# ── Load environment ──────────────────────────────────────────────────────────
source package $PKG_DREP

echo "Job started"; hostname; date

# ── Directories ───────────────────────────────────────────────────────────────
FASTA_DIR="$OUT_DIR/02_assembly/fasta"
DREP_DIR="$OUT_DIR/03_annotation/drep"
CHECKM2_REPORT="$OUT_DIR/00_final_results/02_assembly/checkm2_quality_report.tsv"

[[ ! -d "$DREP_DIR" ]] && mkdir -p "$DREP_DIR"

# ── Sanity checks ─────────────────────────────────────────────────────────────
FASTA_COUNT=$(find "$FASTA_DIR" -name "*.fasta" | wc -l)
if [[ "$FASTA_COUNT" -eq 0 ]]; then
    echo "ERROR: No .fasta files found in $FASTA_DIR"
    exit 1
fi
echo "Found $FASTA_COUNT assemblies for dereplication"

if [[ ! -f "$CHECKM2_REPORT" ]]; then
    echo "ERROR: CheckM2 report not found at $CHECKM2_REPORT"
    exit 1
fi

# ── Reformat CheckM2 report for dRep ─────────────────────────────────────────
# dRep expects: genome (basename of .fasta), completeness, contamination
# CheckM2 produces: Name, Completeness, Contamination, ... (TSV, title case)
GENOME_INFO="$DREP_DIR/genome_info.csv"
echo "genome,completeness,contamination" > "$GENOME_INFO"

tail -n +2 "$CHECKM2_REPORT" | awk -F'\t' \
    '{print $1".fasta,"$2","$3}' >> "$GENOME_INFO"

echo "Genome info file written to $GENOME_INFO"

# ── Run dRep ──────────────────────────────────────────────────────────────────
# Pass full paths to --genomes; genome_info uses basenames as required by dRep
echo "Running dRep with ANI threshold: $DREP_ANI"
dRep dereplicate \
    "$DREP_DIR" \
    --genomes "$FASTA_DIR"/*.fasta \
    --genomeInfo "$GENOME_INFO" \
    --S_ani "$DREP_ANI" \
    --processors "$CPUS_DREP"

# ── Sanity check outputs ──────────────────────────────────────────────────────
if [[ ! -f "$DREP_DIR/data_tables/Cdb.csv" ]]; then
    echo "ERROR: dRep did not produce Cdb.csv (cluster assignments)"
    exit 1
fi
if [[ ! -f "$DREP_DIR/data_tables/Widb.csv" ]]; then
    echo "ERROR: dRep did not produce Widb.csv (winner genomes)"
    exit 1
fi

# ── Summary ───────────────────────────────────────────────────────────────────
TOTAL_GENOMES=$(tail -n +2 "$DREP_DIR/data_tables/Cdb.csv" | wc -l)
TOTAL_CLUSTERS=$(tail -n +2 "$DREP_DIR/data_tables/Cdb.csv" | \
    awk -F',' '{print $2}' | sort -u | wc -l)
REPRESENTATIVES=$(tail -n +2 "$DREP_DIR/data_tables/Widb.csv" | wc -l)

echo ""
echo "======================================================================"
echo "dRep complete"
echo "  Total genomes    : $TOTAL_GENOMES"
echo "  Total clusters   : $TOTAL_CLUSTERS"
echo "  Representatives  : $REPRESENTATIVES"
echo "  ANI threshold    : $DREP_ANI"
echo ""
echo "Cluster assignments : $DREP_DIR/data_tables/Cdb.csv"
echo "Winner genomes      : $DREP_DIR/data_tables/Widb.csv"
echo "======================================================================"

echo "Job done"; date
