#!/bin/bash -l

if [[ -z "${MODULE06_SCRIPT_DIR:-}" ]]; then
    echo "ERROR: MODULE06_SCRIPT_DIR is not defined"
    exit 1
fi

source "$MODULE06_SCRIPT_DIR/config.sh"

mkdir -p "$PHORAGER_DIR"

export WRAPPER_DEBUG
export NXF_OFFLINE

set +e
source package "$PKG_NEXTFLOW"
NEXTFLOW_LOAD_STATUS=$?
set -e

if [[ "$NEXTFLOW_LOAD_STATUS" -ne 0 ]]; then
    echo "WARNING: configured Nextflow package failed to load:"
    echo "  $PKG_NEXTFLOW"
fi

export PATH="$PHORAGER_HOME:$PATH"

echo "============================================================"
echo "Module 06A — PHORAGER"
echo "Job ID: ${SLURM_JOB_ID:-NA}"
echo "Host: $(hostname)"
date
echo "============================================================"

echo ""
echo "Nextflow:"
nextflow -version || true

echo ""
echo "PHORAGER:"
command -v phorager || { echo "ERROR: phorager not found"; exit 1; }
phorager --version 2>/dev/null || true

THREADS="${SLURM_CPUS_PER_TASK:-$CPUS_PHORAGER}"

RESUME_ARG=""
[[ "$PHORAGER_RESUME" == true ]] && RESUME_ARG="--resume"

echo ""
echo "Step 1/3 — prophage detection"
phorager prophage \
    --genome "$GENOME_DIR" \
    --outdir "$PHORAGER_DIR" \
    --threads "$THREADS" \
    $RESUME_ARG

echo ""
echo "Step 2/3 — annotation"
phorager annotation \
    --prophage "$PHORAGER_DIR" \
    --outdir "$PHORAGER_DIR" \
    --threads "$THREADS" \
    $RESUME_ARG

echo ""
echo "Step 3/3 — prophage table"
phorager summarize \
    --type prophage_table \
    --annotation-outdir $PHORAGER_DIR --outdir "$PHORAGER_DIR"

echo ""
echo "PHORAGER COMPLETE"
date
