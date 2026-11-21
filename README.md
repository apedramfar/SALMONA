# SALMONA

### Salmonella Omics and Genomic Analysis

A modular bioinformatics pipeline for *Salmonella* genome quality control, assembly, annotation, serotyping, antimicrobial resistance profiling, mobile genetic element detection, prophage characterisation and genomic typing.

**Authors:**

- [Arezoo Pedramfar](https://github.com/apedramfar) | [Quadram Profile](https://quadram.ac.uk/people/arezoo-pedramfar/)
- [Alise Ponsero](https://github.com/aponsero) | [Quadram Profile](https://quadram.ac.uk/people/alise-ponsero/)

**Supervision:**

- [Prof. Evelien Adriaenssens](https://quadram.ac.uk/people/evelien-adriaenssens/) | [Adriaenssens Lab GitHub](https://github.com/adriaenssens-lab)

**Developed at:** [Quadram Institute](https://quadram.ac.uk/), Norwich, United Kingdom.

💡 **Tip:** Although SALMONA was developed for *Salmonella*, several modules can be adapted for use with other bacterial species by replacing the relevant reference databases, tool settings, and analysis parameters. The serotyping workflow is specific to *Salmonella*, while the typing workflow requires suitable species-specific typing schemes and reference schemas.

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
git clone https://github.com/apedramfar/SALMONA.git
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

## Citation Guidance

Users should cite the original publications for the tools and databases employed in their analyses. Additional software references, version information and module-specific methodological details are provided in the individual module documentation. A dedicated SALMONA citation will be added when available.

## References and Software Citations

SALMONA integrates established bioinformatics tools across multiple stages of bacterial whole-genome analysis. We acknowledge the developers of these tools and encourage users to cite the relevant original publications when using SALMONA workflows.

### Module 00 — Setup
Sample sheet preparation and workflow configuration are implemented using Bash scripts. No module-specific scientific publication is required.

### Module 01 — Quality Control and Contamination Screening

- **Hostile:** Constantinides B, Hunt M, Crook DW (2023). Hostile: accurate decontamination of microbial host sequences. *Bioinformatics*. [DOI](https://doi.org/10.1093/bioinformatics/btad728)
- **Trim Galore:** Krueger F. Trim Galore: a wrapper tool for quality and adapter trimming. [Software documentation](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/)
- **FastQC:** Andrews S. FastQC: a quality control tool for high-throughput sequence data. [Software documentation](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
- **MultiQC:** Ewels P et al. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report. *Bioinformatics*. [DOI](https://doi.org/10.1093/bioinformatics/btw354)
- **MetaPhlAn 4:** Blanco-Míguez A et al. (2023). Extending and improving metagenomic taxonomic profiling with uncharacterized species using MetaPhlAn 4. *Nature Biotechnology*. [DOI](https://doi.org/10.1038/s41587-023-01688-w)

### Module 02 — Genome Assembly and Quality Assessment

- **SPAdes:** Bankevich A et al. (2012). SPAdes: a new genome assembly algorithm and its applications to single-cell sequencing. *Journal of Computational Biology*. [DOI](https://doi.org/10.1089/cmb.2012.0021)
- **SeqKit:** Shen W et al. (2016). SeqKit: a cross-platform and ultrafast toolkit for FASTA/Q file manipulation. *PLOS ONE*. [DOI](https://doi.org/10.1371/journal.pone.0163962)
- **CoverM:** Aroney ST et al. (2025). CoverM: read alignment statistics for metagenomics. *Bioinformatics*. [DOI](https://doi.org/10.1093/bioinformatics/btaf147)
- **CheckM2:** Chklovski A et al. (2023). CheckM2: a rapid, scalable and accurate tool for assessing microbial genome quality using machine learning. *Nature Methods*. [DOI](https://doi.org/10.1038/s41592-023-01941-9)

### Module 03 — Genome Dereplication and Annotation

- **dRep:** Olm MR et al. (2017). dRep: a tool for fast and accurate genomic comparisons that enables improved genome recovery from metagenomes through de-replication. *The ISME Journal*. [DOI](https://doi.org/10.1038/ismej.2017.126)
- **Bakta:** Schwengers O et al. (2021). Bakta: rapid and standardized annotation of bacterial genomes via alignment-free sequence identification. *Microbial Genomics*. [DOI](https://doi.org/10.1099/mgen.0.000685)

### Module 04 — Salmonella Serotyping

- **SeqSero2:** Zhang S et al. (2019). SeqSero2: rapid and improved Salmonella serotype determination using whole-genome sequencing data. *Applied and Environmental Microbiology*. [DOI](https://doi.org/10.1128/AEM.01746-19)
- **SISTR:** Yoshida CE et al. (2016). The Salmonella In Silico Typing Resource (SISTR): an open web-accessible tool for rapidly typing and subtyping draft Salmonella genome assemblies. *PLOS ONE*. [DOI](https://doi.org/10.1371/journal.pone.0147101)

### Module 05 — Antimicrobial Resistance and Mobile Genetic Elements

- **AMRFinderPlus:** Feldgarden M et al. (2021). AMRFinderPlus and the Reference Gene Catalog facilitate examination of the genomic links among antimicrobial resistance, stress response, and virulence. *Scientific Reports*. [DOI](https://doi.org/10.1038/s41598-021-91456-0)
- **geNomad:** Camargo AP et al. (2024). Identification of mobile genetic elements with geNomad. *Nature Biotechnology*. [DOI](https://doi.org/10.1038/s41587-023-01953-y)
- **ResFinder:** Bortolaia V et al. (2020). ResFinder 4.0 for predictions of phenotypes from genotypes. *Journal of Antimicrobial Chemotherapy*. [DOI](https://doi.org/10.1093/jac/dkaa345)

### Module 06 — Prophage Detection and Classification

- **PHORAGER:** Dyball X et al. (2026). Defining the ESKAPE pathogen prophage repertoire with PHORAGER. *bioRxiv preprint*. [DOI](https://doi.org/10.64898/2026.08.05.742953)
- **vConTACT3:** Bolduc B et al. (2025). Machine learning enables scalable and systematic hierarchical virus taxonomy. *Nature Biotechnology*. [DOI](https://doi.org/10.1038/s41587-025-02946-9)

### Module 07 — Genomic Typing (MLST, wgMLST and cgMLST)

- **mlst:** Seemann T. mlst: scan contig files against PubMLST typing schemes. [GitHub repository](https://github.com/tseemann/mlst)
- **chewBBACA:** Silva M et al. (2018). chewBBACA: a complete suite for gene-by-gene schema creation and strain identification. *Microbial Genomics*. [DOI](https://doi.org/10.1099/mgen.0.000166)






