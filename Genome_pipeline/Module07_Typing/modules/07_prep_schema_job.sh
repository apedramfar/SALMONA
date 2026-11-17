#!/bin/bash -l
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

source config.sh

set +eu
source package $PKG_CHEWBBACA
set -eu

echo "Job started"; hostname; date

echo "chewBBACA version : $(chewBBACA.py --version)"
echo "Input schema      : $CHEW_EXISTING_SCHEMA"
echo "Input loci        : $(find "$CHEW_EXISTING_SCHEMA" -maxdepth 1 -type f -name "*.fasta" | wc -l)"
echo "Output schema     : $CHEW_PREPARED_SCHEMA"
echo ""

chewBBACA.py PrepExternalSchema \
    -g "$CHEW_EXISTING_SCHEMA" \
    -o "$CHEW_PREPARED_SCHEMA" \
    --cpu "$SLURM_CPUS_PER_TASK"

if [[ ! -d "$CHEW_PREPARED_SCHEMA" ]]; then
    echo "ERROR: PrepExternalSchema did not produce output"
    exit 1
fi

echo ""
echo "PrepExternalSchema complete"
echo "  Prepared schema : $CHEW_PREPARED_SCHEMA"
echo "  Prepared loci   : $(find "$CHEW_PREPARED_SCHEMA" -maxdepth 1 -type f -name "*.fasta" | wc -l)"
echo "Job done"; date
