# Public website image: the self-contained BioAI Research Lab (SQLite, local file storage, background worker,
# prebuilt frontend). The Docker Compose / PostgreSQL stack uses backend/Dockerfile and frontend/Dockerfile instead.
FROM python:3.12-slim
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 MPLBACKEND=Agg MPLCONFIGDIR=/tmp/mpl \
    HOST=0.0.0.0 PORT=8765 BIOAI_DATA_DIR=/data \
    ENVIRONMENT=production TRUST_PROXY=true MAX_UPLOAD_MB=25 LOAD_DEMO=true SHOW_VERIFICATION_LINKS=true
WORKDIR /app
COPY requirements-local.txt ./
RUN pip install --no-cache-dir -r requirements-local.txt
COPY run_local.py ./
COPY backend ./backend
COPY frontend/dist-local ./frontend/dist-local
RUN useradd -m app && mkdir -p /data && chown -R app /data /app
USER app
EXPOSE 8765
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s CMD python -c "import os,urllib.request; urllib.request.urlopen(f'http://127.0.0.1:{os.environ[\"PORT\"]}/api/v1/health')"
CMD ["python", "run_local.py", "--no-browser"]
