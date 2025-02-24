FROM continuumio/miniconda3:latest

WORKDIR /app

# Create Conda env
COPY environment.yml .
RUN conda env create -f environment.yml

# Copy code
COPY src/ ./src/
COPY infra/ ./infra/

# Run AWS services
ENTRYPOINT ["conda", "run", "-n", "aws-trading"]
CMD ["sh", "-c", "python src/strategy.py & python src/cost_checker.py"]