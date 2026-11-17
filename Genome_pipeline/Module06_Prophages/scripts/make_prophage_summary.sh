#!/bin/bash -l

echo "=== Creating prophage caller comparison summary ==="

OUT="prophage_caller_summary.tsv"

GENOMAD_DIR="Proph1_geNomad"
VIBRANT_DIR="Proph2_VIBRANT"
COMPARE_DIR="Proph3_Comparison"

echo -e "sample_id\tgenomad_prophage_count\tvibrant_prophage_count\tconsolidated_prophage_count" > "$OUT"

for sample_dir in "$GENOMAD_DIR"/*; do

    [[ ! -d "$sample_dir" ]] && continue

    sample=$(basename "$sample_dir")

    genomad_file="$GENOMAD_DIR/$sample/${sample}_genomad_coordinates.tsv"
    vibrant_file="$VIBRANT_DIR/$sample/${sample}_vibrant_coordinates.tsv"
    consolidated_file="$COMPARE_DIR/$sample/${sample}_consolidated_coordinates.tsv"

    if [[ -f "$genomad_file" ]]; then
        genomad_count=$(tail -n +2 "$genomad_file" | awk 'NF > 0' | wc -l)
    else
        genomad_count="NA"
    fi

    if [[ -f "$vibrant_file" ]]; then
        vibrant_count=$(tail -n +2 "$vibrant_file" | awk 'NF > 0' | wc -l)
    else
        vibrant_count="NA"
    fi

    if [[ -f "$consolidated_file" ]]; then
        consolidated_count=$(tail -n +2 "$consolidated_file" | awk 'NF > 0' | wc -l)
    else
        consolidated_count="NA"
    fi

    echo -e "${sample}\t${genomad_count}\t${vibrant_count}\t${consolidated_count}" >> "$OUT"

done

echo ""
echo "Summary written to:"
echo "$OUT"
echo ""

column -t -s $'\t' "$OUT"
