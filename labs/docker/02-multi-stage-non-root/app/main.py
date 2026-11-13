"""Minimal FastAPI service used to practice Dockerfile basics."""

from fastapi import FastAPI

app = FastAPI(title="dockerfile-basics", version="0.1.0")


@app.get("/health")
def health() -> dict[str, str]:
    """Liveness probe: returns 200 while the process is up."""
    return {"status": "ok"}
