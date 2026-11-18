
# Changelog

All notable changes to SALMONA (Salmonella Omics and Genomic Analysis) will be documented here.

## [Unreleased]

### Planned
- Further workflow integration and standardisation.
- Improvements to documentation and portability.
- Additional validation and testing.

## [v0.1.0-beta] - 2026-11-18

### Initial Beta Release

- Introduced eight modular Bash/SLURM analysis workflows:
  - Module 00 — Setup and sample sheet preparation
  - Module 01 — Quality control
  - Module 02 — Genome assembly and quality assessment
  - Module 03 — Genome dereplication and annotation
  - Module 04 — In silico serotyping
  - Module 05 — AMR and mobile genetic element analysis
  - Module 06 — Prophage analysis
  - Module 07 — MLST, wgMLST and cgMLST
- Added module-specific README files and example configurations.
- Added GitHub Wiki documentation.

The workflows were developed for research use in a Linux HPC environment using SLURM.
