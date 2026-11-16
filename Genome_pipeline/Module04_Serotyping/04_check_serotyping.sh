#!/bin/bash -l
source config.sh

echo "=== Module 04 serotyping check ==="
echo ""

SUMMARY="$SEROTYPING_DIR/serotyping_summary.tsv"

mkdir -p "$SEROTYPING_DIR"

echo -e "sample_id\tseqsero2_predicted_serovar\tsistr_predicted_serovar" > "$SUMMARY"

while IFS=$'\t' read -r SAMPLE_ID READ1 READ2; do

    [[ "$SAMPLE_ID" == "sample_id" ]] && continue
    [[ -z "$SAMPLE_ID" ]] && continue

    SEQSERO_DIR_SAMPLE="$SEQSERO2_DIR/${SAMPLE_ID}"
    SEQSERO_FILE="$SEQSERO_DIR_SAMPLE/SeqSero_result.tsv"

    SISTR_DIR_SAMPLE="$SISTR_DIR/${SAMPLE_ID}"
    SISTR_FILE="$SISTR_DIR_SAMPLE/${SAMPLE_ID}_sistr.csv"

    # -----------------------------
    # SeqSero2
    # -----------------------------
    if [[ -f "$SEQSERO_FILE" && -s "$SEQSERO_FILE" ]]; then

        SEQSERO=$(awk -F'\t' '
            NR==1 {
                for(i=1;i<=NF;i++){
                    if($i=="Predicted serotype") col=i
                }
            }
            NR==2 && col {
                print $col
            }
        ' "$SEQSERO_FILE")

        if [[ -z "$SEQSERO" || "$SEQSERO" == "-" || "$SEQSERO" == "- -:-:-" ]]; then
            SEQSERO="NA"
        fi

    else
        SEQSERO="NA"

        if [[ -d "$SEQSERO_DIR_SAMPLE" ]]; then
            echo "WARNING: SeqSero2 folder exists but result missing/empty for $SAMPLE_ID"
            echo "         Expected: $SEQSERO_FILE"
        else
            echo "WARNING: SeqSero2 output folder missing for $SAMPLE_ID"
            echo "         Expected: $SEQSERO_DIR_SAMPLE"
        fi
    fi

    # -----------------------------
    # SISTR
    # -----------------------------
    if [[ -f "$SISTR_FILE" && -s "$SISTR_FILE" ]]; then

        SISTR=$(python3 - "$SISTR_FILE" <<'PY'
import csv
import sys

with open(sys.argv[1], newline='') as f:
    reader = csv.DictReader(f)
    row = next(reader, None)

    if row is None:
        print("NA")
    else:
        value = row.get("serovar", "").strip()
        if value == "" or value == "-:-:-":
            print("NA")
        else:
            print(value)
PY
)

    else
        SISTR="NA"

        if [[ -d "$SISTR_DIR_SAMPLE" ]]; then
            echo "WARNING: SISTR folder exists but result missing/empty for $SAMPLE_ID"
            echo "         Expected: $SISTR_FILE"
        else
            echo "WARNING: SISTR output folder missing for $SAMPLE_ID"
            echo "         Expected: $SISTR_DIR_SAMPLE"
        fi
    fi

    echo -e "${SAMPLE_ID}\t${SEQSERO}\t${SISTR}" >> "$SUMMARY"

done < "$SAMPLE_SHEET"

echo ""
echo "Summary created:"
echo "$SUMMARY"
echo ""

column -t -s $'\t' "$SUMMARY"