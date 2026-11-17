#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

source config.sh

set +eu
source package $PKG_MLST
set -eu

echo "Job started"; hostname; date

TYPING_DIR="$OUT_DIR/07_typing"
MLST_DIR="$TYPING_DIR/03_mlst"
[[ ! -d "$MLST_DIR" ]] && mkdir -p "$MLST_DIR"

echo "mlst version: $(mlst --version 2>&1 || true)"
echo "MLST scheme : $MLST_SCHEME"

# ── Sanity checks ─────────────────────────────────────────────────────────────
if [[ ! -d "$MLST_DATADIR/$MLST_SCHEME" ]]; then
    echo "ERROR: scheme directory not found: $MLST_DATADIR/$MLST_SCHEME"
    exit 1
fi

if [[ ! -f "$MLST_BLASTDB" ]]; then
    echo "ERROR: BLAST FASTA not found: $MLST_BLASTDB"
    exit 1
fi

# ── Collect assemblies ────────────────────────────────────────────────────────
FASTA_FILES=()
IFS=';' read -ra DIRS <<< "$GENOME_DIR"
for DIR in "${DIRS[@]}"; do
    if [[ ! -d "$DIR" ]]; then
        echo "ERROR: genome directory not found: $DIR"
        exit 1
    fi
    while IFS= read -r F; do
        FASTA_FILES+=("$F")
    done < <(find "$DIR" -maxdepth 1 -type f -name "*.fasta" | sort)
done

TOTAL="${#FASTA_FILES[@]}"
echo "Assemblies found : $TOTAL"

if [[ "$TOTAL" -ne "$EXPECTED_SALMONELLA" ]]; then
    echo "ERROR: found $TOTAL assemblies but expected $EXPECTED_SALMONELLA"
    exit 1
fi

# ── Run MLST ──────────────────────────────────────────────────────────────────
echo ""
echo "Running MLST on $TOTAL assemblies..."
mlst \
    --datadir "$MLST_DATADIR" \
    --blastdb "$MLST_BLASTDB" \
    --scheme "$MLST_SCHEME" \
    "${FASTA_FILES[@]}" \
    > "$MLST_DIR/mlst_results.tsv"

if [[ ! -s "$MLST_DIR/mlst_results.tsv" ]]; then
    echo "ERROR: mlst_results.tsv is missing or empty"
    exit 1
fi

# ── ST summary ────────────────────────────────────────────────────────────────
echo -e "ST\tcount" > "$MLST_DIR/st_summary.tsv"
awk -F'\t' '{print $3}' "$MLST_DIR/mlst_results.tsv" | \
    sort | uniq -c | sort -rn | \
    awk '{print $2"\t"$1}' >> "$MLST_DIR/st_summary.tsv"

echo ""
echo "MLST complete"
echo "  Total profiles : $TOTAL"
echo "  Unassigned ST  : $(awk -F'\t' '$3=="-" {c++} END {print c+0}' "$MLST_DIR/mlst_results.tsv")"
echo "  Results        : $MLST_DIR/mlst_results.tsv"
echo "Job done"; date
