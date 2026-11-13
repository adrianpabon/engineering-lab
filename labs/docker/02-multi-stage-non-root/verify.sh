#!/usr/bin/env bash
# Verifies lab docker/02-multi-stage-non-root. For each Dockerfile variant (slim, alpine, distroless):
#   build -> run -> GET /health == {"status":"ok"} -> process is NOT root -> print size -> clean up.
# Idempotent: unique names per run, everything removed on exit (success or failure).
set -euo pipefail

cd "$(dirname "$0")"

VARIANTS=(slim alpine distroless)
RUN_ID="$$-$(date +%s)"
CREATED=()

cleanup() {
  for name in "${CREATED[@]:-}"; do
    [[ -n "$name" ]] || continue
    docker rm -f "$name" >/dev/null 2>&1 || true
    docker rmi -f "$name:verify" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

printf '%-11s %-9s %-10s %s\n' VARIANT UID CONTENT RESULT
for v in "${VARIANTS[@]}"; do
  name="lab02-${v}-${RUN_ID}"
  CREATED+=("$name")

  docker build --quiet -f "Dockerfile.${v}" -t "${name}:verify" . >/dev/null
  docker run -d --name "$name" -p 127.0.0.1:0:8000 "${name}:verify" >/dev/null
  port="$(docker port "$name" 8000/tcp | head -n1 | awk -F: '{print $NF}')"

  body=""
  for _ in $(seq 1 30); do
    body="$(curl -fsS "http://127.0.0.1:${port}/health" 2>/dev/null)" && break
    sleep 1
  done
  if [[ "$body" != '{"status":"ok"}' ]]; then
    echo "FAIL [$v]: unexpected /health response: '${body:-<none>}'" >&2
    docker logs "$name" >&2 || true
    exit 1
  fi

  # The host sees the container's PID 1 with its real UID; 0 means root. (`docker top` requires the pid column.)
  uid="$(docker top "$name" -o pid,uid | awk 'NR==2 {print $2}')"
  if [[ -z "$uid" || "$uid" == "0" || "$uid" == "root" ]]; then
    echo "FAIL [$v]: container process runs as root (uid='${uid}')" >&2
    exit 1
  fi

  content="$(docker image inspect "${name}:verify" --format '{{.Size}}' | awk '{printf "%.1fMB", $1/1e6}')"
  printf '%-11s %-9s %-10s %s\n' "$v" "$uid" "$content" "OK"
done

echo "OK: all variants healthy and non-root"
