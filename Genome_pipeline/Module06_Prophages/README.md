# Module 06 — Prophage Detection and Classification

**Pipeline:** PHORAGER → vConTACT3  
**Software:** PHORAGER v0.5.0-beta | vConTACT3 v3.1.3  
**Execution environment:** Linux HPC with SLURM

## Overview

Module 06 identifies and characterises prophage sequences from bacterial genome assemblies using PHORAGER, then performs viral genome classification and network analysis using vConTACT3.

The workflow consists of four sequential SLURM jobs:

```text
Bacterial genome assemblies
            |
            v
06A — PHORAGER
  Prophage detection
  Annotation
  Prophage summary
            |
            v
06a2 — PHORAGER handoff
  Prepare prophage FASTA
            |
            v
06B — vConTACT3
  Viral classification
  Network analysis
            |
            v
06b2 — Final summary
  Collect assignments
  Generate summary tables
```

The main runner submits these jobs using SLURM's `--dependency=afterok` option, allowing each stage to start only when the preceding job has completed successfully.

**Note:** Correct error handling within each analysis script is necessary for a failed command to produce a failed SLURM job status.

## Directory Structure

```text
Module06_Prophages/
├── 06_run_prophage.sh
├── 06_check_prophage.sh
├── config.example.sh
├── modules/
│   ├── 06a_phorager.sh
│   ├── 06a2_prepare_vcontact3_input.sh
│   ├── 06b_vcontact3.sh
│   └── 06b2_vcontact3_summary.sh
├── scripts/
│   ├── make_prophage_summary.sh
│   └── count_prophages_per_host.py
└── README.md
```

The local `config.sh` is excluded from version control. Users should create their own configuration from `config.example.sh`.

## Requirements

- Linux-based HPC environment with SLURM
- Bash and standard Unix utilities
- PHORAGER v0.5.0-beta
- Nextflow, compatible with the installed PHORAGER version
- PHORAGER reference databases and required container images
- vConTACT3 v3.1.3 and its reference database
- Python 3 with pandas for the optional per-host prophage summary

Software installation and reference databases are managed externally and are not included in this repository.

## Input

The primary input is a directory containing bacterial genome assemblies in FASTA format.

Supported filename extensions:

- `.fasta`
- `.fa`
- `.fna`

The runner checks for at least one assembly file directly within `GENOME_DIR` before submitting any jobs.

## Configuration

Create a local configuration file:

```bash
cp config.example.sh config.sh
```

Update the paths, software environments and SLURM resources as appropriate.

Key configuration variables include:

| Variable | Purpose |
|---|---|
| `GENOME_DIR` | Directory containing bacterial genome assemblies |
| `OUT_DIR` | Main pipeline output directory |
| `LOG_DIR` | SLURM log directory |
| `PHORAGER_HOME` | PHORAGER installation directory |
| `PHORAGER_SHARED` | Shared PHORAGER resources |
| `PKG_NEXTFLOW` | HPC Nextflow environment |
| `PHORAGER_RESUME` | Enables resuming PHORAGER analyses |
| `PHORAGER_HANDOFF_MODE` | Selects filtered or consolidated prophage FASTA |
| `VCONTACT3_DB` | vConTACT3 reference database |
| `PKG_VCONTACT3` | HPC vConTACT3 environment |

SLURM partitions, walltimes, CPU counts and memory settings are configurable for each job.

The configuration file is designed to be adapted to the user's HPC environment.

## 06A — PHORAGER

Script: `modules/06a_phorager.sh`

The PHORAGER stage performs three operations:

1. `phorager prophage` — detects prophage regions from bacterial genome assemblies.
2. `phorager annotation` — annotates the detected prophage sequences.
3. `phorager summarize --type prophage_table` — generates the prophage summary table.

The downstream workflow expects PHORAGER outputs including:

**Consolidated prophage sequences**

```text
2.Prophage_detection/Proph3_Comparison/<sample>/<sample>_prophage_sequences.fasta
```

**CheckV-filtered prophage sequences**

```text
3.Annotation/Anno1_CheckV/filtered_prophages.fasta
```

**Prophage summary**

```text
prophage_table.tsv
```

These are expected paths for the configured PHORAGER workflow and should be checked against the installed release.

## 06a2 — PHORAGER to vConTACT3 Handoff

Script: `modules/06a2_prepare_vcontact3_input.sh`

This stage prepares a single FASTA file for vConTACT3.

Two input modes are supported.

### Filtered mode (default)

```bash
PHORAGER_HANDOFF_MODE="filtered"
```

Uses the CheckV-filtered PHORAGER FASTA:

```text
3.Annotation/Anno1_CheckV/filtered_prophages.fasta
```

### Consolidated mode

```bash
PHORAGER_HANDOFF_MODE="consolidated"
```

Concatenates non-empty per-host files matching:

```text
*_prophage_sequences.fasta
```

from `Proph3_Comparison`.

Both modes create:

```text
06_prophage_handoff/
├── phorager_prophages_for_vcontact3.fasta
└── handoff_summary.tsv
```

The script checks that the input exists, is non-empty and contains FASTA sequence headers.

The handoff summary records the source, mode and sequence count.

**Important:** The handoff script does not independently assess sequence quality or remove duplicate sequences.

## 06B — vConTACT3

Script: `modules/06b_vcontact3.sh`

vConTACT3 receives the FASTA prepared during the handoff stage.

The analysis is configured with:

- Prokaryotic virus reference database
- Configurable thread count and `--breaks` parameter
- Taxonomic target ranks: order, family, subfamily and genus
- Export formats: GraphML, Cytoscape, D3, Cosmograph, completeness and protein-cluster profiles

Outputs are written to:

```text
06_vcontact3/
```

Taxonomic assignments are computational predictions based on the selected database and analysis settings.

## 06b2 — Final Results

Script: `modules/06b2_vcontact3_summary.sh`

The final stage collects the classification results and creates:

```text
00_final_results/
└── 06_prophage/
    ├── final_assignments.csv
    ├── handoff_summary.tsv
    └── module06_summary.tsv
```

If available, `query_not_in_network.txt` is also copied into the final results directory.

The `module06_summary.tsv` file includes:

- Selected PHORAGER handoff mode
- Number of input FASTA sequences
- Number of vConTACT3 assignment rows
- Reference database path
- vConTACT3 breaks parameter

The assignment-row count should not automatically be interpreted as the number of unique prophages.

## Run the Pipeline

After configuring the required paths and software environments:

```bash
bash 06_run_prophage.sh
```

The runner submits the four jobs in dependency order.

Monitor the jobs using:

```bash
squeue -u $USER
```

Inspect the configured SLURM log directory if a job fails.

## Validate Results

After all jobs finish:

```bash
bash 06_check_prophage.sh
```

The checker examines the expected PHORAGER, handoff, vConTACT3 and final summary outputs.

It also reports counts of supported network export files and can run additional summary utilities.

## Supporting Scripts

### `make_prophage_summary.sh`

Creates a per-host comparison of prophage counts reported by geNomad, VIBRANT and the consolidated PHORAGER results.

The script expects the corresponding PHORAGER detection output directories and coordinate tables.

Output:

```text
prophage_caller_summary.tsv
```

### `count_prophages_per_host.py`

Uses pandas to summarise the PHORAGER prophage table by bacterial host, including:

- Prophage counts
- Number of unique clusters
- CheckV quality categories
- Mean phage length

Output:

```text
prophage_counts_per_host.tsv
```

These scripts support output inspection and are not submitted as separate jobs by the main runner.

## Important Notes and Limitations

- The pipeline requires a configured HPC environment; it is not designed to execute directly on macOS.
- PHORAGER output paths and database dependencies may differ across releases.
- The original installation used Nextflow 22.10.7. Compatibility should be verified against the installed PHORAGER version.
- `PHORAGER_HANDOFF_MODE` determines which sequences enter vConTACT3 and can therefore affect downstream classifications.
- The runner's SLURM dependencies require analysis scripts to return a non-zero exit status when critical commands fail.
- Prophage detection, CheckV quality assessment and taxonomic assignments provide computational evidence; they do not independently establish prophage inducibility or infectivity.
- The optional pandas-based summary requires the expected input column names and appropriate numeric values.

## Documentation

- **PHORAGER:** https://github.com/aponsero/PHORAGER
- **vConTACT3:** https://vcontact3.readthedocs.io/en/latest/installation.html

Further software references and citations can be maintained in the main repository documentation.