# Module 02 — Genome Assembly & Quality Assessment

## Overview

This module performs *de novo* genome assembly of quality-controlled paired-end sequencing reads from bacterial isolates, estimates sequencing coverage by mapping reads back to assembled genomes, and evaluates genome completeness and contamination.

The workflow was developed for execution on the Quadram Institute HPC cluster using SLURM. It consists of two dependent processing steps: genome assembly and coverage estimation, followed by CheckM2-based assembly quality assessment.

The resulting quality metrics support the identification of assemblies requiring further review before proceeding to downstream genomic analyses.

## Tools and dependencies

| Tool | Version | Purpose |
|---|---|---|
| SPAdes | 3.15.5 | *De novo* genome assembly using isolate mode |
| SeqKit | 2.8.2 | Contig length filtering |
| CoverM | 0.7.0 | Read mapping and genome coverage estimation |
| CheckM2 | 1.0.2 | Genome completeness and contamination assessment |
| BWA | To be verified | Read alignment used by CoverM |
| Conda | Environment-dependent | Software environment management |
| GNU Bash | 5.1.8 | Workflow execution |
| SLURM | 23.02.8 | HPC job scheduling and dependency management |
| bc | 1.07.1 | Numerical comparisons for assembly quality screening |

Software and reference databases are managed separately from the repository. The exact software environments may require adaptation for other HPC systems.

## Module structure

```text
Module02_Assembly/
├── 02_run_assembly.sh
├── 02_check_assembly.sh
├── config.example.sh
├── config.sh                  # Local configuration, not tracked by Git
├── README.md
└── modules/
    ├── 02a_assembly_coverage.sh
    └── 02b_checkm2.sh
```

A locally maintained CoverM container may also be used depending on the software environment. Container images are not distributed through this repository.

## Configuration

The workflow uses a Bash configuration file containing input/output paths, database locations, software package identifiers, assembly parameters, and SLURM resource settings.

A reusable template is provided as `config.example.sh`.

### 1. Create the local configuration

From the `Module02_Assembly` directory:

```bash
cp config.example.sh config.sh
```

Edit the configuration:

```bash
nano config.sh
```

The local `config.sh` is excluded from Git through `.gitignore`.

### 2. Configure input and output paths

```bash
SAMPLE_SHEET="/path/to/samples.tsv"
OUT_DIR="/path/to/output"
LOG_DIR="/path/to/logs"
```

The `OUT_DIR` must refer to the same analysis directory used by Module01_QC, since Module02 reads quality-controlled sequencing data from:

```text
$OUT_DIR/01_qc/trimming/
```

### 3. Configure reference databases and software

```bash
CHECKM2DB="/path/to/checkm2/database.dmnd"

PKG_SPADES="spades_package"
PKG_COVERM="coverm_package"
PKG_BWA="bwa_package"
PKG_CHECKM2="checkm2_package"
PKG_SEQKIT="seqkit_package"
```

Software package identifiers must be adapted to the HPC environment.

The CheckM2 reference database must be available separately and its path specified in `CHECKM2DB`.

### 4. Assembly parameters and QC thresholds

| Parameter | Default | Description |
|---|---:|---|
| `MIN_CONTIG_LENGTH` | 500 bp | Minimum contig length retained after assembly |
| `MIN_COMPLETENESS` | 90% | Minimum CheckM2-estimated completeness |
| `MAX_CONTAMINATION` | 5% | Maximum CheckM2-estimated contamination |
| `MIN_COVERAGE` | 20× | Minimum mean genome coverage estimated by CoverM |

These thresholds are configurable and serve as preliminary assembly quality-screening criteria.

### 5. SLURM resource configuration

The workflow provides configurable SLURM settings for both processing steps.

| Resource | Assembly and coverage | CheckM2 |
|---|---|---|
| Time limit | 24 hours | 24 hours |
| CPUs | 16 | 10 |
| Memory per CPU | 4 GB | 10 GB |
| Partition | User-configured | User-configured |

Users should adapt these allocations to their HPC resources and dataset size.

## How to run

### 1. Confirm Module01 has completed

Ensure that quality-controlled paired-end reads are available for all samples in:

```text
$OUT_DIR/01_qc/trimming/
```

The Module01 output checker can be run from its own directory:

```bash
bash 01_check_qc.sh
```

Review any reported warnings before proceeding.

### 2. Launch Module02

From the `Module02_Assembly` directory:

```bash
bash 02_run_assembly.sh
```

The runner submits two SLURM jobs in dependency order:

```text
02a_assembly_coverage       (Job array — one task per sample)
          |
          v
02b_checkm2                 (Single job — assembly quality assessment)
```

**Step 02a — Assembly and coverage**

- Performs *de novo* assembly using SPAdes isolate mode.
- Filters contigs shorter than the configured minimum length using SeqKit.
- Maps cleaned sequencing reads back to filtered assemblies using CoverM.
- Produces per-sample genome FASTA files and coverage reports.

**Step 02b — Assembly quality assessment**

- Evaluates genome completeness and contamination using CheckM2.
- Collects coverage measurements across samples.
- Generates combined assembly quality reports.

### 3. Check outputs

After all jobs have completed:

```bash
bash 02_check_assembly.sh
```

The checker verifies expected output files and evaluates genome quality metrics against the configured thresholds.

Flagged assemblies should be reviewed before downstream analyses.

## Expected outputs

```text
output_dir/
├── 02_assembly/
│   ├── fasta/
│   │   └── {sample_id}.fasta
│   │
│   ├── coverage/
│   │   └── {sample_id}_coverage.tsv
│   │
│   └── checkm2/
│       └── quality_report.tsv
│
└── 00_final_results/
    └── 02_assembly/
        ├── checkm2_quality_report.tsv
        └── coverage_summary.tsv
```

Temporary SPAdes working directories may be removed after successful assembly and contig filtering.

### Aggregated quality reports

| Output | Description |
|---|---|
| `checkm2_quality_report.tsv` | CheckM2 completeness and contamination estimates |
| `coverage_summary.tsv` | Combined per-sample mean genome coverage estimates |

### `coverage_summary.tsv` columns

| Column | Description |
|---|---|
| `sample_id` | Sample identifier |
| `mean_coverage` | Mean genome coverage estimated by CoverM |

## Assembly quality screening

The `02_check_assembly.sh` script evaluates assemblies using the following criteria:

| Warning | Condition |
|---|---|
| `low_completeness` | Completeness below `MIN_COMPLETENESS` |
| `high_contamination` | Contamination above `MAX_CONTAMINATION` |
| `low_coverage` | Mean genome coverage below `MIN_COVERAGE` |

These quality thresholds support preliminary screening. They should not be interpreted as definitive indicators of genome quality without considering assembly characteristics, sequencing data, and the biological context.

Warnings do not automatically remove samples or stop downstream analyses. Flagged assemblies should be reviewed manually before proceeding to Module03.

## Reproducibility and data availability

This repository provides the analysis scripts, example configuration, and workflow documentation.

Raw sequencing datasets, reference databases, generated assemblies, analysis outputs, and large container images are maintained separately.

Users must configure the required software environments, reference database paths, SLURM resources, and input/output locations before executing the workflow.

## References and documentation

The following publications and resources describe the principal software tools used in Module02.

**SPAdes — Genome assembly** :Bankevich, A., Nurk, S., Antipov, D., et al. (2012). SPAdes: A New Genome Assembly Algorithm and Its Applications to Single-Cell Sequencing. *Journal of Computational Biology*, 19(5), 455–477. Software: https://github.com/ablab/spades

**SeqKit — FASTA/Q processing**: Shen, W., Le, S., Li, Y., & Hu, F. (2016). SeqKit: A Cross-Platform and Ultrafast Toolkit for FASTA/Q File Manipulation. *PLOS ONE*, 11(10), e0163962. Software: https://github.com/shenwei356/seqkit

**CoverM — Coverage estimation**: Aroney, S. T., et al. (2025). CoverM: Read alignment statistics for metagenomics. *Bioinformatics*, 41(4), btaf147. Software: https://github.com/wwood/CoverM

**CheckM2 — Genome quality assessment**: Chklovski, A., Parks, D. H., Woodcroft, B. J., & Tyson, G. W. (2023). CheckM2: a rapid, scalable and accurate tool for assessing microbial genome quality using machine learning. *Nature Methods*, 20, 1203–1212. Software: https://github.com/chklovski/CheckM2

**Additional software**

- BWA: https://github.com/lh3/bwa
- SLURM: https://slurm.schedmd.com/

For detailed methodological explanations and interpretation of quality metrics, see the GitHub Wiki page **Module 02 — Genome Assembly and Quality Assessment**.
