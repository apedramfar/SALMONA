#!/bin/bash

# ══════════════════════════════════════════════════════════════════════════════
# INPUT / OUTPUT
# ══════════════════════════════════════════════════════════════════════════════
SAMPLE_SHEET="/path/to/samples.tsv"
OUT_DIR="/path/to/output"
LOG_DIR="/path/to/logs"
# ══════════════════════════════════════════════════════════════════════════════
# ASSEMBLY PARAMETERS
# ══════════════════════════════════════════════════════════════════════════════
MIN_CONTIG_LENGTH=500     # minimum contig length passed to downstream tools

# ══════════════════════════════════════════════════════════════════════════════
# ASSEMBLY QC THRESHOLDS
# ══════════════════════════════════════════════════════════════════════════════
MIN_COMPLETENESS=90       # CheckM2 completeness %
MAX_CONTAMINATION=5       # CheckM2 contamination %
MIN_COVERAGE=20           # mean genome coverage from CoverM

# ══════════════════════════════════════════════════════════════════════════════
# DATABASES
# ══════════════════════════════════════════════════════════════════════════════
CHECKM2DB="/path/to/checkm2/database.dmnd"
# ══════════════════════════════════════════════════════════════════════════════
# PACKAGES
# ══════════════════════════════════════════════════════════════════════════════
PKG_SPADES="spades_package"
PKG_COVERM="coverm_package"
PKG_BWA="bwa_package"
PKG_CHECKM2="checkm2_package"
PKG_SEQKIT="seqkit_package"
# ══════════════════════════════════════════════════════════════════════════════
# SLURM — MODULE 02a: ASSEMBLY + COVERAGE (array)
# ══════════════════════════════════════════════════════════════════════════════
PARTITION_ASSEMBLY="your_partition"
TIME_ASSEMBLY="24:00:00"
CPUS_ASSEMBLY=16
MEM_PER_CPU_ASSEMBLY="4G"

# ══════════════════════════════════════════════════════════════════════════════
# SLURM — MODULE 02b: CHECKM2 (single job)
# ══════════════════════════════════════════════════════════════════════════════
PARTITION_CHECKM2="your_partition"
TIME_CHECKM2="24:00:00"
CPUS_CHECKM2=10
MEM_PER_CPU_CHECKM2="10G"

# ══════════════════════════════════════════════════════════════════════════════
# SLURM — MODULE 03a: DREP (single job)
# ══════════════════════════════════════════════════════════════════════════════
PARTITION_DREP="your_partition"
TIME_DREP="06:00:00"
CPUS_DREP=8
MEM_PER_CPU_DREP="4G"

