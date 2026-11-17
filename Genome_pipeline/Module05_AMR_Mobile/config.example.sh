#!/bin/bash

# ══════════════════════════════════════════════════════════════════════════════
# INPUT / OUTPUT
# ══════════════════════════════════════════════════════════════════════════════

SAMPLE_SHEET="/path/to/samples.tsv"
OUT_DIR="/path/to/output"
LOG_DIR="/path/to/logs"

# ══════════════════════════════════════════════════════════════════════════════
# MODULE 05 SWITCHES
# ══════════════════════════════════════════════════════════════════════════════
RUN_AMRFINDER=true
RUN_GENOMAD=true
RUN_RESFINDER=true

# ══════════════════════════════════════════════════════════════════════════════
# AMRFINDERPLUS
# ══════════════════════════════════════════════════════════════════════════════
# Set to a valid AMRfinderplus organism name, or "mixed" to skip the flag
# Valid values: Acinetobacter_baumannii, Campylobacter, Clostridioides_difficile,
# Enterococcus_faecalis, Enterococcus_faecium, Escherichia, Klebsiella_pneumoniae,
# Pseudomonas_aeruginosa, Salmonella, Staphylococcus_aureus,
# Streptococcus_pneumoniae, Streptococcus_pyogenes, and others.
# Run: amrfinder --list_organisms for the full list
AMRFINDER_ORGANISM="Salmonella"
AMRFINDER_DB="/path/to/amrfinderplus/database"

# ══════════════════════════════════════════════════════════════════════════════
# GENOMAD
# ══════════════════════════════════════════════════════════════════════════════
GENOMAD_DB="/path/to/genomad/database"
══════════════════════════════════════════════════════════════════════════════
# RESFINDER
# ══════════════════════════════════════════════════════════════════════════════
RESFINDER_DB="/path/to/resfinder/database"
# ══════════════════════════════════════════════════════════════════════════════
# PACKAGES
# ══════════════════════════════════════════════════════════════════════════════
PKG_AMRFINDER="your_amrfinder_package"
PKG_GENOMAD="your_genomad_package"
PKG_RESFINDER="your_resfinder_package"


# =========================================================
# SLURM — MODULE 05a: AMRFINDERPLUS
# =========================================================

PARTITION_AMRFINDER="your_partition"
TIME_AMRFINDER="24:00:00"
CPUS_AMRFINDER=4
MEM_PER_CPU_AMRFINDER="4G"

# =========================================================
# SLURM — MODULE 05b: GENOMAD
# =========================================================

PARTITION_GENOMAD="your_partition"
TIME_GENOMAD="24:00:00"
CPUS_GENOMAD=8
MEM_PER_CPU_GENOMAD="8G"

# =========================================================
# SLURM — MODULE 05c: RESFINDER
# =========================================================

PARTITION_RESFINDER="your_partition"
TIME_RESFINDER="24:00:00"
CPUS_RESFINDER=8
MEM_PER_CPU_RESFINDER="4G"

# =========================================================
# SLURM — MODULE 05d: MERGE
# =========================================================

PARTITION_MERGE_MOB="your_partition"
TIME_MERGE_MOB="12:00:00"