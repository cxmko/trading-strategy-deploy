FROM continuumio/miniconda3:latest

WORKDIR /app

# Install AWS CLI and required tools
RUN apt-get update && apt-get install -y curl unzip
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install

# Create Conda environment
COPY environment.yml .
RUN conda env create -f environment.yml

# Copy source files
COPY src/ ./src/

# Run services with proper logging
CMD ["sh", "-c", \
    "conda run -n aws-trading python src/strategy.py >> /proc/1/fd/1 2>>/proc/1/fd/2 & \
     conda run -n aws-trading python src/cost_checker.py >> /proc/1/fd/1 2>>/proc/1/fd/2 & \
     tail -f /dev/null"]