#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err

source config.sh

# ── Load environments ─────────────────────────────────────────────────────────
source package $PKG_SPADES
source package $PKG_COVERM
source package $PKG_SEQKIT 

conda activate coverm

echo "Job started"; hostname; date

# ── Parse sample sheet ────────────────────────────────────────────────────────
LINE=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" $SAMPLE_SHEET)
SAMPLE_ID=$(echo "$LINE" | awk '{print $1}')

echo "Processing sample: $SAMPLE_ID"

# ── Input reads from module 01 ────────────────────────────────────────────────
READ1="$OUT_DIR/01_qc/trimming/${SAMPLE_ID}_clean_R1.fq.gz"
READ2="$OUT_DIR/01_qc/trimming/${SAMPLE_ID}_clean_R2.fq.gz"

if [[ ! -f "$READ1" || ! -f "$READ2" ]]; then
    echo "ERROR: Clean reads not found for $SAMPLE_ID. Has 01_qc completed successfully?"
    exit 1
fi

# ── Output directories ────────────────────────────────────────────────────────
ASS_DIR="$OUT_DIR/02_assembly"
FASTA_DIR="$ASS_DIR/fasta"
COVERM_DIR="$ASS_DIR/coverage"
SPADES_TMP="$ASS_DIR/spades_tmp/${SAMPLE_ID}"

[[ ! -d "$FASTA_DIR" ]]   && mkdir -p "$FASTA_DIR"
[[ ! -d "$COVERM_DIR" ]]  && mkdir -p "$COVERM_DIR"
[[ ! -d "$SPADES_TMP" ]]  && mkdir -p "$SPADES_TMP"

# ── SPAdes assembly ───────────────────────────────────────────────────────────
echo "Running SPAdes for $SAMPLE_ID"
spades.py \
    --isolate \
    -1 "$READ1" \
    -2 "$READ2" \
    -o "$SPADES_TMP" \
    --threads $CPUS_ASSEMBLY

if [[ ! -f "$SPADES_TMP/contigs.fasta" ]]; then
    echo "ERROR: SPAdes did not produce contigs.fasta for $SAMPLE_ID"
    exit 1
fi

# ── Filter contigs by minimum length ─────────────────────────────────────────
FILTERED_FASTA="$FASTA_DIR/${SAMPLE_ID}.fasta"

echo "Filtering contigs shorter than ${MIN_CONTIG_LENGTH} bp"
seqkit seq \
    --min-len "$MIN_CONTIG_LENGTH" \
    "$SPADES_TMP/contigs.fasta" \
    -o "$FILTERED_FASTA"

if [[ ! -s "$FILTERED_FASTA" ]]; then
    echo "ERROR: No contigs remaining after length filtering for $SAMPLE_ID"
    exit 1
fi

CONTIG_COUNT=$(seqkit stats -T "$FILTERED_FASTA" | tail -1 | awk -F'\t' '{print $4}')
echo "Contigs after filtering: $CONTIG_COUNT"

# ── Cleanup SPAdes tmp directory ──────────────────────────────────────────────
rm -rf "$SPADES_TMP"
echo "SPAdes tmp directory removed"

# ── CoverM: map reads back to assembly ───────────────────────────────────────
echo "Running CoverM for $SAMPLE_ID"
coverm genome \
    --coupled "$READ1" "$READ2" \
    --genome-fasta-files "$FILTERED_FASTA" \
    -p bwa-mem \
    -m mean relative_abundance covered_fraction \
    --output-file "$COVERM_DIR/${SAMPLE_ID}_coverage.tsv"

if [[ ! -s "$COVERM_DIR/${SAMPLE_ID}_coverage.tsv" ]]; then
    echo "ERROR: CoverM produced no output for $SAMPLE_ID"
    exit 1
fi

echo "Coverage written to: $COVERM_DIR/${SAMPLE_ID}_coverage.tsv"
echo "Job done"; date
