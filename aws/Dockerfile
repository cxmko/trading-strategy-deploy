FROM continuumio/miniconda3:latest

WORKDIR /app

# Create Conda environment
COPY environment.yml .
RUN conda env create -f environment.yml

# Copy source files
COPY src/ ./src/

# No need to modify print statements - just ensure output isn't buffered
ENV PYTHONUNBUFFERED=1

ENTRYPOINT ["conda", "run", "-n", "aws-trading", "--no-capture-output"]
CMD ["sh", "-c", "python src/strategy.py && python src/cost_checker.py"]