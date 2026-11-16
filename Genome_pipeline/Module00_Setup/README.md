# Module 00 — Sample Sheet Generation

## Overview

This module prepares sample sheets for downstream bioinformatics analyses of paired-end whole-genome sequencing data from *Salmonella* isolates.

The `generate_sample_sheet.sh` script identifies paired-end FASTQ files and generates a tab-separated sample sheet (`samples.tsv`) containing sample identifiers and their corresponding sequencing read paths.

## Requirements

| Software | Version | Purpose |
|---|---|---|
| Bash | 4.x or later recommended | Script execution |
| Standard Unix utilities | System-provided | File and directory operations |

No additional bioinformatics software or Conda environment is required.

## Input files

The script expects paired-end, gzip-compressed FASTQ files following the Illumina naming convention:

```text
reads/
├── Sample01_R1_001.fastq.gz
├── Sample01_R2_001.fastq.gz
├── Sample02_R1_001.fastq.gz
└── Sample02_R2_001.fastq.gz
```

## Usage

Configure the input and output paths in `generate_sample_sheet.sh`:

```bash
READS_DIR="./reads"
OUTPUT="./samples.tsv"
```

Execute the script:

```bash
bash generate_sample_sheet.sh
```

Run the script from the directory relative to which the configured paths should be resolved.

## Output

The script generates a tab-separated file named `samples.tsv` with three columns:

| Column | Description |
|---|---|
| `sample_id` | Unique sample identifier |
| `read1` | Path to the forward sequencing reads (R1) |
| `read2` | Path to the reverse sequencing reads (R2) |

Example:

```text
sample_id    read1                         read2
Sample01     ./reads/Sample01_R1_001.fastq.gz ./reads/Sample01_R2_001.fastq.gz
```

The actual file uses tab characters as column separators.

## Notes and limitations

- Input files must follow the specified `_R1_001.fastq.gz` and `_R2_001.fastq.gz` naming conventions.
- Input and output paths must be configured before execution.
- The generated sample sheet is intended for use by downstream analysis modules.
- This module does not perform sequencing quality control or validate FASTQ file contents.

## Reproducibility

This module uses standard Bash and Unix command-line utilities. 