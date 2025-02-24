#!/bin/bash

# Activate Conda environment
source /opt/conda/etc/profile.d/conda.sh
conda activate aws-trading

# Start services with logging
python src/strategy.py > /proc/1/fd/1 2>&1 &
python src/cost_checker.py > /proc/1/fd/1 2>&1 &

# Keep container alive
tail -f /dev/null