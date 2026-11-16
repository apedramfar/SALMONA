#!/bin/bash -l
source config.sh

echo "=== Annotation Check ==="
echo ""

AGG_DIR="$OUT_DIR/00_final_results/03_annotation"
SUMMARY="$AGG_DIR/assembly_annotation_summary.tsv"


PASS=0
FAIL=0
MISSING=0
EMPTY=0

# ── Per-sample file checks ────────────────────────────────────────────────────
echo "--- Per-sample file check ---"
echo ""
while IFS=$'\t' read -r SAMPLE_ID READ1 READ2; do
    [[ "$SAMPLE_ID" == "sample_id" ]] && continue

    SAMPLE_FAIL=false

    GFF="$OUT_DIR/03_annotation/bakta/${SAMPLE_ID}/${SAMPLE_ID}.gff3"
    FAA="$OUT_DIR/03_annotation/bakta/${SAMPLE_ID}/${SAMPLE_ID}.faa"
    TSV="$OUT_DIR/03_annotation/bakta/${SAMPLE_ID}/${SAMPLE_ID}.tsv"

    for FILE in "$GFF" "$FAA" "$TSV"; do
        if [[ ! -f "$FILE" ]]; then
            echo "MISSING : $SAMPLE_ID -- $(basename $FILE)"
            ((MISSING++)); SAMPLE_FAIL=true
        elif [[ ! -s "$FILE" ]]; then
            echo "EMPTY   : $SAMPLE_ID -- $(basename $FILE)"
            ((EMPTY++)); SAMPLE_FAIL=true
        fi
    done

    if [[ "$SAMPLE_FAIL" == false ]]; then
        ((PASS++))
    else
        ((FAIL++))
    fi

done < "$SAMPLE_SHEET"

TOTAL=$(( PASS + FAIL ))
echo ""
echo "  Total samples : $TOTAL"
echo "  Passed        : $PASS"
echo "  Failed        : $FAIL"
echo "  (missing files: $MISSING | empty files: $EMPTY)"

# ── dRep clustering summary ───────────────────────────────────────────────────
echo ""
echo "--- dRep Clustering Summary ---"
CDB="$AGG_DIR/drep_clusters.csv"
WIDB="$AGG_DIR/drep_representatives.csv"

if [[ ! -f "$CDB" || ! -f "$WIDB" ]]; then
    echo "WARNING: dRep output tables not found in $AGG_DIR"
    echo "         Has 03a_drep completed successfully?"
else
    TOTAL_GENOMES=$(tail -n +2 "$CDB" | wc -l)
    TOTAL_CLUSTERS=$(tail -n +2 "$CDB" | awk -F',' '{print $2}' | sort -u | wc -l)
    REPRESENTATIVES=$(tail -n +2 "$WIDB" | wc -l)
    REDUNDANT=$(( TOTAL_GENOMES - REPRESENTATIVES ))

    echo "  Total genomes      : $TOTAL_GENOMES"
    echo "  Distinct clusters  : $TOTAL_CLUSTERS"
    echo "  Representatives    : $REPRESENTATIVES"
    echo "  Redundant genomes  : $REDUNDANT"
    echo "  ANI threshold used : $DREP_ANI"
fi

# ── Combined summary table ────────────────────────────────────────────────────
echo ""
echo "--- Assembly & Annotation Summary ---"

if [[ ! -f "$SUMMARY" ]]; then
    echo "WARNING: Combined summary not found at $SUMMARY"
    echo "         Has 03c_merge completed successfully?"
else
    # Verify thresholds are set
    if [[ -z "$MIN_COMPLETENESS" || -z "$MAX_CONTAMINATION" || -z "$MIN_COVERAGE" ]]; then
        echo "ERROR: One or more quality thresholds are not set in config.sh"
        echo "       Please check MIN_COMPLETENESS, MAX_CONTAMINATION, MIN_COVERAGE"
        exit 1
    fi

    WARN_COUNT=0
    OK_COUNT=0

    printf "%-30s %-14s %-15s %-12s %-14s %-16s %s\n" \
        "SAMPLE_ID" "COMPLETENESS" "CONTAMINATION" "COVERAGE" "DREP_CLUSTER" "REPRESENTATIVE" "STATUS"
    printf '%0.s-' {1..115}; echo ""

    while IFS=$'\t' read -r sample_id completeness contamination n50 coverage cluster is_rep; do
        [[ "$sample_id" == "sample_id" ]] && continue

        WARNINGS=()

        if [[ "$completeness" != "NA" ]] && \
           awk "BEGIN {exit !($completeness < $MIN_COMPLETENESS)}"; then
            WARNINGS+=("low_completeness:${completeness}%")
        fi

        if [[ "$contamination" != "NA" ]] && \
           awk "BEGIN {exit !($contamination > $MAX_CONTAMINATION)}"; then
            WARNINGS+=("high_contamination:${contamination}%")
        fi

        if [[ "$coverage" != "NA" ]] && \
           awk "BEGIN {exit !($coverage < $MIN_COVERAGE)}"; then
            WARNINGS+=("low_coverage:${coverage}x")
        fi

        if [[ "${#WARNINGS[@]}" -gt 0 ]]; then
            STATUS="WARN: $(IFS=';'; echo "${WARNINGS[*]}")"
            ((WARN_COUNT++))
        else
            STATUS="OK"
            ((OK_COUNT++))
        fi

        printf "%-30s %-14s %-15s %-12s %-14s %-16s %s\n" \
            "$sample_id" "$completeness" "$contamination" \
            "$coverage" "$cluster" "$is_rep" "$STATUS"

    done < "$SUMMARY"

    echo ""
    echo "  High-quality genomes : $OK_COUNT"
    echo "  Flagged genomes      : $WARN_COUNT"
    echo ""

    if [[ "$WARN_COUNT" -gt 0 ]]; then
        echo ""
        echo "WARNING: $WARN_COUNT genome(s) flagged. Review before downstream analysis."
    fi
fi

echo ""
if [[ "$FAIL" -gt 0 ]]; then
    echo "WARNING: Some Bakta output files are missing. Check logs in $LOG_DIR."
else
    echo "All files present. Pipeline complete."
    echo "Final results are in: $OUT_DIR/00_final_results/"
fi
