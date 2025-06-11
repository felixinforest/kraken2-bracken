#!/bin/bash
set -euo pipefail

# Load conda
eval "$(conda shell.bash hook)"

# Check input
if [ $# -lt 1 ]; then
    echo "Usage: $0 <input.fastq.gz>"
    exit 1
fi

# Input and environment
inf="$1"
fname=$(basename "$inf" | sed -E 's/\.fastq\.gz$//')
kraken_db="/media/felicia/SiLoL_drive/database/Kraken_db"
kraken_sif="/home/felicia/my_sif/nf-sif/kraken2.img"
logfile="${fname}_kraken_bracken_run.log"

# Start logging
{
    echo "==== KRAKEN2 + BRACKEN RUN ===="
    echo "Start time: $(date)"
    echo "Input file: $inf"
    echo "Sample prefix: $fname"
    echo "Kraken DB: $kraken_db"
    echo "Singularity image: $kraken_sif"
    echo

    # Get Kraken2 version
    echo "Checking Kraken2 version..."
    version=$(singularity exec -B $PWD "$kraken_sif" kraken2 --version | grep -v "version")
    echo "Kraken2 Version: $version"
    echo

    # Run Kraken2
    echo "Running Kraken2..."
    singularity exec -B $PWD -B "$kraken_db" "$kraken_sif" kraken2 \
        -db "$kraken_db" \
        --threads 10 \
        --unclassified-out "${fname}.unclassified.fastq" \
        --classified-out "${fname}.classified.fastq" \
        --report "${fname}.kraken2.report.txt" \
        --gzip-compressed "$inf"
    echo "Kraken2 completed."
    echo

    # Run Bracken
    echo "Activating Bracken environment..."
    conda activate bracken

    echo "Checking Bracken version..."
    bracken_version=$(bracken -v)
    echo "Bracken Version: $bracken_version"
    echo

    echo "Running Bracken..."
    bracken -d "$kraken_db" \
        -i "${fname}.kraken2.report.txt" \
        -o "${fname}.bracken_output.txt" \
        -r 100 -l S
    echo "Bracken completed."
    echo

    echo "Finished successfully at: $(date)"
    echo "==============================="
} 2>&1 | tee "$logfile"
