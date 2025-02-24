FROM continuumio/miniconda3:latest

WORKDIR /app

# Create logs directory
RUN mkdir -p /app/logs

# Install Python dependencies
COPY environment.yml .
RUN conda env create -f environment.yml

# Copy source files
COPY src/ ./src/

# Run both services
ENTRYPOINT ["conda", "run", "-n", "aws-trading", "--no-capture-output"]
CMD ["sh", "-c", "python src/strategy.py & python src/cost_checker.py"]