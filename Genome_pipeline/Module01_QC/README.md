# Module 01 — Read QC, Host Removal & Contamination Check

## Overview

This module performs read quality control and host-read removal on paired-end Illumina or MGI short-read sequencing data from bacterial isolates. It additionally uses MetaPhlAn for taxonomic profiling to identify potentially mixed cultures or contaminated isolates before proceeding to genome assembly.

The module was developed for execution on the Quadram Institute HPC cluster using SLURM. It consists of three dependent processing steps submitted through a single runner script.

## Tools and dependencies

| Tool | Version | Purpose |
|---|---|---|
| Hostile | 2.0.0 | Host-read removal |
| Trim Galore | 0.6.10 | Adapter trimming and quality filtering |
| FastQC | To be confirmed | Per-sample sequencing read quality assessment |
| MultiQC | 1.19 | Aggregated quality control reporting |
| MetaPhlAn | 4.1.1 | Taxonomic profiling and potential contamination assessment |
| jq | 1.6 | Parsing Hostile JSON output |
| bc | 1.07.1 | Numerical comparisons for contamination screening |
| GNU Bash | 5.1.8 | Workflow execution |
| SLURM | 23.02.8 | HPC job scheduling and dependency management |

Software is managed through the institute's HPC environment. Software package identifiers and reference database locations must be configured for the execution environment.

**Note:** FastQC is invoked by Trim Galore but was not available in the inspected interactive HPC environment. Its installation and version remain to be confirmed before reproducing the workflow.

## Module structure

```text
Module01_QC/
├── 01.run_qc.sh
├── 01_check_qc.sh
├── config.sh
├── README.md
└── modules/
    ├── 01a_qc_host_removal.sh
    ├── 01b_metaphlan_profiling.sh
    └── 01c_qc_merge.sh
```

## How to run

### 1. Prepare the sample sheet

Provide a tab-separated file containing one sample per line, with three columns:

```text
sample_id	read1	read2
isolate_01	/path/to/isolate_01_R1.fastq.gz	/path/to/isolate_01_R2.fastq.gz
```

Sample identifiers should not contain spaces.

### 2. Configure `config.sh`

Set the input, output, log, and reference database paths:

```bash
SAMPLE_SHEET="/path/to/samples.tsv"
OUT_DIR="/path/to/output"
LOG_DIR="/path/to/logs"

HOSTILE_CACHE_DIR="/path/to/hostile/database"
MET_DB="/path/to/metaphlan/database"

TYPE="illumina"    # or "mgi"
HOST_REF="human"   # or "mouse"
```

Configure the relevant HPC software package identifiers for Hostile, Trim Galore, MetaPhlAn, and MultiQC.

The default contamination-screening thresholds are:

```bash
CONTAM_MAX_SPECIES=1        # Flag if more than one species is detected
CONTAM_MIN_DOMINANT=80      # Flag if dominant species abundance is below 80%
CONTAM_MAX_UNCLASSIFIED=30  # Flag if unclassified percentage exceeds 30%
```

These thresholds are configurable according to study requirements.

### 3. Launch the module

From the `Module01_QC` directory, run:

```bash
bash 01.run_qc.sh
```

The runner submits three SLURM jobs in dependency order:

```text
01a_qc_host_removal       (Job array — one task per sample)
          |
          v
01b_metaphlan_profiling   (Job array — one task per sample)
          |
          v
01c_qc_merge              (Single aggregation job)
```

### 4. Check outputs

Once all jobs have completed, run:

```bash
bash 01_check_qc.sh
```

The script verifies the expected QC outputs and displays a contamination-screening summary.

Samples flagged as potentially mixed or contaminated should be reviewed before proceeding to genome assembly. Warnings do not automatically exclude samples.

## Expected outputs

```text
output_dir/
└── 01_qc/
    ├── host_removal/
    │   └── {sample_id}_hostmap.json
    │
    ├── trimming/
    │   ├── {sample_id}_clean_R1.fq.gz
    │   └── {sample_id}_clean_R2.fq.gz
    │
    ├── fastqc/
    │   ├── {sample_id}_R1_fastqc.html
    │   ├── {sample_id}_R1_fastqc.zip
    │   ├── {sample_id}_R1_trimming_report.txt
    │   └── ...
    │
    ├── metaphlan/
    │   └── {sample_id}.unclprofile.txt
    │
    └── aggregated/
        ├── multiqc/
        │   └── multiqc_report.html
        ├── hostile_summary.csv
        ├── contamination_summary.tsv
        └── metaphlan_merged.tsv
```

The cleaned paired-end FASTQ files in `01_qc/trimming/` are intended for downstream genome assembly in Module02.

### Aggregated reports

| Output | Description |
|---|---|
| `multiqc/multiqc_report.html` | Combined FastQC quality assessment |
| `hostile_summary.csv` | Per-sample Hostile read-removal statistics |
| `contamination_summary.tsv` | Taxonomic screening results and warning flags |
| `metaphlan_merged.tsv` | Merged MetaPhlAn taxonomic profiles |

## Contamination screening

The `contamination_summary.tsv` file contains:

| Column | Description |
|---|---|
| `sample_id` | Sample identifier |
| `species_count` | Number of species detected in the MetaPhlAn profile |
| `top_species` | Most abundant species |
| `top_species_abundance` | Relative abundance of the dominant species (%) |
| `unclassified_pct` | Percentage reported as unclassified |
| `status` | `OK` or `WARN`, including warning reasons |

### Warning criteria

| Warning | Condition |
|---|---|
| `high_unclassified` | Unclassified percentage exceeds 30% |
| `mixed_isolate` | More than one species is detected |
| `low_dominant` | Dominant species relative abundance is below 80% |

The thresholds are defined in `config.sh` and may be modified.

These criteria provide preliminary screening for potentially mixed or contaminated isolates. They are not definitive contamination diagnoses and should be interpreted alongside sequencing quality and other taxonomic evidence.

Warnings do not terminate the workflow. Flagged samples should be reviewed manually before proceeding to Module02_Assembly.

## Reproducibility and configuration

The workflow relies on SLURM, institute-managed software packages, and external reference databases.

For execution on another HPC system, users must configure the relevant software environments, database locations, sequencing input paths, and output directories.

The repository contains workflow scripts and documentation; sequencing datasets, reference databases, and generated analysis results are maintained separately.