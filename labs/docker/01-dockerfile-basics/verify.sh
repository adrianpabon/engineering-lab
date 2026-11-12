#!/usr/bin/env bash
# Verifies lab docker/01-dockerfile-basics:
#   build image -> run container -> GET /health returns {"status":"ok"} -> clean up.
# Idempotent: unique names per run, and everything is removed on exit (success or failure).
set -euo pipefail

cd "$(dirname "$0")"

RUN_ID="$$-$(date +%s)"
IMAGE="lab-dockerfile-basics:verify-${RUN_ID}"
CONTAINER="lab-dockerfile-basics-${RUN_ID}"

cleanup() {
  docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
  docker rmi -f "$IMAGE" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "==> Building $IMAGE"
docker build --quiet -t "$IMAGE" . >/dev/null

echo "==> Starting $CONTAINER"
# Port 0 lets Docker pick a free host port, so parallel runs never collide.
docker run -d --name "$CONTAINER" -p 127.0.0.1:0:8000 "$IMAGE" >/dev/null
PORT="$(docker port "$CONTAINER" 8000/tcp | head -n1 | awk -F: '{print $NF}')"
URL="http://127.0.0.1:${PORT}/health"

echo "==> Waiting for $URL"
for _ in $(seq 1 30); do
  if BODY="$(curl -fsS "$URL" 2>/dev/null)"; then
    break
  fi
  sleep 1
done

if [[ "${BODY:-}" != '{"status":"ok"}' ]]; then
  echo "FAIL: unexpected response: '${BODY:-<none>}'" >&2
  docker logs "$CONTAINER" >&2 || true
  exit 1
fi

echo "OK: /health -> $BODY"
