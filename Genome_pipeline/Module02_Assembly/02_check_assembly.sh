#!/bin/bash -l
source config.sh

echo "=== Assembly QC Check ==="
echo ""

AGG_DIR="$OUT_DIR/00_final_results/02_assembly"
CHECKM2_REPORT="$AGG_DIR/checkm2_quality_report.tsv"
COVERAGE_SUMMARY="$AGG_DIR/coverage_summary.tsv"
FASTA_DIR="$OUT_DIR/02_assembly/fasta"

PASS=0
FAIL=0
MISSING=0
EMPTY=0

# ── Per-sample file checks ────────────────────────────────────────────────────
echo "--- Per-sample file check ---"
while IFS=$'\t' read -r SAMPLE_ID READ1 READ2; do
    [[ "$SAMPLE_ID" == "sample_id" ]] && continue

    SAMPLE_FAIL=false

    FASTA="$FASTA_DIR/${SAMPLE_ID}.fasta"
    COV="$OUT_DIR/02_assembly/coverage/${SAMPLE_ID}_coverage.tsv"

    for FILE in "$FASTA" "$COV"; do
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

# ── Assembly quality summary ──────────────────────────────────────────────────
echo ""
echo "--- Assembly Quality Summary ---"

if [[ ! -f "$CHECKM2_REPORT" ]]; then
    echo "WARNING: CheckM2 report not found at $CHECKM2_REPORT"
    echo "         Has 02b_checkm2 completed successfully?"
elif [[ ! -f "$COVERAGE_SUMMARY" ]]; then
    echo "WARNING: Coverage summary not found at $COVERAGE_SUMMARY"
    echo "         Has 02b_checkm2 completed successfully?"
else
    WARN_COUNT=0
    OK_COUNT=0

    # Load coverage into associative array
    declare -A COVERAGE
    while IFS=$'\t' read -r sample_id mean_cov; do
        [[ "$sample_id" == "sample_id" ]] && continue
        COVERAGE["$sample_id"]="$mean_cov"
    done < "$COVERAGE_SUMMARY"

    # Print header
    printf "%-30s %-14s %-15s %-12s %s\n" \
        "SAMPLE_ID" "COMPLETENESS" "CONTAMINATION" "COVERAGE" "STATUS"
    printf '%0.s-' {1..90}; echo ""

    # Skip two header lines in CheckM2 report (comment line + column names)
    while IFS=$'\t' read -r name completeness contamination rest; do
        [[ "$name" == "Name" || "$name" == \#* ]] && continue

        mean_cov="${COVERAGE[$name]:-NA}"
        WARNINGS=()

        # Completeness check
        if [[ "$completeness" != "NA" ]] && \
           (( $(echo "$completeness < $MIN_COMPLETENESS" | bc -l) )); then
            WARNINGS+=("low_completeness:${completeness}%")
        fi

        # Contamination check
        if [[ "$contamination" != "NA" ]] && \
           (( $(echo "$contamination > $MAX_CONTAMINATION" | bc -l) )); then
            WARNINGS+=("high_contamination:${contamination}%")
        fi

        # Coverage check
        if [[ "$mean_cov" != "NA" ]] && \
           (( $(echo "$mean_cov < $MIN_COVERAGE" | bc -l) )); then
            WARNINGS+=("low_coverage:${mean_cov}x")
        fi

        if [[ "${#WARNINGS[@]}" -gt 0 ]]; then
            STATUS="WARN: $(IFS=';'; echo "${WARNINGS[*]}")"
            ((WARN_COUNT++))
        else
            STATUS="OK"
            ((OK_COUNT++))
        fi

        printf "%-30s %-14s %-15s %-12s %s\n" \
            "$name" "$completeness" "$contamination" "$mean_cov" "$STATUS"

    done < "$CHECKM2_REPORT"

    echo ""
    echo "  High-quality genomes : $OK_COUNT"
    echo "  Flagged genomes      : $WARN_COUNT"
    echo ""
    echo "Thresholds applied:"
    echo "  Completeness  >= ${MIN_COMPLETENESS}%"
    echo "  Contamination <= ${MAX_CONTAMINATION}%"
    echo "  Coverage      >= ${MIN_COVERAGE}x"

    if [[ "$WARN_COUNT" -gt 0 ]]; then
        echo ""
        echo "WARNING: $WARN_COUNT genome(s) flagged."
        echo "Review flagged samples and consider removing them from your sample"
        echo "sheet before proceeding to dereplication and annotation."
    fi
fi

echo ""
if [[ "$FAIL" -gt 0 ]]; then
    echo "WARNING: Some output files are missing. Check logs in $LOG_DIR before proceeding."
else
    echo "All files present. Review any quality warnings above, then run: bash 03_run_annotation.sh"
fi
