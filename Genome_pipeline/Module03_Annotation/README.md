# Module 03 — Genome Dereplication & Annotation

## Overview

This module performs genome dereplication using dRep, followed by functional genome annotation with Bakta. It is designed to run after Module02_Assembly, once genome assembly quality has been assessed.

The workflow was developed for execution on the Quadram Institute HPC cluster using SLURM. It consists of three dependent processing steps: genome dereplication, genome annotation, and consolidation of results.

The final step integrates assembly quality metrics, sequencing coverage, dRep clustering information, and annotation outputs to support downstream comparative genomic analyses.

## Tools and dependencies

| Tool | Version | Purpose |
|---|---|---|
| dRep | To be confirmed | Genome dereplication and clustering |
| Bakta | 1.11.4 | Bacterial genome annotation |
| Bakta database | v6 | Reference database for annotation |
| GNU Bash | 5.1.8 | Workflow execution |
| SLURM | 23.02.8 | HPC job scheduling and dependency management |

Software packages and reference databases are managed separately from the repository and must be configured according to the computing environment.

## Module structure

```text
Module03_Annotation/
├── 03_run_annotation.sh
├── 03_check_annotation.sh
├── config.example.sh
├── config.sh                  # Local configuration, excluded from Git
├── README.md
└── modules/
    ├── 03a_drep.sh
    ├── 03b_bakta.sh
    └── 03c_merge.sh
```

## Configuration

The workflow uses a shared Bash configuration file containing input/output paths, software package identifiers, database locations, analysis parameters, and SLURM resource settings.

A reusable template is provided as `config.example.sh`.

### 1. Create the local configuration

From the `Module03_Annotation` directory:

```bash
cp config.example.sh config.sh
```

Edit the file:

```bash
nano config.sh
```

The local configuration is excluded from version control through `.gitignore`.

### 2. Configure input and output paths

```bash
SAMPLE_SHEET="/path/to/samples.tsv"
OUT_DIR="/path/to/output"
LOG_DIR="/path/to/logs"
```

The `OUT_DIR` must point to the same analysis directory used by Module02_Assembly because Module03 requires assembled genome FASTA files and CheckM2 quality reports.

### 3. Configure software and databases

```bash
BAKTA_DB="/path/to/bakta/database"

PKG_BAKTA="bakta_package"
PKG_DREP="drep_package"
```

Replace the package placeholders with identifiers supported by the HPC environment.

The Bakta reference database must be installed separately and configured through `BAKTA_DB`.

### 4. Configure analysis parameters

```bash
DREP_ANI=0.99
BAKTA_SPECIES="mixed"
```

| Parameter | Default | Description |
|---|---|---|
| `DREP_ANI` | 0.99 | ANI threshold used for dRep secondary clustering |
| `BAKTA_SPECIES` | `mixed` | Configuration setting for species information supplied to Bakta |

The behaviour of `BAKTA_SPECIES` depends on how it is handled in `03b_bakta.sh`. The value `mixed` should not be assumed to be a valid scientific species name passed directly to Bakta.

### 5. Configure SLURM resources

| Processing step | Time limit | CPUs | Memory per CPU |
|---|---|---:|---|
| dRep | 12 hours | 8 | 4 GB |
| Bakta | 12 hours | 8 | 8 GB |
| Results merging | 6 hours | Configured by runner | Configured by runner |

Partition names must be adapted to the local HPC environment.

## How to run

### 1. Confirm Module02 has completed

Ensure that the assembled genome FASTA files are available in:

```text
$OUT_DIR/02_assembly/fasta/
```

And that the assembly quality report is available at:

```text
$OUT_DIR/00_final_results/02_assembly/checkm2_quality_report.tsv
```

Review the Module02 assembly quality summary before proceeding. Samples requiring exclusion should be removed from the sample sheet according to the study's quality criteria.

### 2. Launch Module03

From the `Module03_Annotation` directory:

```bash
bash 03_run_annotation.sh
```

The runner submits three dependent SLURM processing steps:

```text
03a_drep           (Single job — genome dereplication)
       |
       v
03b_bakta          (Job array — genome annotation)
       |
       v
03c_merge          (Single job — results consolidation)
```

**Step 03a — Genome dereplication**

dRep clusters assembled genomes according to their genomic similarity and the configured clustering threshold.

**Step 03b — Genome annotation**

Bakta annotates the assembled genomes, producing gene annotations, protein sequences, and functional annotation tables.

**Step 03c — Results consolidation**

The merge step collects dRep assignments and Bakta outputs, integrating them with available assembly quality and coverage metrics.

### 3. Check outputs

After all submitted jobs have completed:

```bash
bash 03_check_annotation.sh
```

The checker verifies expected Bakta outputs, reports dRep clustering results, and displays the combined assembly and annotation quality summary.

## Expected outputs

```text
output_dir/
├── 03_annotation/
│   ├── drep/
│   │   ├── data_tables/
│   │   │   ├── Cdb.csv
│   │   │   └── Widb.csv
│   │   └── ...
│   │
│   └── bakta/
│       └── {sample_id}/
│           ├── {sample_id}.gff3
│           ├── {sample_id}.faa
│           ├── {sample_id}.tsv
│           └── ...
│
└── 00_final_results/
    └── 03_annotation/
        ├── drep_clusters.csv
        ├── drep_representatives.csv
        ├── gff3/
        │   └── {sample_id}.gff3
        ├── faa/
        │   └── {sample_id}.faa
        └── assembly_annotation_summary.tsv
```

### Aggregated results

| Output | Description |
|---|---|
| `drep_clusters.csv` | dRep cluster assignments |
| `drep_representatives.csv` | dRep representative genome information |
| `gff3/` | Collected Bakta GFF3 annotation files |
| `faa/` | Collected predicted protein sequences |
| `assembly_annotation_summary.tsv` | Combined assembly quality, coverage, and dereplication information |

### `assembly_annotation_summary.tsv` columns

| Column | Description |
|---|---|
| `sample_id` | Sample identifier |
| `completeness` | CheckM2-estimated genome completeness (%) |
| `contamination` | CheckM2-estimated genome contamination (%) |
| `contig_n50` | Assembly N50, where available from upstream results |
| `mean_coverage` | Mean genome coverage estimated by CoverM |
| `drep_cluster` | dRep cluster assignment |
| `drep_representative` | Indicates whether the genome was selected as a cluster representative |

## Genome dereplication

The workflow uses dRep to group genomes based on genomic similarity, with a default secondary clustering ANI threshold of 99%.

Genomes assigned to the same cluster exhibit high genomic similarity under the selected clustering criteria. However, clustering at 99% ANI does not necessarily establish that genomes belong to the same biological strain.

Representative genomes are selected according to dRep's configured scoring and quality assessment procedures.

All genomes are intended to undergo Bakta annotation, regardless of their dRep representative status.

## Quality assessment

The annotation checker uses the assembly quality thresholds defined upstream:

| Parameter | Threshold |
|---|---:|
| Minimum completeness | 90% |
| Maximum contamination | 5% |
| Minimum mean coverage | 20× |

Samples failing these criteria are flagged for further review.

Warnings do not automatically terminate the workflow or exclude genomes. Quality thresholds should be interpreted in the context of the sequencing data, assembly characteristics, and study objectives.

## Reproducibility and data availability

This repository provides the workflow scripts, example configuration, and supporting documentation.

Raw sequencing datasets, reference databases, genome assemblies, and generated analysis outputs are maintained separately.

Users must configure the appropriate software environments, database locations, SLURM resources, and input/output directories before running the workflow.