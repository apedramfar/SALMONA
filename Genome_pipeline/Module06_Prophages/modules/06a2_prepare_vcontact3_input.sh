#!/bin/bash -l

if [[ -z "${MODULE06_SCRIPT_DIR:-}" ]]; then
    echo "ERROR: MODULE06_SCRIPT_DIR is not defined"
    exit 1
fi

source "$MODULE06_SCRIPT_DIR/config.sh"

mkdir -p "$HANDOFF_DIR"
TMP="${VCONTACT3_INPUT}.tmp"
rm -f "$TMP"

echo "=== PHORAGER → vConTACT3 handoff ==="
echo "Mode: $PHORAGER_HANDOFF_MODE"
echo ""

case "$PHORAGER_HANDOFF_MODE" in

    filtered)
        if [[ ! -s "$PHORAGER_FILTERED_FASTA" ]]; then
            echo "ERROR: PHORAGER CheckV-filtered FASTA not found or empty:"
            echo "  $PHORAGER_FILTERED_FASTA"
            exit 1
        fi

        cp "$PHORAGER_FILTERED_FASTA" "$TMP"
        SOURCE_DESCRIPTION="$PHORAGER_FILTERED_FASTA"
        ;;

    consolidated)
        if [[ ! -d "$PHORAGER_COMPARISON_DIR" ]]; then
            echo "ERROR: PHORAGER comparison directory not found:"
            echo "  $PHORAGER_COMPARISON_DIR"
            exit 1
        fi

        mapfile -t FASTAS < <(
            find "$PHORAGER_COMPARISON_DIR" \
                -mindepth 2 -maxdepth 2 \
                -type f \
                -name "*_prophage_sequences.fasta" \
                -size +0c \
                | sort
        )

        if [[ "${#FASTAS[@]}" -eq 0 ]]; then
            echo "ERROR: no *_prophage_sequences.fasta files found."
            exit 1
        fi

        cat "${FASTAS[@]}" > "$TMP"
        SOURCE_DESCRIPTION="${#FASTAS[@]} PHORAGER consolidated per-host FASTAs"
        ;;

    *)
        echo "ERROR: unknown PHORAGER_HANDOFF_MODE:"
        echo "  $PHORAGER_HANDOFF_MODE"
        echo "Valid values: filtered, consolidated"
        exit 1
        ;;
esac

if [[ ! -s "$TMP" ]]; then
    echo "ERROR: generated handoff FASTA is empty."
    exit 1
fi

SEQ_COUNT=$(grep -c '^>' "$TMP" || true)

if [[ "$SEQ_COUNT" -eq 0 ]]; then
    echo "ERROR: no FASTA headers found in generated handoff."
    exit 1
fi

mv "$TMP" "$VCONTACT3_INPUT"

{
    echo -e "field\tvalue"
    echo -e "mode\t$PHORAGER_HANDOFF_MODE"
    echo -e "source\t$SOURCE_DESCRIPTION"
    echo -e "output\t$VCONTACT3_INPUT"
    echo -e "sequence_count\t$SEQ_COUNT"
} > "$HANDOFF_DIR/handoff_summary.tsv"

echo "Handoff FASTA created:"
echo "  $VCONTACT3_INPUT"
echo "Sequences:"
echo "  $SEQ_COUNT"
