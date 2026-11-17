#!/bin/bash -l
source config.sh

echo "=== Mobile Elements & AMR Check ==="
echo ""
echo "  AMRfinderplus : $RUN_AMRFINDER"
echo "  geNomad       : $RUN_GENOMAD"
echo "  ResFinder     : $RUN_RESFINDER"
echo ""

AGG_DIR="$OUT_DIR/00_final_results/05_mobile_amr"
COMBINED="$AGG_DIR/mobile_amr_summary.tsv"

PASS=0
FAIL=0
MISSING=0
EMPTY=0

echo "--- Per-sample file check ---"
echo ""

while IFS=$'\t' read -r SAMPLE_ID READ1 READ2; do
    [[ "$SAMPLE_ID" == "sample_id" ]] && continue
    [[ -z "$SAMPLE_ID" ]] && continue

    SAMPLE_FAIL=false

    if [[ "$RUN_AMRFINDER" == true ]]; then
        FILE="$OUT_DIR/05_mobile_amr/amrfinder/${SAMPLE_ID}_amrfinder.tsv"
        if [[ ! -f "$FILE" ]]; then
            echo "MISSING : $SAMPLE_ID -- $(basename "$FILE")"
            ((MISSING++)); SAMPLE_FAIL=true
        elif [[ ! -s "$FILE" ]]; then
            echo "EMPTY   : $SAMPLE_ID -- $(basename "$FILE")"
            ((EMPTY++)); SAMPLE_FAIL=true
        fi
    fi

    if [[ "$RUN_GENOMAD" == true ]]; then
        FILE="$OUT_DIR/05_mobile_amr/genomad/${SAMPLE_ID}/${SAMPLE_ID}_summary/${SAMPLE_ID}_plasmid_summary.tsv"
        if [[ ! -f "$FILE" ]]; then
            echo "MISSING : $SAMPLE_ID -- $(basename "$FILE")"
            ((MISSING++)); SAMPLE_FAIL=true
        elif [[ ! -s "$FILE" ]]; then
            echo "EMPTY   : $SAMPLE_ID -- $(basename "$FILE")"
            ((EMPTY++)); SAMPLE_FAIL=true
        fi
    fi

    if [[ "$RUN_RESFINDER" == true ]]; then
        FILE="$OUT_DIR/05_mobile_amr/resfinder/${SAMPLE_ID}/ResFinder_results_tab.txt"
        if [[ ! -f "$FILE" ]]; then
            echo "MISSING : $SAMPLE_ID -- ResFinder_results_tab.txt"
            ((MISSING++)); SAMPLE_FAIL=true
        elif [[ ! -s "$FILE" ]]; then
            echo "EMPTY   : $SAMPLE_ID -- ResFinder_results_tab.txt"
            ((EMPTY++)); SAMPLE_FAIL=true
        fi
    fi

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

echo ""
echo "--- Aggregated file check ---"
echo ""

AGG_FAIL=false

if [[ "$RUN_AMRFINDER" == true ]]; then
    for FILE in \
        "$AGG_DIR/amrfinder_merged.tsv" \
        "$AGG_DIR/amrfinder_summary.tsv"; do

        if [[ ! -f "$FILE" ]]; then
            echo "MISSING : $(basename "$FILE")"
            AGG_FAIL=true
        elif [[ ! -s "$FILE" ]]; then
            echo "EMPTY   : $(basename "$FILE")"
            AGG_FAIL=true
        else
            echo "OK      : $(basename "$FILE")"
        fi
    done
fi

if [[ "$RUN_GENOMAD" == true ]]; then
    for FILE in \
        "$AGG_DIR/genomad_plasmid_merged.tsv" \
        "$AGG_DIR/genomad_summary.tsv"; do

        if [[ ! -f "$FILE" ]]; then
            echo "MISSING : $(basename "$FILE")"
            AGG_FAIL=true
        elif [[ ! -s "$FILE" ]]; then
            echo "EMPTY   : $(basename "$FILE")"
            AGG_FAIL=true
        else
            echo "OK      : $(basename "$FILE")"
        fi
    done
fi

if [[ "$RUN_RESFINDER" == true ]]; then
    for FILE in \
        "$AGG_DIR/resfinder_merged.tsv" \
        "$AGG_DIR/resfinder_summary.tsv"; do

        if [[ ! -f "$FILE" ]]; then
            echo "MISSING : $(basename "$FILE")"
            AGG_FAIL=true
        elif [[ ! -s "$FILE" ]]; then
            echo "EMPTY   : $(basename "$FILE")"
            AGG_FAIL=true
        else
            echo "OK      : $(basename "$FILE")"
        fi
    done
fi

if [[ ! -f "$COMBINED" ]]; then
    echo "MISSING : $(basename "$COMBINED")"
    AGG_FAIL=true
elif [[ ! -s "$COMBINED" ]]; then
    echo "EMPTY   : $(basename "$COMBINED")"
    AGG_FAIL=true
else
    echo "OK      : $(basename "$COMBINED")"
fi

if [[ "$AGG_FAIL" == true ]]; then
    echo ""
    echo "WARNING: Some aggregated files are missing. Has 05d_merge completed successfully?"
fi

if [[ "$RUN_AMRFINDER" == true && -f "$AGG_DIR/amrfinder_summary.tsv" ]]; then
    echo ""
    echo "--- AMRfinderplus Summary ---"
    echo ""

    SAMPLES_WITH_AMR=$(tail -n +2 "$AGG_DIR/amrfinder_summary.tsv" | awk -F'\t' '$2 != "NA" && $2 > 0' | wc -l)
    SAMPLES_WITH_VIR=$(tail -n +2 "$AGG_DIR/amrfinder_summary.tsv" | awk -F'\t' '$3 != "NA" && $3 > 0' | wc -l)
    SAMPLES_WITH_STRESS=$(tail -n +2 "$AGG_DIR/amrfinder_summary.tsv" | awk -F'\t' '$4 != "NA" && $4 > 0' | wc -l)

    echo "  Samples with AMR genes       : $SAMPLES_WITH_AMR / $TOTAL"
    echo "  Samples with virulence genes : $SAMPLES_WITH_VIR / $TOTAL"
    echo "  Samples with stress genes    : $SAMPLES_WITH_STRESS / $TOTAL"
fi

if [[ "$RUN_GENOMAD" == true && -f "$AGG_DIR/genomad_summary.tsv" ]]; then
    echo ""
    echo "--- geNomad Plasmid Summary ---"
    echo ""

    SAMPLES_WITH_PLASMID=$(tail -n +2 "$AGG_DIR/genomad_summary.tsv" | awk -F'\t' '$2 != "NA" && $2 > 0' | wc -l)

    echo "  Samples with plasmids : $SAMPLES_WITH_PLASMID / $TOTAL"
fi

if [[ "$RUN_RESFINDER" == true && -f "$AGG_DIR/resfinder_summary.tsv" ]]; then
    echo ""
    echo "--- ResFinder Summary ---"
    echo ""

    SAMPLES_WITH_RES=$(tail -n +2 "$AGG_DIR/resfinder_summary.tsv" | awk -F'\t' '$2 != "NA" && $2 > 0' | wc -l)

    echo "  Samples with acquired AMR genes : $SAMPLES_WITH_RES / $TOTAL"
fi

echo ""
if [[ "$FAIL" -gt 0 || "$AGG_FAIL" == true ]]; then
    echo "WARNING: Some output files are missing. Check logs in $LOG_DIR."
else
    echo "All files present. Module 05 complete."
    echo "Final results are in: $OUT_DIR/00_final_results/05_mobile_amr/"
fi