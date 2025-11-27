#!/bin/bash
#SBATCH --job-name=mlcmm
#SBATCH --output=mlcmm_%A_%a.out
#SBATCH --error=mlcmm_%A_%a.err
#SBATCH --time=72:00:00
#SBATCH --cpus-per-task=50
#SBATCH --mem=128G
#SBATCH --mail-type=ALL
#SBATCH --mail-user=anthony.gagnon7@usherbrooke.ca
#SBATCH --account=def-larissa1

# Use an array job to run multiple instances with different parameters
#SBATCH --array=2-15

module load r/4.5.0

Rscript mlcmm.R \
    -i BAG_ILR_data.csv \
    -o latentModels/ \
    -c ${SLURM_ARRAY_TASK_ID} \
    -n 50 \
    -r 50 \
    -x 250 \
    -s sid \
    -a age