#!/bin/bash

# =========================================================
# INPUT / OUTPUT
# =========================================================

SAMPLE_SHEET="/path/to/samples.tsv"
OUT_DIR="/path/to/output"
LOG_DIR="/path/to/logs"

# =========================================================
# MODULE 02 — Assembly
# =========================================================

ASSEMBLY_DIR="$OUT_DIR/02_assembly/fasta"

# =========================================================
# MODULE 04 — Serotyping
# =========================================================

SEROTYPING_DIR="$OUT_DIR/04_serotyping"

SEQSERO2_DIR="$SEROTYPING_DIR/seqsero2"
SISTR_DIR="$SEROTYPING_DIR/sistr"

# =========================================================
# SOFTWARE PACKAGES
# =========================================================

PKG_SEQSERO2="seqsero2_package"
PKG_SISTR="sistr"

# =========================================================
# SLURM — SeqSero2
# =========================================================

PARTITION_SEQSERO2="your_partition"

TIME_SEQSERO2="24:00:00"

CPUS_SEQSERO2=10

# 10 × 6400M ≈ 64G total
MEM_PER_CPU_SEQSERO2="6400M"

# =========================================================
# SLURM — SISTR
# =========================================================

PARTITION_SISTR="your_partition"

TIME_SISTR="12:00:00"

CPUS_SISTR=4

MEM_PER_CPU_SISTR="4G"
