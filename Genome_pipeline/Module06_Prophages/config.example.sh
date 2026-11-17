
#!/bin/bash

# ══════════════════════════════════════════════════════════════════════════════
# PIPELINE / INPUT / OUTPUT 
# ══════════════════════════════════════════════════════════════════════════════

PIPELINE_DIR="/path/to/Module06_Prophages"
SAMPLE_SHEET="/path/to/samples.tsv"
GENOME_DIR="/path/to/genome_assemblies"
OUT_DIR="/path/to/output"
LOG_DIR="/path/to/logs"

# ══════════════════════════════════════════════════════════════════════════════
# MODULE 06A — PHORAGER v0.5.0-beta
# ══════════════════════════════════════════════════════════════════════════════

# PHORAGER results 
PHORAGER_DIR="$OUT_DIR/06_phorager_v0.5.0"

# Central QIB installation (source, databases, and Singularity images)
PHORAGER_SHARED="/path/to/phorager/shared_resources"


# Personal HPC installation, as recommended by QIB documentation.
# The PHORAGER wrapper launches Nextflow from its installation directory,
# so this directory must be writable.
PHORAGER_HOME="/path/to/phorager/installation"

# Shared databases and Singularity cache
PHORAGER_DB="$PHORAGER_SHARED/databases"
PHORAGER_CACHE="$PHORAGER_SHARED/singularity_cache"

# HPC Nextflow package
PKG_NEXTFLOW="your_nextflow_package"

NXF_OFFLINE=true
WRAPPER_DEBUG=false
PHORAGER_RESUME=true

PARTITION_PHORAGER="your_partition"
TIME_PHORAGER="200:00:00"
CPUS_PHORAGER=4
MEM_PER_CPU_PHORAGER="40G"

# ══════════════════════════════════════════════════════════════════════════════
# 06A → 06B HANDOFF
# ══════════════════════════════════════════════════════════════════════════════

# Combined CheckV-filtered prophage FASTA produced by PHORAGER annotation.
PHORAGER_FILTERED_FASTA="$PHORAGER_DIR/3.Annotation/Anno1_CheckV/filtered_prophages.fasta"

# Consolidated prophage FASTAs produced during detection.
PHORAGER_COMPARISON_DIR="$PHORAGER_DIR/2.Prophage_detection/Proph3_Comparison"

# Standardised FASTA passed to vConTACT3.
HANDOFF_DIR="$OUT_DIR/06_prophage_handoff"
VCONTACT3_INPUT="$HANDOFF_DIR/phorager_prophages_for_vcontact3.fasta"

# Options:
#   filtered     = CheckV-filtered PHORAGER FASTA (default)
#   consolidated = concatenate *_prophage_sequences.fasta from Proph3_Comparison
PHORAGER_HANDOFF_MODE="filtered"

# SLURM — PHORAGER to vConTACT3 handoff
PARTITION_HANDOFF="your_partition"
TIME_HANDOFF="02:00:00"
CPUS_HANDOFF=1
MEM_HANDOFF="4G"

# ══════════════════════════════════════════════════════════════════════════════
# MODULE 06B — vConTACT3
# ══════════════════════════════════════════════════════════════════════════════

VCONTACT3_DIR="$OUT_DIR/06_vcontact3"

VCONTACT3_DB="/path/to/vcontact3/database"
VCONTACT3_DOMAIN="prokaryotes"
VCONTACT3_BREAKS=5

PKG_VCONTACT3="/your/software/package/path/bin/vcontact3__3.1.3"

PARTITION_VCONTACT3="your_partition"
TIME_VCONTACT3="24:00:00"
CPUS_VCONTACT3=16
MEM_PER_CPU_VCONTACT3="4G"

# ══════════════════════════════════════════════════════════════════════════════
# MODULE 06B — vConTACT3 SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

PARTITION_VCONTACT3_SUMMARY="your_partition"
TIME_VCONTACT3_SUMMARY="02:00:00"
CPUS_VCONTACT3_SUMMARY=2
MEM_PER_CPU_VCONTACT3_SUMMARY="4G"
