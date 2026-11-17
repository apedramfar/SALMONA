#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=%x_%A.out
#SBATCH --error=%x_%A.err

source config.sh

echo "Job started"; hostname; date

AMR_DIR="$OUT_DIR/05_mobile_amr/amrfinder"
GENOMAD_DIR="$OUT_DIR/05_mobile_amr/genomad"
RESFINDER_DIR="$OUT_DIR/05_mobile_amr/resfinder"
AGG_DIR="$OUT_DIR/00_final_results/05_mobile_amr"

mkdir -p "$AGG_DIR"

# ─────────────────────────────────────────────────────────────
# AMRfinderPlus
# ─────────────────────────────────────────────────────────────
if [[ "$RUN_AMRFINDER" == true ]]; then
    echo "Merging AMRfinderplus outputs..."

    AMR_MERGED="$AGG_DIR/amrfinder_merged.tsv"
    AMR_SUMMARY="$AGG_DIR/amrfinder_summary.tsv"

    FIRST=true
    for tsv in "$AMR_DIR"/*_amrfinder.tsv; do
        [[ ! -f "$tsv" ]] && continue
        sample_id=$(basename "$tsv" _amrfinder.tsv)

        if [[ "$FIRST" == true ]]; then
            head -1 "$tsv" | awk '{print "sample_id\t"$0}' > "$AMR_MERGED"
            FIRST=false
        fi

        tail -n +2 "$tsv" | awk -v sid="$sample_id" 'NF > 0 {print sid"\t"$0}' >> "$AMR_MERGED"
    done

    echo -e "sample_id\tamr_genes\tvirulence_genes\tstress_genes\ttotal_findings\tamr_classes" > "$AMR_SUMMARY"

    while IFS=$'\t' read -r SAMPLE_ID READ1 READ2; do
        [[ "$SAMPLE_ID" == "sample_id" ]] && continue
        [[ -z "$SAMPLE_ID" ]] && continue

        tsv="$AMR_DIR/${SAMPLE_ID}_amrfinder.tsv"

        if [[ ! -f "$tsv" ]]; then
            echo -e "${SAMPLE_ID}\tNA\tNA\tNA\tNA\tNA" >> "$AMR_SUMMARY"
            continue
        fi

        amr_genes=$(tail -n +2 "$tsv" | awk -F'\t' '$9=="AMR"' | wc -l)
        virulence=$(tail -n +2 "$tsv" | awk -F'\t' '$9=="VIRULENCE"' | wc -l)
        stress=$(tail -n +2 "$tsv" | awk -F'\t' '$9=="STRESS"' | wc -l)
        total=$(tail -n +2 "$tsv" | awk 'NF > 0' | wc -l)

        amr_classes=$(tail -n +2 "$tsv" | \
            awk -F'\t' '$9=="AMR" && $12!="" {print $12}' | \
            sort -u | tr '\n' ';' | sed 's/;$//')

        [[ -z "$amr_classes" ]] && amr_classes="-"

        echo -e "${SAMPLE_ID}\t${amr_genes}\t${virulence}\t${stress}\t${total}\t${amr_classes}" >> "$AMR_SUMMARY"

    done < "$SAMPLE_SHEET"

    echo "AMRfinderplus summary written to $AMR_SUMMARY"
fi

# ─────────────────────────────────────────────────────────────
# geNomad
# ─────────────────────────────────────────────────────────────
if [[ "$RUN_GENOMAD" == true ]]; then
    echo "Merging geNomad outputs..."

    GENOMAD_MERGED="$AGG_DIR/genomad_plasmid_merged.tsv"
    GENOMAD_SUMMARY="$AGG_DIR/genomad_summary.tsv"

    FIRST=true
    for tsv in "$GENOMAD_DIR"/*/*_summary/*_plasmid_summary.tsv; do
        [[ ! -f "$tsv" ]] && continue
        sample_id=$(basename "$(dirname "$(dirname "$tsv")")")

        if [[ "$FIRST" == true ]]; then
            head -1 "$tsv" | awk '{print "sample_id\t"$0}' > "$GENOMAD_MERGED"
            FIRST=false
        fi

        tail -n +2 "$tsv" | awk -v sid="$sample_id" 'NF > 0 {print sid"\t"$0}' >> "$GENOMAD_MERGED"
    done

    echo -e "sample_id\tplasmid_count\ttotal_plasmid_length_bp" > "$GENOMAD_SUMMARY"

    while IFS=$'\t' read -r SAMPLE_ID READ1 READ2; do
        [[ "$SAMPLE_ID" == "sample_id" ]] && continue
        [[ -z "$SAMPLE_ID" ]] && continue

        tsv="$GENOMAD_DIR/${SAMPLE_ID}/${SAMPLE_ID}_summary/${SAMPLE_ID}_plasmid_summary.tsv"

        if [[ ! -f "$tsv" ]]; then
            echo -e "${SAMPLE_ID}\tNA\tNA" >> "$GENOMAD_SUMMARY"
            continue
        fi

        plasmid_count=$(tail -n +2 "$tsv" | awk 'NF > 0' | wc -l)

        if [[ "$plasmid_count" -eq 0 ]]; then
            total_length=0
        else
            total_length=$(tail -n +2 "$tsv" | awk -F'\t' '{sum += $2} END {print sum+0}')
        fi

        echo -e "${SAMPLE_ID}\t${plasmid_count}\t${total_length}" >> "$GENOMAD_SUMMARY"

    done < "$SAMPLE_SHEET"

    echo "geNomad summary written to $GENOMAD_SUMMARY"
fi

# ─────────────────────────────────────────────────────────────
# ResFinder
# ─────────────────────────────────────────────────────────────
if [[ "$RUN_RESFINDER" == true ]]; then
    echo "Merging ResFinder outputs..."

    RES_MERGED="$AGG_DIR/resfinder_merged.tsv"
    RES_SUMMARY="$AGG_DIR/resfinder_summary.tsv"

    FIRST=true
    for tsv in "$RESFINDER_DIR"/*/ResFinder_results_tab.txt; do
        [[ ! -f "$tsv" ]] && continue
        sample_id=$(basename "$(dirname "$tsv")")

        if [[ "$FIRST" == true ]]; then
            head -1 "$tsv" | awk '{print "sample_id\t"$0}' > "$RES_MERGED"
            FIRST=false
        fi

        tail -n +2 "$tsv" | awk -v sid="$sample_id" 'NF > 0 {print sid"\t"$0}' >> "$RES_MERGED"
    done

    echo -e "sample_id\tresfinder_genes\tresfinder_classes\tresfinder_gene_list" > "$RES_SUMMARY"

    while IFS=$'\t' read -r SAMPLE_ID READ1 READ2; do
        [[ "$SAMPLE_ID" == "sample_id" ]] && continue
        [[ -z "$SAMPLE_ID" ]] && continue

        tsv="$RESFINDER_DIR/${SAMPLE_ID}/ResFinder_results_tab.txt"

        if [[ ! -f "$tsv" ]]; then
            echo -e "${SAMPLE_ID}\tNA\tNA\tNA" >> "$RES_SUMMARY"
            continue
        fi

        gene_count=$(tail -n +2 "$tsv" | awk 'NF > 0' | wc -l)

        gene_list=$(tail -n +2 "$tsv" | \
            awk -F'\t' 'NF > 0 {print $1}' | \
            sort -u | tr '\n' ';' | sed 's/;$//')

        class_list=$(tail -n +2 "$tsv" | \
            awk -F'\t' 'NF > 0 {print $NF}' | \
            sort -u | tr '\n' ';' | sed 's/;$//')

        [[ -z "$gene_list" ]] && gene_list="-"
        [[ -z "$class_list" ]] && class_list="-"

        echo -e "${SAMPLE_ID}\t${gene_count}\t${class_list}\t${gene_list}" >> "$RES_SUMMARY"

    done < "$SAMPLE_SHEET"

    echo "ResFinder summary written to $RES_SUMMARY"
fi

# ─────────────────────────────────────────────────────────────
# Combined summary
# ─────────────────────────────────────────────────────────────
echo "Building combined summary table..."

COMBINED="$AGG_DIR/mobile_amr_summary.tsv"

HEADER="sample_id"

[[ "$RUN_AMRFINDER" == true ]] && HEADER="${HEADER}\tamrfinder_amr_genes\tamrfinder_virulence_genes\tamrfinder_stress_genes\tamrfinder_classes"
[[ "$RUN_GENOMAD" == true ]] && HEADER="${HEADER}\tgenomad_plasmid_count\tgenomad_plasmid_length_bp"
[[ "$RUN_RESFINDER" == true ]] && HEADER="${HEADER}\tresfinder_genes\tresfinder_classes\tresfinder_gene_list"

echo -e "$HEADER" > "$COMBINED"

while IFS=$'\t' read -r SAMPLE_ID READ1 READ2; do
    [[ "$SAMPLE_ID" == "sample_id" ]] && continue
    [[ -z "$SAMPLE_ID" ]] && continue

    ROW="$SAMPLE_ID"

    if [[ "$RUN_AMRFINDER" == true ]]; then
        AMR_ROW=$(grep "^${SAMPLE_ID}"$'\t' "$AGG_DIR/amrfinder_summary.tsv" | head -1 || true)
        ROW="${ROW}\t$(echo "$AMR_ROW" | awk -F'\t' '{print $2}')\t$(echo "$AMR_ROW" | awk -F'\t' '{print $3}')\t$(echo "$AMR_ROW" | awk -F'\t' '{print $4}')\t$(echo "$AMR_ROW" | awk -F'\t' '{print $6}')"
    fi

    if [[ "$RUN_GENOMAD" == true ]]; then
        GEN_ROW=$(grep "^${SAMPLE_ID}"$'\t' "$AGG_DIR/genomad_summary.tsv" | head -1 || true)
        ROW="${ROW}\t$(echo "$GEN_ROW" | awk -F'\t' '{print $2}')\t$(echo "$GEN_ROW" | awk -F'\t' '{print $3}')"
    fi

    if [[ "$RUN_RESFINDER" == true ]]; then
        RES_ROW=$(grep "^${SAMPLE_ID}"$'\t' "$AGG_DIR/resfinder_summary.tsv" | head -1 || true)
        ROW="${ROW}\t$(echo "$RES_ROW" | awk -F'\t' '{print $2}')\t$(echo "$RES_ROW" | awk -F'\t' '{print $3}')\t$(echo "$RES_ROW" | awk -F'\t' '{print $4}')"
    fi

    echo -e "$ROW" >> "$COMBINED"

done < "$SAMPLE_SHEET"

echo ""
echo "Module 05 outputs ready in: $AGG_DIR"
echo "Combined summary: $COMBINED"
echo "Job done"; date