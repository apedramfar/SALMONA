#!/bin/bash -l

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/config.sh"

echo "=== Module 06 Check ==="
echo ""

FAIL=0

check_file () {
    local LABEL="$1" FILE="$2"
    if [[ -s "$FILE" ]]; then
        echo "FOUND   : $LABEL"
    else
        echo "MISSING : $LABEL"
        echo "          $FILE"
        FAIL=$((FAIL+1))
    fi
}

echo "--- 06A PHORAGER ---"
check_file "PHORAGER filtered prophages" "$PHORAGER_FILTERED_FASTA"

PROPHAGE_TABLE=$(find "$PHORAGER_DIR" -type f -name "prophage_table.tsv" -print -quit)
if [[ -n "$PROPHAGE_TABLE" ]]; then
    check_file "PHORAGER prophage_table.tsv" "$PROPHAGE_TABLE"
else
    echo "MISSING : PHORAGER prophage_table.tsv"
    FAIL=$((FAIL+1))
fi

echo ""
echo "--- 06A → 06B handoff ---"
check_file "vConTACT3 handoff FASTA" "$VCONTACT3_INPUT"
check_file "handoff summary" "$HANDOFF_DIR/handoff_summary.tsv"

if [[ -s "$VCONTACT3_INPUT" ]]; then
    echo "Sequences in handoff: $(grep -c '^>' "$VCONTACT3_INPUT" || true)"
fi

echo ""
echo "--- 06B vConTACT3 ---"

ASSIGNMENTS="$VCONTACT3_DIR/exports/final_assignments.csv"
[[ -f "$ASSIGNMENTS" ]] || ASSIGNMENTS="$VCONTACT3_DIR/final_assignments.csv"
check_file "final_assignments.csv" "$ASSIGNMENTS"

GRAPHML=$(find "$VCONTACT3_DIR" -type f -name "*.graphml" | wc -l)
CYJS=$(find "$VCONTACT3_DIR" -type f -name "*.cyjs" | wc -l)
D3=$(find "$VCONTACT3_DIR" -type f -name "*.d3.json" | wc -l)
HTML=$(find "$VCONTACT3_DIR" -type f -name "*.d3.json.html" | wc -l)

echo "GraphML files    : $GRAPHML"
echo "Cytoscape files  : $CYJS"
echo "D3 JSON files    : $D3"
echo "Interactive HTML : $HTML"

echo ""
echo "--- PHORAGER pipeline summaries ---"

GENOMAD_DIR="$PHORAGER_DIR/2.Prophage_detection/Proph1_geNomad"
VIBRANT_DIR="$PHORAGER_DIR/2.Prophage_detection/Proph2_VIBRANT"
COMPARE_DIR="$PHORAGER_DIR/2.Prophage_detection/Proph3_Comparison"

if [[ -d "$GENOMAD_DIR" && -d "$VIBRANT_DIR" && -d "$COMPARE_DIR" ]]; then
    (
        cd "$PHORAGER_DIR/2.Prophage_detection"
        bash "$HERE/scripts/make_prophage_summary.sh"
    )
else
    echo "WARNING: caller comparison directories not all present; skipping caller summary."
fi

if [[ -n "$PROPHAGE_TABLE" && -s "$PROPHAGE_TABLE" ]]; then
    (
        cd "$(dirname "$PROPHAGE_TABLE")"
        python3 "$HERE/scripts/count_prophages_per_host.py"
    )
fi

echo ""
if [[ "$FAIL" -gt 0 ]]; then
    echo "WARNING: Module 06 has $FAIL failed core check(s)."
    echo "Check logs:"
    echo "  $LOG_DIR"
    exit 1
else
    echo "Module 06 core checks passed."
    echo "Final results:"
    echo "  $OUT_DIR/00_final_results/06_prophage"
fi
