FROM --platform=linux/amd64 python:3.10-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# ---- Install core dependencies ----
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        python3-dev \
        libssl-dev \
        curl && \
    rm -rf /var/lib/apt/lists/*

# ---- Security and group setup ----
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# ---- Install Python dependencies ----
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip "setuptools>=70.0.0" wheel && \
    pip install --no-cache-dir -r requirements.txt

# ---- Copy application files ----
COPY . .
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8000

# ---- Healthcheck for container ----
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# ---- Run FastAPI app ----
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]