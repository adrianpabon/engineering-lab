---
title: Dockerfile basics with a FastAPI health endpoint
tech: docker
tags: [dockerfile, fastapi, python, layers, healthcheck]
level: beginner
status: in-progress
date: 2026-11-11
last_reviewed: 2026-11-11
time_spent_h: 0
---

# Dockerfile basics

## Goal

Package a minimal FastAPI service into a container image and prove it serves `GET /health` correctly.

## Architecture

```mermaid
flowchart LR
    subgraph Build["docker build"]
        DF[Dockerfile] --> L1[python:3.12-slim]
        L1 --> L2[pip install requirements.txt<br/>cached layer]
        L2 --> L3[COPY app/]
    end
    L3 --> IMG[(Image)]
    IMG -->|docker run -p 127.0.0.1:0:8000| C[Container<br/>uvicorn :8000]
    V[verify.sh] -->|curl /health| C
    C -->|"{status: ok}"| V
```

## What I built

- `app/main.py` — FastAPI app with a single `GET /health` endpoint.
- `Dockerfile` — single-stage image on `python:3.12-slim`; dependencies copied before code to reuse the layer cache; exec-form `CMD` so uvicorn is PID 1 and handles `SIGTERM`.
- `verify.sh` — builds the image, runs it on a random free port, polls `/health`, and removes container + image on exit.

## How to verify

```bash
./verify.sh   # exit 0 = OK; cleans up everything it creates
```

## What broke and how I fixed it

- TODO

## What I learned

- TODO

## Interview questions this answers

- TODO
