#!/bin/bash -l
source config.sh

echo "=== Module 07 — Typing Check ==="
echo ""

TYPING_DIR="$OUT_DIR/07_typing"
AGG_DIR="$OUT_DIR/00_final_results/07_typing"

MISSING=0
EMPTY=0

check_file() {
    local LABEL="$1"
    local FILE="$2"
    if [[ ! -f "$FILE" ]]; then
        echo "MISSING : $LABEL"
        ((MISSING++))
    elif [[ ! -s "$FILE" ]]; then
        echo "EMPTY   : $LABEL"
        ((EMPTY++))
    else
        echo "OK      : $LABEL"
    fi
}

check_dir() {
    local LABEL="$1"
    local DIR="$2"
    if [[ ! -d "$DIR" ]]; then
        echo "MISSING : $LABEL"
        ((MISSING++))
    else
        echo "OK      : $LABEL"
    fi
}

# ── 07_prep_schema ────────────────────────────────────────────────────────────
echo "--- prep schema ---"
check_dir "prepared schema" "$CHEW_PREPARED_SCHEMA"

# ── 07a existing schema ───────────────────────────────────────────────────────
echo ""
echo "--- 07a: existing schema ---"
check_dir  "wgMLST allele call"           "$TYPING_DIR/01_existing_schema/wg_call"
check_file "cgMLST95 locus list"          "$TYPING_DIR/01_existing_schema/cgMLST/cgMLSTschema95.txt"
check_file "cgMLST95 profiles"            "$TYPING_DIR/01_existing_schema/cgMLST/cgMLST95.tsv"
check_dir  "core allele call"             "$TYPING_DIR/01_existing_schema/core_call"
check_dir  "allele call evaluator report" "$TYPING_DIR/01_existing_schema/report"

# ── 07b custom-320 ────────────────────────────────────────────────────────────
echo ""
echo "--- 07b: custom-320 schema ---"
check_dir  "custom-320 allele call"      "$TYPING_DIR/02_custom320/01_core_allele_call"
check_dir  "custom-320 evaluator report" "$TYPING_DIR/02_custom320/02_allelecall_report"

# ── 07c MLST ──────────────────────────────────────────────────────────────────
echo ""
echo "--- 07c: MLST ---"
check_file "MLST results" "$TYPING_DIR/03_mlst/mlst_results.tsv"
check_file "ST summary"   "$TYPING_DIR/03_mlst/st_summary.tsv"

# ── 07d aggregated outputs ────────────────────────────────────────────────────
echo ""
echo "--- 07d: aggregated outputs ---"
check_file "existing schema core profiles" "$AGG_DIR/existing_schema_core_results_alleles.tsv"
check_file "custom-320 core profiles"      "$AGG_DIR/custom320_core_results_alleles.tsv"
check_file "MLST results"                  "$AGG_DIR/mlst_results.tsv"
check_file "ST summary"                    "$AGG_DIR/st_summary.tsv"

# ── MLST cohort summary ───────────────────────────────────────────────────────
if [[ -f "$TYPING_DIR/03_mlst/mlst_results.tsv" ]]; then
    echo ""
    echo "--- MLST cohort summary ---"
    TOTAL_MLST=$(wc -l < "$TYPING_DIR/03_mlst/mlst_results.tsv")
    UNKNOWN_ST=$(awk -F'\t' '$3=="-" {c++} END {print c+0}' \
        "$TYPING_DIR/03_mlst/mlst_results.tsv")
    echo "  Total profiles  : $TOTAL_MLST"
    echo "  Unassigned ST   : $UNKNOWN_ST"
    echo ""
    echo "  Top sequence types:"
    awk -F'\t' '{print $3}' "$TYPING_DIR/03_mlst/mlst_results.tsv" | \
        sort | uniq -c | sort -rn | head -10 | \
        awk '{printf "    ST%-10s : %s samples\n", $2, $1}'
fi

# ── Final status ──────────────────────────────────────────────────────────────
echo ""
echo "=== Summary ==="
echo "  Missing : $MISSING"
echo "  Empty   : $EMPTY"
echo ""

if [[ "$MISSING" -gt 0 || "$EMPTY" -gt 0 ]]; then
    echo "WARNING: Some outputs are missing. Check logs in $LOG_DIR."
else
    echo "All files present. Module 07 complete."
    echo "Final results are in: $OUT_DIR/00_final_results/07_typing/"
fi
