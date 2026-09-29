#!/usr/bin/env bash
# Render-time assertions for charts/aisix: what the config file, env and
# volumes look like for a given set of values, and which values the chart
# refuses. Needs helm and python3 with PyYAML.
set -euo pipefail

chart=charts/aisix
base=(-f "$chart/ci/default-values.yaml")
fails=0

render() { helm template ci "$chart" "${base[@]}" "$@"; }

# query <python expr over `docs` (the rendered manifests)> <helm args...>
query() {
  local expr=$1
  shift
  render "$@" | python3 -c '
import sys, yaml
docs = [d for d in yaml.safe_load_all(sys.stdin) if d]
dep = next(d for d in docs if d["kind"] == "Deployment")
pod = dep["spec"]["template"]["spec"]
env = {e["name"]: e for e in pod["containers"][0].get("env", [])}
vols = {v["name"] for v in pod.get("volumes", [])}
cm = next(d for d in docs if d["kind"] == "ConfigMap" and d["metadata"]["name"].endswith("-config"))
cfg = yaml.safe_load(cm["data"]["config.yaml"])
sys.exit(0 if eval(sys.argv[1]) else 1)
' "$expr"
}

check() {
  local what=$1
  shift
  if "$@"; then echo "ok   $what"; else echo "FAIL $what"; fails=$((fails + 1)); fi
}

refuses() {
  local want=$1
  shift
  local out
  if out=$(render "$@" 2>&1); then return 1; fi
  grep -q -- "$want" <<<"$out"
}

check "control-plane mode mounts the mTLS bundle as files" \
  query '"cp-mtls" in vols and cfg["managed"]["cp_cert_file"] == "/etc/aisix/cp-mtls/cert.pem" and not any(n.startswith("AISIX_MANAGED__CP_") for n in env)'
check "extraEnvVars PEMs keep the env wiring: no file keys, no mount, all three PEMs from the bundle Secret" \
  query '"cp-mtls" not in vols and not any(k.startswith("cp_") and k.endswith("_file") for k in cfg["managed"]) and all(env[f"AISIX_MANAGED__CP_{s}_PEM"].get("valueFrom") or env[f"AISIX_MANAGED__CP_{s}_PEM"].get("value") for s in ("CERT", "KEY", "CA"))' \
  --set 'extraEnvVars[0].name=AISIX_MANAGED__CP_CERT_PEM' --set 'extraEnvVars[0].value=pem'
check "configSecrets becomes a secretKeyRef env var" \
  query 'env["AISIX_CACHE__REDIS__PASSWORD"]["valueFrom"]["secretKeyRef"] == {"name": "redis-auth", "key": "password"}' \
  --set 'configSecrets.cache\.redis\.password.secretName=redis-auth' --set 'configSecrets.cache\.redis\.password.key=password'
check "config values land in the file, list-typed ones included" \
  query 'cfg["observability"]["heap_profiling"]["auto_dump"]["thresholds"] == [0.7, 0.95] and cfg["proxy"]["request_id"]["accept_headers"] == ["x-aisix-request-id", "x-request-id"]' \
  -f "$chart/ci/config-values.yaml"
check "standalone mode renders no etcd or managed section" \
  query '"etcd" not in cfg and "managed" not in cfg and cfg["admin"] == {"enabled": False} and cfg["resources_file"]' \
  -f "$chart/ci/standalone-values.yaml"
check "a chart-owned key under config is refused" \
  refuses "use containerPorts.proxy" --set config.proxy.addr=0.0.0.0:1
check "a credential under config is refused" \
  refuses "set it through configSecrets.cache.redis.password" --set config.cache.redis.password=x
check "a dotted key under config is refused" \
  refuses "contains a dot" --set 'config.cache\.redis\.password=x'
check "configSecrets outside the allow-list is refused" \
  refuses "not a credential-bearing setting" --set 'configSecrets.upstream\.timeout_ms.secretName=a' --set 'configSecrets.upstream\.timeout_ms.key=b'

[ "$fails" -eq 0 ] || { echo "$fails render check(s) failed"; exit 1; }
