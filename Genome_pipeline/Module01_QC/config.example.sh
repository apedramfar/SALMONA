
#!/bin/bash

# ══════════════════════════════════════════════════════════════════════════════
# INPUT / OUTPUT
# ══════════════════════════════════════════════════════════════════════════════
SAMPLE_SHEET="/path/to/samples.tsv"
OUT_DIR="/path/to/output"
LOG_DIR="/path/to/logs"

# ══════════════════════════════════════════════════════════════════════════════
# SEQUENCING
# ══════════════════════════════════════════════════════════════════════════════
TYPE="illumina"  # "illumina" or "mgi"

# ══════════════════════════════════════════════════════════════════════════════
# HOST REMOVAL
# ══════════════════════════════════════════════════════════════════════════════
HOST_REF="human"  # Set to a supported reference, e.g. "human" or "mouse"
HOSTILE_CACHE_DIR="/path/to/hostile/database"

# ══════════════════════════════════════════════════════════════════════════════
# DATABASES
# ══════════════════════════════════════════════════════════════════════════════
MET_DB="/path/to/metaphlan/database"

# ══════════════════════════════════════════════════════════════════════════════
# CONTAMINATION THRESHOLDS
# ══════════════════════════════════════════════════════════════════════════════
CONTAM_MAX_SPECIES=1
CONTAM_MIN_DOMINANT=80
CONTAM_MAX_UNCLASSIFIED=30

# ══════════════════════════════════════════════════════════════════════════════
# SOFTWARE PACKAGES
# Configure these for the HPC software environment.
# ══════════════════════════════════════════════════════════════════════════════
PKG_HOSTILE="hostile_package"
PKG_TRIMGALORE="trim_galore_package"
PKG_MULTIQC="multiqc_package"
PKG_METAPHLAN="metaphlan_package"

# ══════════════════════════════════════════════════════════════════════════════
# SLURM — MODULE 01a: QC + HOST REMOVAL
# ══════════════════════════════════════════════════════════════════════════════
PARTITION_QC="your_partition"
TIME_QC="03:00:00"
CPUS_QC=5
MEM_PER_CPU_QC="32G"

# ══════════════════════════════════════════════════════════════════════════════
# SLURM — MODULE 01b: METAPHLAN PROFILING
# ══════════════════════════════════════════════════════════════════════════════
PARTITION_METAPHLAN="your_partition"
TIME_METAPHLAN="08:00:00"
CPUS_METAPHLAN=10
MEM_PER_CPU_METAPHLAN="8G"

# ══════════════════════════════════════════════════════════════════════════════
# SLURM — MODULE 01c: QC MERGE + CONTAMINATION SUMMARY
# ══════════════════════════════════════════════════════════════════════════════
PARTITION_MERGE="your_partition"
TIME_MERGE="03:00:00"
