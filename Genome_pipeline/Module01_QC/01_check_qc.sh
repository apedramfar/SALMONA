#!/bin/bash -l
source config.sh

echo "=== QC Check ==="
echo ""

PASS=0
FAIL=0
MISSING=0
EMPTY=0

AGG_DIR="$OUT_DIR/01_qc/aggregated"
CONTAM_TSV="$AGG_DIR/contamination_summary.tsv"

# ── Per-sample file checks ────────────────────────────────────────────────────
while IFS=$'\t' read -r SAMPLE_ID READ1 READ2; do
    [[ "$SAMPLE_ID" == "sample_id" ]] && continue

    SAMPLE_FAIL=false

    R1="$OUT_DIR/01_qc/trimming/${SAMPLE_ID}_clean_R1.fq.gz"
    R2="$OUT_DIR/01_qc/trimming/${SAMPLE_ID}_clean_R2.fq.gz"
    HOSTLOG="$OUT_DIR/01_qc/host_removal/${SAMPLE_ID}_hostmap.json"
    PROFILE="$OUT_DIR/01_qc/metaphlan/${SAMPLE_ID}.unclprofile.txt"

    # Check clean reads
    for FILE in "$R1" "$R2"; do
        if [[ ! -f "$FILE" ]]; then
            echo "MISSING : $SAMPLE_ID -- $(basename $FILE)"
            ((MISSING++)); SAMPLE_FAIL=true
        elif [[ ! -s "$FILE" ]]; then
            echo "EMPTY   : $SAMPLE_ID -- $(basename $FILE)"
            ((EMPTY++)); SAMPLE_FAIL=true
        fi
    done

    # Check hostile log
    if [[ ! -f "$HOSTLOG" ]]; then
        echo "MISSING : $SAMPLE_ID -- host removal log"
        ((MISSING++)); SAMPLE_FAIL=true
    fi

    # Check MetaPhlAn profile
    if [[ ! -f "$PROFILE" ]]; then
        echo "MISSING : $SAMPLE_ID -- MetaPhlAn profile"
        ((MISSING++)); SAMPLE_FAIL=true
    elif [[ ! -s "$PROFILE" ]]; then
        echo "EMPTY   : $SAMPLE_ID -- MetaPhlAn profile"
        ((EMPTY++)); SAMPLE_FAIL=true
    fi

    if [[ "$SAMPLE_FAIL" == false ]]; then
        ((PASS++))
    else
        ((FAIL++))
    fi

done < "$SAMPLE_SHEET"

# ── File check summary ────────────────────────────────────────────────────────
TOTAL=$(( PASS + FAIL ))
echo ""
echo "=== File Check Summary ==="
echo "  Total samples : $TOTAL"
echo "  Passed        : $PASS"
echo "  Failed        : $FAIL"
echo "  (missing files: $MISSING | empty files: $EMPTY)"

# ── Contamination summary ─────────────────────────────────────────────────────
echo ""
echo "=== Contamination Summary ==="

if [[ ! -f "$CONTAM_TSV" ]]; then
    echo "WARNING: contamination_summary.tsv not found at $CONTAM_TSV"
    echo "         Has 01c_qc_merge completed successfully?"
else
    WARN_COUNT=0
    OK_COUNT=0

    # Print header
    printf "%-30s %-15s %-40s %-12s %-18s %s\n" \
        "SAMPLE_ID" "SPECIES_COUNT" "TOP_SPECIES" "TOP_ABUND" "UNCLASSIFIED_PCT" "STATUS"
    printf '%0.s-' {1..130}; echo ""

    while IFS=$'\t' read -r sample_id species_count top_species top_abundance unclassified_pct status; do
        [[ "$sample_id" == "sample_id" ]] && continue
        printf "%-30s %-15s %-40s %-12s %-18s %s\n" \
            "$sample_id" "$species_count" "$top_species" "$top_abundance" "$unclassified_pct" "$status"
        if [[ "$status" == WARN* ]]; then
            ((WARN_COUNT++))
        else
            ((OK_COUNT++))
        fi
    done < "$CONTAM_TSV"

    echo ""
    echo "  Clean isolates    : $OK_COUNT"
    echo "  Flagged isolates  : $WARN_COUNT"

    if [[ "$WARN_COUNT" -gt 0 ]]; then
        echo ""
        echo "WARNING: $WARN_COUNT sample(s) flagged for potential contamination."
        echo "Review $CONTAM_TSV and decide whether to exclude flagged samples"
        echo "before proceeding to assembly."
    fi
fi

echo ""
if [[ "$FAIL" -gt 0 ]]; then
    echo "WARNING: Some output files are missing. Check logs in $LOG_DIR before proceeding."
    echo "When issues are resolved, run: bash 02_run_assembly.sh"
else
    echo "All files present. Review any contamination warnings above, then run: bash 02_run_assembly.sh"
fi
