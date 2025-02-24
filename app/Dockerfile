FROM continuumio/miniconda3:latest

WORKDIR /app

COPY environment.yml .
RUN conda env create -f environment.yml

COPY src/ ./src/

VOLUME /app/db

ENTRYPOINT ["conda", "run", "-n", "local-dash"]
CMD ["python ./src/data_gen.py & streamlit run ./src/dashboard.py --server.port=8501 --server.address=0.0.0.0"]