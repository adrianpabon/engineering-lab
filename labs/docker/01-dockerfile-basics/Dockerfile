# Single-stage image on purpose: multi-stage + non-root come in lab 02.
FROM python:3.12-slim

# Don't write .pyc files and flush logs immediately (useful in containers).
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /srv

# Copy requirements first so the dependency layer is cached between code changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

EXPOSE 8000

# Exec form: uvicorn runs as PID 1 and receives SIGTERM from `docker stop`.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
