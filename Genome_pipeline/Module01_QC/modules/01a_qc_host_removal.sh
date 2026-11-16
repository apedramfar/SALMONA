#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err

source config.sh

# ── Load environments ─────────────────────────────────────────────────────────
source package $PKG_HOSTILE
source package $PKG_TRIMGALORE

export HOSTILE_CACHE_DIR=$HOSTILE_CACHE_DIR

echo "Job started"; hostname; date

# ── Parse sample sheet ────────────────────────────────────────────────────────
LINE=$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" $SAMPLE_SHEET)
SAMPLE_ID=$(echo "$LINE" | awk '{print $1}')
READ1=$(echo "$LINE"    | awk '{print $2}')
READ2=$(echo "$LINE"    | awk '{print $3}')

echo "Processing sample: $SAMPLE_ID"

# ── Output directories ────────────────────────────────────────────────────────
QC_DIR="$OUT_DIR/01_qc"
HOST_DIR="$QC_DIR/host_removal"
TRIM_DIR="$QC_DIR/trimming"
FASTQC_DIR="$QC_DIR/fastqc"

[[ ! -d "$HOST_DIR" ]]   && mkdir -p "$HOST_DIR"
[[ ! -d "$TRIM_DIR" ]]   && mkdir -p "$TRIM_DIR"
[[ ! -d "$FASTQC_DIR" ]] && mkdir -p "$FASTQC_DIR"
[[ ! -d "$LOG_DIR" ]]    && mkdir -p "$LOG_DIR"

# ── Host index selection ──────────────────────────────────────────────────────
case "$HOST_REF" in
  human) INDEX="human-t2t-hla" ;;
  mouse) INDEX="mouse-mm39" ;;
  *)
    echo "ERROR: Unknown HOST_REF '$HOST_REF'. Choose: human, mouse"
    exit 1
    ;;
esac

# ── Host removal with Hostile ─────────────────────────────────────────────────
HOSTILE_R1="$HOST_DIR/${SAMPLE_ID}_hostremoved_R1.fastq.gz"
HOSTILE_R2="$HOST_DIR/${SAMPLE_ID}_hostremoved_R2.fastq.gz"
HOSTILE_LOG="$HOST_DIR/${SAMPLE_ID}_hostmap.json"

echo "Running Hostile with index: $INDEX"
hostile clean \
  --fastq1 "$READ1" \
  --fastq2 "$READ2" \
  --index "$INDEX" \
  --output "$HOST_DIR" \
  --airplane \
  > "$HOSTILE_LOG"

# ── Rename Hostile outputs to consistent naming scheme ────────────────────────
BASE1=$(basename "$READ1" .fastq.gz)
BASE2=$(basename "$READ2" .fastq.gz)
mv "$HOST_DIR/${BASE1}.clean_1.fastq.gz" "$HOSTILE_R1"
mv "$HOST_DIR/${BASE2}.clean_2.fastq.gz" "$HOSTILE_R2"

# ── Trimming + FastQC with TrimGalore ─────────────────────────────────────────
TMPDIR="$TRIM_DIR/tmp_${SAMPLE_ID}"
mkdir -p "$TMPDIR"
export TMPDIR

TYPE_LOWER=$(echo "$TYPE" | tr '[:upper:]' '[:lower:]')

echo "Running TrimGalore ($TYPE_LOWER)"

if [[ "$TYPE_LOWER" == "mgi" ]]; then
    trim_galore --paired \
        -o "$TRIM_DIR" \
        -a GCTCACAGAACGACATGGCTACGATCCGACTT \
        -a2 TTGTCTTCCTAAGACCGCTTGGCCTCCGACTT \
        --fastqc --fastqc_args "-d $TMPDIR" \
        "$HOSTILE_R1" "$HOSTILE_R2"

elif [[ "$TYPE_LOWER" == "illumina" ]]; then
    trim_galore --paired \
        -o "$TRIM_DIR" \
        --fastqc --fastqc_args "-d $TMPDIR" \
        "$HOSTILE_R1" "$HOSTILE_R2"

else
    echo "ERROR: Unknown TYPE '$TYPE'. Choose: illumina or mgi"
    exit 1
fi

# ── Organise trimmed outputs ──────────────────────────────────────────────────
BASE_HR1=$(basename "$HOSTILE_R1" .fastq.gz)
BASE_HR2=$(basename "$HOSTILE_R2" .fastq.gz)

CLEAN_R1="$TRIM_DIR/${SAMPLE_ID}_clean_R1.fq.gz"
CLEAN_R2="$TRIM_DIR/${SAMPLE_ID}_clean_R2.fq.gz"

mv "$TRIM_DIR/${BASE_HR1}_val_1.fq.gz" "$CLEAN_R1"
mv "$TRIM_DIR/${BASE_HR2}_val_2.fq.gz" "$CLEAN_R2"

# ── Organise FastQC and trimming reports ──────────────────────────────────────
mv "$TRIM_DIR/${BASE_HR1}_val_1_fastqc.html"         "$FASTQC_DIR/${SAMPLE_ID}_R1_fastqc.html"         2>/dev/null
mv "$TRIM_DIR/${BASE_HR2}_val_2_fastqc.html"         "$FASTQC_DIR/${SAMPLE_ID}_R2_fastqc.html"         2>/dev/null
mv "$TRIM_DIR/${BASE_HR1}_val_1_fastqc.zip"          "$FASTQC_DIR/${SAMPLE_ID}_R1_fastqc.zip"          2>/dev/null
mv "$TRIM_DIR/${BASE_HR2}_val_2_fastqc.zip"          "$FASTQC_DIR/${SAMPLE_ID}_R2_fastqc.zip"          2>/dev/null
mv "$TRIM_DIR/${BASE_HR1}_trimming_report.txt"       "$FASTQC_DIR/${SAMPLE_ID}_R1_trimming_report.txt" 2>/dev/null
mv "$TRIM_DIR/${BASE_HR2}_trimming_report.txt"       "$FASTQC_DIR/${SAMPLE_ID}_R2_trimming_report.txt" 2>/dev/null

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -f "$HOSTILE_R1" "$HOSTILE_R2"
rm -rf "$TMPDIR"

echo "Clean reads: $CLEAN_R1 / $CLEAN_R2"
echo "Job done"; date
