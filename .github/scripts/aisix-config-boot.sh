#!/usr/bin/env bash
# Boot the gateway image the chart deploys (its appVersion) on the config file
# the chart renders, in both modes, with charts/aisix/ci/config-values.yaml
# setting list-typed keys through `config`.
#
# Standalone must come up and answer /livez. Control-plane mode has no control
# plane to reach here, so it must get past loading the config file and fail
# only once it acts on the connection. Override the image with AISIX_IMAGE.
set -euo pipefail

chart=charts/aisix
app=$(awk '/^appVersion:/ {gsub(/"/, "", $2); print $2}' "$chart/Chart.yaml")
image=${AISIX_IMAGE:-docker.io/api7/aisix:$app}
work=$(mktemp -d)
chmod 755 "$work"
run_id=$$
trap 'docker rm -f "aisix-cfgboot-standalone-$run_id" "aisix-cfgboot-managed-$run_id" >/dev/null 2>&1 || true; rm -rf "$work"' EXIT

# extract <template> <data key> <out file> [helm args...]
extract() {
  local template=$1 key=$2 out=$3
  shift 3
  helm template ci "$chart" "$@" --show-only "templates/$template" \
    | python3 -c '
import sys, yaml
key = sys.argv[1]
for doc in yaml.safe_load_all(sys.stdin):
    if doc:
        data = doc.get("data") or doc.get("stringData") or {}
        if key in data:
            sys.stdout.write(data[key])
' "$key" >"$out"
  test -s "$out"
  chmod 644 "$out"
}

echo "== image $image"
docker pull -q "$image" >/dev/null

echo "== standalone"
mkdir -p "$work/standalone"
set_standalone=(-f "$chart/ci/standalone-values.yaml" -f "$chart/ci/config-values.yaml")
extract configmap.yaml config.yaml "$work/standalone/config.yaml" "${set_standalone[@]}"
extract secret.yaml resources.yaml "$work/standalone/resources.yaml" "${set_standalone[@]}"
cat "$work/standalone/config.yaml"
name=aisix-cfgboot-standalone-$run_id
docker run -d --name "$name" -p 127.0.0.1::3000 \
  -e AISIX_CONFIG_PATH=/etc/aisix/chart/config.yaml \
  -e OPENAI_API_KEY=sk-ci-placeholder -e CALLER_API_KEY=ci-caller-placeholder \
  -v "$work/standalone/config.yaml:/etc/aisix/chart/config.yaml:ro" \
  -v "$work/standalone/resources.yaml:/etc/aisix/resources/resources.yaml:ro" \
  "$image" >/dev/null
port=$(docker port "$name" 3000/tcp | head -n1 | sed 's/.*://')
ok=
for _ in $(seq 1 60); do
  if curl -fsS "http://127.0.0.1:$port/livez" >/dev/null 2>&1; then ok=1; break; fi
  if [ "$(docker inspect -f '{{.State.Running}}' "$name")" != true ]; then break; fi
  sleep 1
done
if [ -z "$ok" ]; then
  echo "standalone gateway did not come up on the rendered config:"
  docker logs "$name" 2>&1 | tail -n 50
  exit 1
fi
echo "standalone: /livez answered"

echo "== control-plane mode"
mkdir -p "$work/managed/cp-mtls"
extract configmap.yaml config.yaml "$work/managed/config.yaml" -f "$chart/ci/config-values.yaml"
cat "$work/managed/config.yaml"
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj "/CN=aisix-ci" \
  -keyout "$work/managed/cp-mtls/key.pem" -out "$work/managed/cp-mtls/cert.pem" 2>/dev/null
cp "$work/managed/cp-mtls/cert.pem" "$work/managed/cp-mtls/ca.pem"
chmod 755 "$work/managed/cp-mtls"
chmod 644 "$work/managed/cp-mtls/"*.pem
name=aisix-cfgboot-managed-$run_id
docker run -d --name "$name" \
  -e AISIX_CONFIG_PATH=/etc/aisix/chart/config.yaml \
  -v "$work/managed/config.yaml:/etc/aisix/chart/config.yaml:ro" \
  -v "$work/managed/cp-mtls:/etc/aisix/cp-mtls:ro" \
  "$image" >/dev/null
for _ in $(seq 1 30); do
  [ "$(docker inspect -f '{{.State.Running}}' "$name")" = true ] || break
  sleep 1
done
logs=$(docker logs "$name" 2>&1)
echo "$logs" | tail -n 20
# `level=debug` is config-values.yaml's log_level: the file was read and applied.
if echo "$logs" | grep -q "config load failed"; then
  echo "control-plane mode: the rendered config file did not load"
  exit 1
fi
if ! echo "$logs" | grep -q "tracing initialised service=aisix level=debug"; then
  echo "control-plane mode: the gateway never got past loading its config file"
  exit 1
fi
echo "control-plane mode: config file loaded; the gateway stopped at the control-plane connection"
