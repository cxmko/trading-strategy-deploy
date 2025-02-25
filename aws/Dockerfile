FROM continuumio/miniconda3:latest

WORKDIR /app

# Create Conda environment
COPY environment.yml .
RUN conda env create -f environment.yml

# Copy source files
COPY src/ ./src/
COPY entrypoint.sh .

# Make entrypoint.sh executable
RUN chmod +x entrypoint.sh

# Ensure output isn't buffered
ENV PYTHONUNBUFFERED=1

ENTRYPOINT ["/app/entrypoint.sh"]