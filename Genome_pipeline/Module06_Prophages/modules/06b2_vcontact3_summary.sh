#!/bin/bash -l

if [[ -z "${MODULE06_SCRIPT_DIR:-}" ]]; then
    echo "ERROR: MODULE06_SCRIPT_DIR is not defined"
    exit 1
fi

source "$MODULE06_SCRIPT_DIR/config.sh"

FINAL_DIR="$OUT_DIR/00_final_results/06_prophage"
mkdir -p "$FINAL_DIR"

ASSIGNMENTS="$VCONTACT3_DIR/exports/final_assignments.csv"
[[ -f "$ASSIGNMENTS" ]] || ASSIGNMENTS="$VCONTACT3_DIR/final_assignments.csv"

if [[ ! -s "$ASSIGNMENTS" ]]; then
    echo "ERROR: final_assignments.csv not found or empty."
    exit 1
fi

cp "$ASSIGNMENTS" "$FINAL_DIR/final_assignments.csv"
cp "$HANDOFF_DIR/handoff_summary.tsv" "$FINAL_DIR/handoff_summary.tsv"

QUERY_NOT_NETWORK=$(find "$VCONTACT3_DIR" -type f -name "query_not_in_network.txt" -print -quit)
if [[ -n "$QUERY_NOT_NETWORK" && -s "$QUERY_NOT_NETWORK" ]]; then
    cp "$QUERY_NOT_NETWORK" "$FINAL_DIR/query_not_in_network.txt"
fi

TOTAL=$(( $(wc -l < "$ASSIGNMENTS") - 1 ))
INPUT_N=$(grep -c '^>' "$VCONTACT3_INPUT" || true)

{
    echo -e "metric\tvalue"
    echo -e "phorager_handoff_mode\t$PHORAGER_HANDOFF_MODE"
    echo -e "vcontact3_input_sequences\t$INPUT_N"
    echo -e "vcontact3_assignment_rows\t$TOTAL"
    echo -e "vcontact3_database\t$VCONTACT3_DB"
    echo -e "vcontact3_breaks\t$VCONTACT3_BREAKS"
} > "$FINAL_DIR/module06_summary.tsv"

echo "Module 06 summary written to:"
echo "  $FINAL_DIR"
