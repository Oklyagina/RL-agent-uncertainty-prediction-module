FROM python:3.11.13-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    OMP_NUM_THREADS=1 \
    CUDA_VISIBLE_DEVICES=-1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        g++ \
        gcc \
        gfortran \
        git \
        git-lfs \
        libgomp1 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt ./
RUN python -m pip install --upgrade pip setuptools wheel \
    && python -m pip install -r requirements.txt

RUN useradd --create-home --shell /bin/bash appuser \
    && mkdir -p /app/src/RESULTS /app/src/CACHE /home/appuser/data_grid2op \
    && chown -R appuser:appuser /home/appuser/data_grid2op

COPY --chown=appuser:appuser . .
COPY docker/entrypoint.sh /usr/local/bin/project-entrypoint

RUN chown -R appuser:appuser /app/src/RESULTS /app/src/CACHE \
    && chmod +x /usr/local/bin/project-entrypoint

USER appuser
WORKDIR /app/src

ENTRYPOINT ["project-entrypoint"]
CMD ["python", "main.py", "--config", "smoke"]
