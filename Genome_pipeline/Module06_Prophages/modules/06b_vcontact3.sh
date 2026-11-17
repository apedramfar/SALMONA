#!/bin/bash -l

if [[ -z "${MODULE06_SCRIPT_DIR:-}" ]]; then
    echo "ERROR: MODULE06_SCRIPT_DIR is not defined"
    exit 1
fi

source "$MODULE06_SCRIPT_DIR/config.sh"

echo "============================================================"
echo "Module 06B — vConTACT3"
echo "Job ID: ${SLURM_JOB_ID:-NA}"
date
echo "============================================================"

if [[ ! -s "$VCONTACT3_INPUT" ]]; then
    echo "ERROR: PHORAGER handoff FASTA is missing or empty:"
    echo "  $VCONTACT3_INPUT"
    echo "Module 06B will not run without successful Module 06A handoff."
    exit 1
fi

if [[ ! -d "$VCONTACT3_DB" ]]; then
    echo "ERROR: vConTACT3 database not found:"
    echo "  $VCONTACT3_DB"
    exit 1
fi

if [[ -n "$PKG_VCONTACT3" ]]; then
    source package "$PKG_VCONTACT3"
fi

if ! command -v vcontact3 >/dev/null 2>&1; then
    echo "ERROR: vcontact3 is not available in PATH."
    echo "Set PKG_VCONTACT3 in config.sh or load the correct environment."
    exit 1
fi

echo ""
echo "vConTACT3 version:"
vcontact3 version 2>/dev/null || vcontact3 --version 2>/dev/null || true

mkdir -p "$VCONTACT3_DIR"

echo ""
echo "Input:"
echo "  $VCONTACT3_INPUT"
echo "Sequences:"
grep -c '^>' "$VCONTACT3_INPUT" || true
echo ""

vcontact3 run \
    --nucleotide "$VCONTACT3_INPUT" \
    --output "$VCONTACT3_DIR" \
    --db-path "$VCONTACT3_DB" \
    --db-domain "$VCONTACT3_DOMAIN" \
    --threads "${SLURM_CPUS_PER_TASK:-$CPUS_VCONTACT3}" \
    --breaks "$VCONTACT3_BREAKS" \
    --exports \
        graphml \
        cytoscape \
        d3js \
        cosmograph \
        completeness \
        profiles \
    --target-rank \
        order \
        family \
        subfamily \
        genus

echo ""
echo "vConTACT3 COMPLETE"
date
