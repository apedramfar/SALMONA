#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err

source config.sh

# ── Load environment ──────────────────────────────────────────────────────────
source package $PKG_BAKTA

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
BAKTA_DIR="$OUT_DIR/03_annotation/bakta/${SAMPLE_ID}"
[[ ! -d "$BAKTA_DIR" ]] && mkdir -p "$BAKTA_DIR"

# ── Build genus/species flags ─────────────────────────────────────────────────
# If BAKTA_SPECIES is "mixed" or empty, skip taxonomy flags entirely
TAXON_FLAGS=""
if [[ -n "$BAKTA_SPECIES" && "$BAKTA_SPECIES" != "mixed" ]]; then
    GENUS=$(echo "$BAKTA_SPECIES" | awk '{print $1}')
    SPECIES=$(echo "$BAKTA_SPECIES" | awk '{print $2}')
    if [[ -n "$GENUS" ]];   then TAXON_FLAGS="$TAXON_FLAGS --genus $GENUS";     fi
    if [[ -n "$SPECIES" ]]; then TAXON_FLAGS="$TAXON_FLAGS --species $SPECIES"; fi
    echo "Taxon flags: $TAXON_FLAGS"
else
    echo "BAKTA_SPECIES=mixed — running without genus/species flags"
fi

# ── Run Bakta ─────────────────────────────────────────────────────────────────
echo "Running Bakta for $SAMPLE_ID"
bakta \
    --db "$BAKTA_DB" \
    --output "$BAKTA_DIR" \
    --prefix "$SAMPLE_ID" \
    --threads "$CPUS_BAKTA" \
    --force \
    $TAXON_FLAGS \
    "$FASTA"

# ── Sanity checks ─────────────────────────────────────────────────────────────
GFF="$BAKTA_DIR/${SAMPLE_ID}.gff3"
FAA="$BAKTA_DIR/${SAMPLE_ID}.faa"

if [[ ! -s "$GFF" ]]; then
    echo "ERROR: Bakta did not produce .gff3 for $SAMPLE_ID"
    exit 1
fi
if [[ ! -s "$FAA" ]]; then
    echo "ERROR: Bakta did not produce .faa for $SAMPLE_ID"
    exit 1
fi

# ── Quick annotation stats from Bakta TSV ─────────────────────────────────────
TSV="$BAKTA_DIR/${SAMPLE_ID}.tsv"
if [[ -f "$TSV" ]]; then
    TOTAL_FEATURES=$(tail -n +2 "$TSV" | wc -l)
    CDS_COUNT=$(tail -n +2 "$TSV" | awk -F'\t' '$2=="CDS"' | wc -l)
    HYPOTHETICAL=$(tail -n +2 "$TSV" | awk -F'\t' '$2=="CDS" && $9~/hypothetical/' | wc -l)
    echo "Annotation summary for $SAMPLE_ID:"
    echo "  Total features  : $TOTAL_FEATURES"
    echo "  CDS             : $CDS_COUNT"
    echo "  Hypothetical    : $HYPOTHETICAL"
fi

echo "Bakta output written to: $BAKTA_DIR"
echo "Job done"; date
