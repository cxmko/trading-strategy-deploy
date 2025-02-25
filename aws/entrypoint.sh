#!/bin/bash

# Activate Conda environment
source /opt/conda/etc/profile.d/conda.sh
conda activate aws-trading

echo "Starting trading strategy at $(date)"
python src/strategy.py

echo "Running cost checker at $(date)"
python src/cost_checker.py

echo "Execution completed at $(date)"