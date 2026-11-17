# SALMONA

### Salmonella Omics and Genomic Analysis

A modular bioinformatics pipeline for bacterial genome quality control, assembly, annotation, serotyping, antimicrobial resistance detection, mobile genetic element analysis, prophage characterisation and genomic typing.

**Developed at the [Quadram Institute](https://quadram.ac.uk/), Norwich, United Kingdom.**

**Contributors**
- [Arezoo Pedramfar](https://github.com/apedramfar)
- [Alise Ponsero](https://github.com/aponsero)

**Status:** Research workflows under development. A fully integrated implementation is planned for future release through the Quadram Institute.

---

## Overview

This repository provides modular bioinformatics workflows developed to investigate the genomic diversity, antimicrobial resistance (AMR), mobile genetic elements and evolutionary relationships of animal-derived *Salmonella* isolates.

The workflows support bacterial whole-genome sequencing analysis, integrating experimental isolate sequencing data with computational approaches for genome reconstruction, quality assessment, functional characterisation and comparative genomics.

The pipeline includes:

- **Read quality control and contamination screening** — Host-read removal, adapter trimming, sequencing quality assessment and taxonomic profiling.
- **Genome assembly and quality assessment** — *De novo* assembly, contig filtering, sequencing coverage estimation and genome completeness/contamination assessment.
- **Genome dereplication and annotation** — Genomic similarity-based clustering and functional annotation.
- **Salmonella serotyping** — Independent serovar predictions from assembled genomes.
- **Antimicrobial resistance and mobile genetic elements** — Detection of AMR-associated, virulence-associated and stress-response genes, alongside predicted plasmid sequences.
- **Prophage analysis** — Identification, annotation and classification of prophage sequences.
- **Genomic typing** — Classical MLST, whole-genome MLST (wgMLST) and core-genome MLST (cgMLST).

The workflows were developed for a Linux high-performance computing (HPC) environment using SLURM. Individual modules can be configured and executed according to study requirements.

Although the workflow was designed primarily for *Salmonella*, selected modules may be adapted to other bacterial species using appropriate databases and analysis parameters.

## Pipeline Modules

| Module | Analysis | Main software |
|---|---|---|
| [00 — Setup](Genome_pipeline/Module00_Setup/) | Sample sheet preparation and configuration | Bash |
| [01 — Quality Control](Genome_pipeline/Module01_QC/) | Read QC, host-read removal and contamination screening | Hostile, Trim Galore, FastQC, MultiQC, MetaPhlAn |
| [02 — Genome Assembly](Genome_pipeline/Module02_Assembly/) | *De novo* assembly, coverage estimation and genome quality assessment | SPAdes, SeqKit, CoverM, CheckM2 |
| [03 — Genome Annotation](Genome_pipeline/Module03_Annotation/) | Genome dereplication and functional annotation | dRep, Bakta |
| [04 — Serotyping](Genome_pipeline/Module04_Serotyping/) | In silico *Salmonella* serovar prediction | SeqSero2, SISTR |
| [05 — AMR & Mobile Elements](Genome_pipeline/Module05_AMR_Mobile/) | AMR, virulence-associated determinants and plasmid prediction | AMRFinderPlus, geNomad, ResFinder |
| [06 — Prophages](Genome_pipeline/Module06_Prophages/) | Prophage detection, annotation and classification | PHORAGER, vConTACT3 |
| [07 — Genomic Typing](Genome_pipeline/Module07_Typing/) | Classical MLST, wgMLST and cgMLST | mlst, chewBBACA |

Each module contains workflow scripts, an example configuration file and a dedicated README describing its requirements, execution, outputs and relevant software references.

## Workflow

```text
                    Paired-end sequencing reads
                               |
                               v
                       Module 00 — Setup
                               |
                               v
                  Module 01 — Quality Control
                 Host removal | Trimming | QC
                               |
                               v
                  Module 02 — Genome Assembly
                 Assembly | Coverage | CheckM2
                               |
                               v
                       Genome assemblies
                               |
          +--------------------+--------------------+
          |                    |                    |
          v                    v                    v
      Module 03            Module 04            Module 05
    Dereplication         Serotyping          AMR & Mobile
    & Annotation                                Elements
          |                    |                    |
          +--------------------+--------------------+
                               |
                   +-----------+-----------+
                   |                       |
                   v                       v
               Module 06               Module 07
               Prophages             Genomic Typing
           PHORAGER/vConTACT3        MLST/wgMLST/cgMLST
                   |                       |
                   +-----------+-----------+
                               |
                               v
                     Comparative Genomics
                 Genomic diversity | AMR profiles
                  Prophage content | Relatedness
```

Modules 03–07 are not necessarily executed sequentially. Most use the genome assemblies generated by Module02, and their results can be integrated for downstream comparative analyses.

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/apedramfar/Salmonella-Genomics-and-Evolution.git
cd Salmonella-Genomics-and-Evolution
```

### 2. Configure a module

Each module contains a `config.example.sh` file that should be copied and adapted to the local computing environment.

For example:

```bash
cd Genome_pipeline/Module01_QC

cp config.example.sh config.sh
nano config.sh
```

Update the relevant input/output directories, reference database paths, software packages and SLURM resources.

The local `config.sh` files are excluded from Git version control.

### 3. Run the workflow

For Module01:

```bash
bash 01.run_qc.sh
```

Subsequent modules can be run independently when their required input data are available.

Consult each module's README for the corresponding commands, required databases, parameters and output checks.

### 4. Review the results

Each module provides an output-checking script that reports expected files, missing results or relevant quality metrics. Review the SLURM logs and generated reports before using results in downstream analyses.

## Requirements

The workflows were developed for Linux HPC environments and generally require:

- Bash and SLURM for workflow execution and job scheduling.
- Access to the required bioinformatics software and compatible versions.
- External reference databases and genomic typing schemas.
- Paired-end sequencing reads or assembled bacterial genomes.
- Sufficient computational resources and storage for the selected analyses.

The scripts use software-loading commands specific to the original HPC environment, including `source package`. These commands may require adaptation for other computing systems.

Software versions and resource requirements are documented in the individual modules.

## Outputs and Applications

The pipeline generates complementary genomic information, including:

- Quality-controlled sequencing reads and bacterial genome assemblies.
- Genome completeness, contamination and sequencing coverage estimates.
- Functional genome annotations and dereplication clusters.
- Predicted *Salmonella* serovars.
- AMR-associated, virulence-associated and stress-response gene profiles.
- Predicted plasmid and prophage sequences.
- Classical MLST sequence types and allele-based genomic profiles.

These outputs support investigations of bacterial genomic diversity, population structure, antimicrobial resistance, mobile genetic elements and genomic relationships.

Additional phylogenetic reconstruction, visualisation and statistical analyses can be performed using downstream tools.

### Future Pipeline Release

The current repository contains research-specific modular workflows and supporting documentation. A more fully integrated and standardised implementation is planned for release through the **Quadram Institute**, with development and release coordinated by **Alise Ponsero**.

The workflows in this repository represent the current research implementations and should not be considered the final institutional pipeline.
Information about the complete pipeline, its availability, installation procedures and associated publications will be updated following the official release.
## Data and Reference Availability

This repository contains workflow scripts, example configurations and documentation.

The following resources are not currently distributed:

- Raw sequencing datasets and original research data.
- Genome assemblies and generated analysis results.
- External software reference databases.
- Large genomic typing schemas and reference collections.
- Local HPC configuration files and computational environments.

### Custom cgMLST Schema

Module07 includes a custom cgMLST analysis using a schema developed from 320 reference genomes and a predefined set of 3,153 core loci. The custom schema and associated reference files are not included in this repository. Researchers can use their own compatible schemas with the provided chewBBACA workflow.

Details regarding schema construction, availability and use will be updated following publication of the complete pipeline.

## Documentation

Detailed documentation is available in the individual module README files, covering input requirements, configuration, execution, software versions, expected outputs and relevant scientific references.

## Note

These workflows were developed for a specific research environment and may require adaptation before being used on other computing systems or datasets.

## Feedback and Contributions

Feedback, suggestions and constructive comments on the workflows, documentation and potential improvements are very welcome and greatly appreciated.
Researchers and developers are encouraged to report issues, share ideas or suggest improvements using [GitHub Issues](https://github.com/apedramfar/Salmonella-Genomics-and-Evolution/issues).
Contributions that improve scientific accuracy, usability, reproducibility and documentation are particularly welcome.

## Citation

Citation information for the integrated pipeline will be added when its associated publication becomes available. If you use or adapt individual workflow components, please cite the relevant original software publications listed in the module README files and GitHub Wiki.

