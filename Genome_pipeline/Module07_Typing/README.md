# Module 07 — Genomic Typing (chewBBACA + MLST)

## Overview

Module 07 performs genomic typing of *Salmonella* isolates using **chewBBACA** for whole-genome and core-genome multilocus sequence typing (wgMLST/cgMLST), alongside classical seven-locus MLST.

The workflow is designed for a SLURM-managed HPC environment and accepts assembled genomes in `.fasta` format, either from Module 02 or from independently generated assemblies.

Three analysis jobs run in parallel, followed by a merge job that collects the final typing results.

## Software

| Tool | Version used | Purpose |
|---|---|---|
| chewBBACA | 3.5.4 | wgMLST and cgMLST allele calling, core-locus extraction and evaluation |
| mlst | 2.35.0 | Classical seven-locus MLST |
| GrapeTree | Optional | Visualisation of allelic relationships |

The workflow was developed for an HPC environment using SLURM. Software-loading commands and computational resources may need to be adapted to other systems.

## Workflow

```text
Assembled bacterial genomes (.fasta)
                |
                v
       07_run_chewBBACA.sh
                |
       Generate genome manifest
                |
        +-------+--------+
        |       |        |
        v       v        v
       07a     07b      07c
     Existing Custom    MLST
     schema   schema
        |       |        |
        +-------+--------+
                |
                v
           07d_merge
                |
                v
         Final typing results
                |
                v
       GrapeTree (optional)
```

### 07a — Existing Salmonella schema

This analysis uses an existing, prepared Salmonella wgMLST schema.

1. Perform whole-genome allele calling (`AlleleCall`).
2. Extract a study-specific core-genome locus set (`ExtractCgMLST`).
3. Perform allele calling using the extracted core loci.
4. Generate an allele-calling evaluation report (`AlleleCallEvaluator`).

The core genome is derived from the input genomes using chewBBACA's 95% core threshold. Therefore, the number of core loci may vary between datasets.

### 07b — Custom 320-reference schema

**Custom schema availability:** The custom cgMLST schema was developed using 320 reference genomes and includes a predefined set of 3,153 core loci. The schema and associated reference files are not currently included in this repository. Information on their availability, construction and use will be updated following publication of the complete pipeline.

This analysis uses a custom schema developed from 320 reference genomes and a predefined core-locus list.

1. Perform core-genome allele calling using the supplied locus list.
2. Generate an allele-calling evaluation report.

The original analysis used a predefined set of **3,153 core loci**. Users applying this workflow to other datasets must supply their own compatible schema and core-locus list.

### 07c — Classical MLST

Classical MLST is performed using the `salmonella` scheme, producing individual sequence-type assignments and a summary of ST frequencies.

### 07d — Merge results

The merge job collects the two chewBBACA core allele matrices and the classical MLST outputs into a single results directory.

## Setup and execution

Run the following commands from the `Module07_Typing` directory.

### 1. Configure the pipeline

Create a local configuration file:

```bash
cp config.example.sh config.sh
```

Edit `config.sh` to specify your input assemblies, output directory, schema locations, software packages, MLST database and SLURM settings.

For example:

```bash
# One assembly directory
GENOME_DIR="/path/to/assemblies"

# Alternatively, multiple directories
GENOME_DIR="/path/to/batch1;/path/to/batch2"

# Expected number of assemblies
EXPECTED_SALMONELLA=100

# Output directory, preferably outside the repository
OUT_DIR="/path/to/typing_results"

# Existing wgMLST schema
CHEW_EXISTING_SCHEMA="/path/to/original_schema"
CHEW_PREPARED_SCHEMA="/path/to/prepared_schema"

# Custom schema and core locus list
CHEW_CUSTOM_SCHEMA="/path/to/custom_schema/schema_seed"
CHEW_CUSTOM_CORE="/path/to/custom_core/cgMLSTschema95.txt"

# Classical MLST scheme
MLST_SCHEME="salmonella"
```

The expected assembly count is configurable. The original study analysed 426 assemblies across four batches.

The local `config.sh` is excluded from Git tracking.

### 2. Prepare the external schema (if required)

An external wgMLST schema may require preparation before it can be used with chewBBACA.

If the schema is not already prepared, run:

```bash
bash 07_prep_schema.sh
```

This submits a SLURM job that executes `PrepExternalSchema` and writes the prepared schema to `CHEW_PREPARED_SCHEMA`.

This step is required only when using an unprepared external schema. If a compatible prepared schema is already available, it can be used directly.

**Schema files are not distributed with this repository.** Users must obtain or generate their own compatible schemas and configure the corresponding paths.

### 3. Run genomic typing

```bash
bash 07_run_chewBBACA.sh
```

The runner checks the input directories and required schemas, builds the genome manifest, and submits four SLURM jobs:

- `07a_chew_existing` — existing-schema wgMLST/cgMLST analysis
- `07b_chew_custom320` — custom-schema core allele calling
- `07c_mlst` — classical seven-locus MLST
- `07d_merge` — collection of final results

The merge job uses SLURM `afterok` dependencies so that it starts only after all three preceding jobs report successful completion.

### 4. Check the results

After all jobs have completed, run:

```bash
bash 07_check_chewBBACA.sh
```

This checks for expected output directories and files and reports missing or empty results.

Review the SLURM logs and the generated reports to assess the quality and completeness of the analyses.

## Expected outputs

```text
output_dir/
├── 07_typing/
│   ├── 00_inputs/
│   │   └── study_genomes.list
│   ├── 01_existing_schema/
│   │   ├── wg_call/
│   │   ├── cgMLST/
│   │   │   ├── cgMLSTschema95.txt
│   │   │   └── cgMLST95.tsv
│   │   ├── core_call/
│   │   └── report/
│   ├── 02_custom320/
│   │   ├── 01_core_allele_call/
│   │   └── 02_allelecall_report/
│   └── 03_mlst/
│       ├── mlst_results.tsv
│       └── st_summary.tsv
│
└── 00_final_results/
    └── 07_typing/
        ├── existing_schema_core_results_alleles.tsv
        ├── custom320_core_results_alleles.tsv
        ├── mlst_results.tsv
        └── st_summary.tsv
```

The final directory contains:

| File | Description |
|---|---|
| `existing_schema_core_results_alleles.tsv` | Study-specific cgMLST allele profiles |
| `custom320_core_results_alleles.tsv` | Allele profiles from the predefined custom core |
| `mlst_results.tsv` | Classical MLST assignments |
| `st_summary.tsv` | Sequence-type frequency summary |

## Downstream visualisation with GrapeTree

Allelic relationships between isolates can be explored using [GrapeTree](https://github.com/achtman-lab/GrapeTree), which supports visualisation of minimum-spanning trees from allelic profiles.

The chewBBACA `results_alleles.tsv` matrices can be prepared for GrapeTree by checking sample identifiers, table orientation and missing-allele representations, and ensuring that the file matches GrapeTree's supported input format.

The **MSTreeV2** algorithm can then be used to investigate relationships between isolates.

For meaningful comparisons, profiles should originate from the same schema and locus set. Results from the existing and custom schemas should not be combined directly into a single allele-distance analysis.

GrapeTree visualisation is optional and is not automatically executed by Module07.

## Important notes

**Input flexibility:** `GENOME_DIR` accepts one directory or multiple directories separated by semicolons. The current scripts collect `.fasta` files directly within those directories, without searching subdirectories.

**Assembly count:** `EXPECTED_SALMONELLA` is used to verify the total number of input assemblies. This does not identify species or assess genome quality. Input assemblies should therefore be checked beforehand.

**Schema compatibility:** The original and prepared schemas must be configured correctly. A custom core-locus list must correspond to the custom schema used for allele calling.

**Output directories:** Some analysis steps remove and recreate their output directories when rerun. Existing results should be backed up before repeating an analysis.

**Merge behaviour:** Missing intermediate files generate warnings during the merge stage. Users should verify that all four final output files are present and non-empty.

**HPC environment:** Scripts use SLURM and an HPC-specific `source package` mechanism. Researchers using other systems must adapt the software-loading commands and resource settings.

## Documentation

- [chewBBACA documentation](https://chewbbaca.readthedocs.io/)
- [chewBBACA GitHub repository](https://github.com/B-UMMI/chewBBACA)
- [mlst GitHub repository](https://github.com/tseemann/mlst)
- [GrapeTree GitHub repository](https://github.com/achtman-lab/GrapeTree)

Detailed software citations, database information and workflow notes can be maintained in the repository Wiki.