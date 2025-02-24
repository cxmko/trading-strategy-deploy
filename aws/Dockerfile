FROM continuumio/miniconda3:latest

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Create Conda environment
COPY environment.yml .
RUN conda env create -f environment.yml

# Copy application code
COPY src/ ./src/

# Configure logging
RUN mkdir -p /var/log/trading
ENV PYTHONUNBUFFERED=1

# Entrypoint script
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]