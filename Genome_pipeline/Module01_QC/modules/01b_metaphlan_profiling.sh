#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err

source config.sh

# ── Load environment ──────────────────────────────────────────────────────────
source package $PKG_METAPHLAN

echo "Job started"; hostname; date

# ── Parse sample sheet ────────────────────────────────────────────────────────
LINE=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" $SAMPLE_SHEET)
SAMPLE_ID=$(echo "$LINE" | awk '{print $1}')

echo "Processing sample: $SAMPLE_ID"

# ── Input reads from module 01a ───────────────────────────────────────────────
READ1="$OUT_DIR/01_qc/trimming/${SAMPLE_ID}_clean_R1.fq.gz"
READ2="$OUT_DIR/01_qc/trimming/${SAMPLE_ID}_clean_R2.fq.gz"

if [[ ! -f "$READ1" || ! -f "$READ2" ]]; then
    echo "ERROR: Clean reads not found for $SAMPLE_ID. Has 01a completed successfully?"
    exit 1
fi

# ── Output directory ──────────────────────────────────────────────────────────
MET_DIR="$OUT_DIR/01_qc/metaphlan"
[[ ! -d "$MET_DIR" ]] && mkdir -p "$MET_DIR"

# ── MetaPhlAn4: initial run to generate bowtie2out + sam ─────────────────────
echo "Running MetaPhlAn4 for $SAMPLE_ID"
metaphlan $READ1,$READ2 \
    --input_type fastq \
    --nproc $CPUS_METAPHLAN \
    -x mpa_vJun23_CHOCOPhlAnSGB_202403 \
    --bowtie2db $MET_DB \
    -t rel_ab \
    --bowtie2out $MET_DIR/${SAMPLE_ID}.bowtie2out \
    --samout $MET_DIR/${SAMPLE_ID}.sam.bz2 \
    -o $MET_DIR/${SAMPLE_ID}.profile.txt

# ── MetaPhlAn4: re-run from bowtie2out with unclassified estimation ───────────
echo "Running MetaPhlAn4 with unclassified estimation for $SAMPLE_ID"
metaphlan $MET_DIR/${SAMPLE_ID}.bowtie2out \
    --input_type bowtie2out \
    --nproc $CPUS_METAPHLAN \
    --unclassified_estimation \
    -x mpa_vJun23_CHOCOPhlAnSGB_202403 \
    --bowtie2db $MET_DB \
    -o $MET_DIR/${SAMPLE_ID}.unclprofile.txt

# ── Sanity check before cleanup ───────────────────────────────────────────────
if [[ ! -s "$MET_DIR/${SAMPLE_ID}.unclprofile.txt" ]]; then
    echo "ERROR: MetaPhlAn unclassified profile is empty or missing for $SAMPLE_ID"
    exit 1
fi

# ── Cleanup intermediate files ────────────────────────────────────────────────
rm -f "$MET_DIR/${SAMPLE_ID}.bowtie2out"
rm -f "$MET_DIR/${SAMPLE_ID}.sam.bz2"
rm -f "$MET_DIR/${SAMPLE_ID}.profile.txt"

echo "MetaPhlAn profile written to: $MET_DIR/${SAMPLE_ID}.unclprofile.txt"
echo "Job done"; date
