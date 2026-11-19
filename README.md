# SALMONA

### Salmonella Omics and Genomic Analysis

A modular bioinformatics pipeline for *Salmonella* genome quality control, assembly, annotation, serotyping, antimicrobial resistance profiling, mobile genetic element detection, prophage characterisation and genomic typing.

**Authors:**

- [Arezoo Pedramfar](https://github.com/apedramfar) | [Quadram Profile](https://quadram.ac.uk/people/arezoo-pedramfar/)
- [Alise Ponsero](https://github.com/aponsero) | [Quadram Profile](https://quadram.ac.uk/people/alise-ponsero/)

**Supervision:**

- [Prof. Evelien Adriaenssens](https://quadram.ac.uk/people/evelien-adriaenssens/) | [QIB Research Group](https://quadram.ac.uk/evelien-adriaenssens/)

**Developed at:** [Quadram Institute](https://quadram.ac.uk/), Norwich, United Kingdom.

**Status:** Research workflows under development.

## Overview

SALMONA provides modular workflows for analysing short-read whole-genome sequencing data to investigate genomic diversity, antimicrobial resistance and evolutionary relationships among animal-derived *Salmonella* isolates.

The workflows were developed for a Linux HPC environment using SLURM and can be adapted to other bacterial datasets with appropriate reference databases and analysis parameters.

## Pipeline Modules

| Module | Analysis | Main tools |
|---|---|---|
| [00 — Setup](Genome_pipeline/Module00_Setup/) | Sample preparation and configuration | Bash |
| [01 — Quality Control](Genome_pipeline/Module01_QC/) | Read QC, host removal and contamination screening | Hostile, Trim Galore, FastQC, MultiQC, MetaPhlAn |
| [02 — Genome Assembly](Genome_pipeline/Module02_Assembly/) | Assembly, coverage and quality assessment | SPAdes, SeqKit, CoverM, CheckM2 |
| [03 — Annotation](Genome_pipeline/Module03_Annotation/) | Genome dereplication and annotation | dRep, Bakta |
| [04 — Serotyping](Genome_pipeline/Module04_Serotyping/) | *Salmonella* serovar prediction | SeqSero2, SISTR |
| [05 — AMR & Mobile Elements](Genome_pipeline/Module05_AMR_Mobile/) | AMR determinants and plasmid prediction | AMRFinderPlus, geNomad, ResFinder |
| [06 — Prophages](Genome_pipeline/Module06_Prophages/) | Prophage detection and classification | PHORAGER, vConTACT3 |
| [07 — Genomic Typing](Genome_pipeline/Module07_Typing/) | MLST, wgMLST and cgMLST | mlst, chewBBACA |

Modules can be configured and executed according to their input requirements. Detailed instructions are provided in each module's README.

## Quick Start

**1. Clone the repository**

```bash
git clone https://github.com/apedramfar/Salmonella-Genomics-and-Evolution.git
cd SALMONA
```

**2. Configure a module**

```bash
cd Genome_pipeline/Module01_QC
cp config.example.sh config.sh
nano config.sh
```

Configure the input/output paths, software packages, reference databases and SLURM resources.

**3. Run the module**

```bash
bash 01.run_qc.sh
```

Other modules have their own execution commands, described in their README files.

The workflows use HPC-specific software-loading commands and may require adaptation on other systems.

## Documentation and Data Availability

Each module provides configuration instructions, expected outputs, software versions and relevant scientific references. Additional information is available in the [GitHub Wiki](https://github.com/apedramfar/Salmonella-Genomics-and-Evolution/wiki).

Raw sequencing data, genome assemblies, reference databases, generated results and local HPC configurations are not distributed with this repository.

The custom 320-reference cgMLST schema used in Module07 is also excluded. Information on its construction and availability will be updated following publication of the complete pipeline.

## Future Pipeline Release

This repository contains the current modular research workflows. A more fully integrated and standardised implementation is planned for release through the **Quadram Institute**, with development and release coordinated by [Alise Ponsero](https://github.com/aponsero).

Details of the complete pipeline and associated publications will be added when available.

### For Quadram Institute Users

SALMONA is currently configured for the Quadram Institute's HPC environment. Quadram users interested in running the workflows are welcome to contact us for the required software packages, environment settings and relevant paths. More detailed installation and configuration instructions will be added as the pipeline develops.

## Feedback and Contributions

Feedback, suggestions and constructive comments are very welcome and greatly appreciated.

Please use [GitHub Issues](https://github.com/apedramfar/Salmonella-Genomics-and-Evolution/issues) to report problems or suggest improvements.

## Funding

SALMONA was developed at the Quadram Institute as part of the Medical Research Council (MRC)-funded project *“Mechanism of multiple drug resistance and genetic evolution of prevalent Salmonella serotypes derived from animals”* (Grant MR/Y0152311).

## Citation

A dedicated citation for SALMONA is not yet available. If you use or adapt these workflows, please cite the relevant original software publications provided in the module documentation. Citation information will be updated when available.
