# Docker cheatsheet

Condensed commands and gotchas collected from the [Docker labs](../labs/docker/). Each entry: command → what it does → when to use it.

## Images

| Command | What it does |
|---|---|
| `docker build -t lab01 .` | Build an image from the `Dockerfile` in the current dir (`.` = build context) and tag it `lab01` (`-t` = name[:tag], default tag `latest`). |
| `docker build -t lab01:v2 .` | Same, with an explicit tag. |
| `docker images` | List local images. |
| `docker images lab01` | List only images named `lab01`. |
| `docker history lab01` | Show every layer of the image, the instruction that created it, and its size. Best tool to find *what* makes an image big. |
| `docker history --no-trunc lab01` | Same, without cutting long instructions. |
| `docker rmi lab01` | Remove an image (`-f` to force). |

**Reading `docker images` sizes** (Docker Desktop, containerd store):
- `CONTENT SIZE` → compressed size, what you download/push.
- `DISK USAGE` → unpacked layers **+** compressed blobs (both are kept on disk).

> Gotcha: a base image (e.g. `python:3.12-slim`) pulled during a build may not appear in `docker images` — its layers live inside your image. Use `docker history`.

## Containers

| Command | What it does |
|---|---|
| `docker run lab01` | Create and start a container; terminal stays attached to its logs (Ctrl+C stops it). |
| `docker run -d lab01` | `-d` = **detached**: run in the background and return the terminal. |
| `docker run -d --name hola-lab lab01` | `--name` = stable name to reference it later (min. **2 characters**, `[a-zA-Z0-9][a-zA-Z0-9_.-]+`). |
| `docker run -d -p 8000:8000 lab01` | `-p host:container` = publish a port. `curl localhost:8000` reaches the container. |
| `docker run -d -p 127.0.0.1:0:8000 lab01` | Bind only to localhost, and `0` = let Docker pick a free host port. |
| `docker run --rm lab01` | Remove the container automatically when it exits. |
| `docker run -d lab01 sh -c "cmd"` | Override the image's `CMD` with another command. |
| `docker ps` | List **running** containers. |
| `docker ps -a` | List **all** containers, including stopped ones. |
| `docker port hola-lab 8000/tcp` | Show which host port maps to container port 8000. |
| `docker logs hola-lab` | Print the container's stdout/stderr (`-f` to follow). |
| `docker exec -it hola-lab sh` | Open a shell inside a running container. |
| `docker stop hola-lab` | Send `SIGTERM` to PID 1, wait the grace period (10 s), then `SIGKILL`. |
| `docker rm hola-lab` | Remove a stopped container (frees its name). `-f` stops + removes. |

Shell helper: `time <command>` measures how long a command takes (e.g. `time docker stop hola-lab`).

## Dockerfile essentials

```dockerfile
FROM python:3.12-slim           # base image
WORKDIR /srv                    # working dir for next instructions
COPY requirements.txt .         # dependencies first → cached layer
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/                # code last → only this layer rebuilds on code changes
EXPOSE 8000                     # documentation only; -p actually publishes
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]   # exec form
```

- **Layer cache:** each instruction is a layer; changing one invalidates all layers after it. Put rarely-changing steps first.
- **Exec vs shell form:**
  - `CMD ["uvicorn", ...]` (exec) → your app is **PID 1**, receives `SIGTERM`, stops gracefully (**0.46 s** in lab 01).
  - `CMD uvicorn ...` (shell) → `sh` is PID 1 and doesn't forward `SIGTERM`; Docker waits 10 s and `SIGKILL`s (**10.16 s** in lab 01).

## Multi-stage builds

Several `FROM`s in one Dockerfile; copy only the result into the final image.

```dockerfile
FROM python:3.12 AS builder                  # "builder" = stage alias, not a tag
COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt

FROM python:3.12-slim                        # clean final stage
COPY --from=builder /install /usr/local      # copy from the builder stage, not from the host
COPY app/ ./app/
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Removes build-time tooling from the final image. It does **not** shrink the runtime base — for that, change the base image.

## Cleanup

| Command | What it does |
|---|---|
| `docker container prune` | Remove all stopped containers. |
| `docker image prune` | Remove dangling (untagged) images. |
| `docker system df` | Show disk used by images, containers, volumes, build cache. |
