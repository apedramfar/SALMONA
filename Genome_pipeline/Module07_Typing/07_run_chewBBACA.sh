#!/bin/bash -l
source config.sh

echo "=== Module 07 — Typing (chewBBACA + MLST) ==="
echo ""

TYPING_DIR="$OUT_DIR/07_typing"
INPUT_DIR="$TYPING_DIR/00_inputs"
MANIFEST="$INPUT_DIR/study_genomes.list"

[[ ! -d "$INPUT_DIR" ]] && mkdir -p "$INPUT_DIR"
[[ ! -d "$LOG_DIR" ]]   && mkdir -p "$LOG_DIR"

# ── Check schemas and core locus list ─────────────────────────────────────────
for D in "$CHEW_EXISTING_SCHEMA" "$CHEW_CUSTOM_SCHEMA"; do
    if [[ ! -d "$D" ]]; then
        echo "ERROR: schema directory not found: $D"
        exit 1
    fi
done

if [[ ! -s "$CHEW_CUSTOM_CORE" ]]; then
    echo "ERROR: custom core locus list not found: $CHEW_CUSTOM_CORE"
    exit 1
fi

echo "Existing schema loci : $(find "$CHEW_EXISTING_SCHEMA" -maxdepth 1 -type f -name "*.fasta" | wc -l)"
echo "Custom core loci     : $(wc -l < "$CHEW_CUSTOM_CORE")"
echo ""

# ── Collect assemblies from all genome directories ────────────────────────────
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
echo "Assemblies found    : $TOTAL"
echo "Expected Salmonella : $EXPECTED_SALMONELLA"
echo ""

if [[ "$TOTAL" -ne "$EXPECTED_SALMONELLA" ]]; then
    echo "ERROR: assembly count does not match expected Salmonella cohort."
    echo "Remove all non-Salmonella assemblies from the input directories first."
    exit 1
fi

# ── Build manifest ────────────────────────────────────────────────────────────
printf '%s\n' "${FASTA_FILES[@]}" > "$MANIFEST"
echo "Manifest : $MANIFEST ($TOTAL genomes)"
echo ""

# ── Submit 07a: existing schema ───────────────────────────────────────────────
echo "Submitting 07a existing-schema chewBBACA..."
J1=$(sbatch \
    --job-name=07a_chew_existing \
    --partition="$PARTITION_CHEWBBACA" \
    --time="$TIME_CHEWBBACA" \
    --cpus-per-task="$CPUS_CHEWBBACA" \
    --mem-per-cpu="$MEM_PER_CPU_CHEWBBACA" \
    --output="$LOG_DIR/%x_%j.out" \
    --error="$LOG_DIR/%x_%j.err" \
    modules/07a_existing_schema.sh)
echo "$J1"
J1_ID=$(echo "$J1" | awk '{print $NF}')

# ── Submit 07b: custom-320 ────────────────────────────────────────────────────
echo ""
echo "Submitting 07b custom-320 chewBBACA..."
J2=$(sbatch \
    --job-name=07b_chew_custom320 \
    --partition="$PARTITION_CHEWBBACA" \
    --time="$TIME_CHEWBBACA" \
    --cpus-per-task="$CPUS_CHEWBBACA" \
    --mem-per-cpu="$MEM_PER_CPU_CHEWBBACA" \
    --output="$LOG_DIR/%x_%j.out" \
    --error="$LOG_DIR/%x_%j.err" \
    modules/07b_custom320.sh)
echo "$J2"
J2_ID=$(echo "$J2" | awk '{print $NF}')

# ── Submit 07c: MLST ──────────────────────────────────────────────────────────
echo ""
echo "Submitting 07c MLST..."
J3=$(sbatch \
    --job-name=07c_mlst \
    --partition="$PARTITION_MLST" \
    --time="$TIME_MLST" \
    --cpus-per-task="$CPUS_MLST" \
    --mem-per-cpu="$MEM_PER_CPU_MLST" \
    --output="$LOG_DIR/%x_%j.out" \
    --error="$LOG_DIR/%x_%j.err" \
    modules/07c_mlst.sh)
echo "$J3"
J3_ID=$(echo "$J3" | awk '{print $NF}')

# ── Submit 07d: merge ─────────────────────────────────────────────────────────
echo ""
echo "Submitting 07d merge (depends on 07a: $J1_ID, 07b: $J2_ID, 07c: $J3_ID)..."
J4=$(sbatch \
    --job-name=07d_merge \
    --partition="$PARTITION_MERGE_TYPING" \
    --time="$TIME_MERGE_TYPING" \
    --cpus-per-task=2 \
    --mem-per-cpu="4G" \
    --output="$LOG_DIR/%x_%j.out" \
    --error="$LOG_DIR/%x_%j.err" \
    --dependency=afterok:${J1_ID}:${J2_ID}:${J3_ID} \
    modules/07d_merge.sh)
echo "$J4"

echo ""
echo "When complete, run: bash 07_check_chewBBACA.sh"
