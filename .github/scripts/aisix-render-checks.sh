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
# 1.5.0 rendered the chart's own PEM variables and then the extraEnvVars ones,
# duplicate names included. Rendering the same pair keeps an upgrade's
# three-way merge from deleting both entries of a name that one side drops.
check "extraEnvVars PEMs render after the chart's own, exactly as 1.5.0 did" \
  query '[e["name"] for e in pod["containers"][0]["env"] if e["name"] == "AISIX_MANAGED__CP_CERT_PEM"] == ["AISIX_MANAGED__CP_CERT_PEM"] * 2 and pod["containers"][0]["env"][[e["name"] for e in pod["containers"][0]["env"]].index("AISIX_MANAGED__CP_CERT_PEM")]["valueFrom"]["secretKeyRef"]["name"] == "aisix-gateway-certificate"' \
  --set 'extraEnvVars[0].name=AISIX_MANAGED__CP_CERT_PEM' --set 'extraEnvVars[0].value=pem'
# extraEnvVars wins on a repeated name (Kubernetes takes the last entry), and
# the chart drops its own entry for a name new since 1.5.0: a repeated name
# breaks upgrades after a rollback and is refused by server-side apply.
new_names=(--set 'configSecrets.cache\.redis\.password.secretName=redis-auth' --set 'configSecrets.cache\.redis\.password.key=password'
  --set 'extraEnvVars[0].name=AISIX_CACHE__REDIS__PASSWORD' --set 'extraEnvVars[0].value=user' --set 'extraEnvVars[1].name=TZ' --set 'extraEnvVars[1].value=UTC')
no_dups='all(len(names) == len(set(names)) for names in ([e["name"] for e in c.get("env", [])] for c in pod["containers"] + pod.get("initContainers", [])))'
check "extraEnvVars overriding a name new since 1.5.0 leaves no repeated name (control plane)" \
  query "$no_dups and env[\"AISIX_CACHE__REDIS__PASSWORD\"] == {\"name\": \"AISIX_CACHE__REDIS__PASSWORD\", \"value\": \"user\"}" "${new_names[@]}"
check "extraEnvVars overriding a name new since 1.5.0 leaves no repeated name (standalone)" \
  query "$no_dups and env[\"AISIX_CACHE__REDIS__PASSWORD\"][\"value\"] == \"user\"" -f "$chart/ci/standalone-values.yaml" "${new_names[@]}"
# A 1.5.0 release that overrides a name 1.5.0 rendered carries it twice; an
# upgrade whose manifest carries it once deletes both entries, the override
# included. So for those names the chart's own entry stays ahead of the user's.
old_names=(--set 'extraEnvVars[0].name=AISIX_MANAGED__CP_BASE_URL' --set 'extraEnvVars[0].value=https://cp.example.com'
  --set 'extraEnvVars[1].name=AISIX_MANAGED__HEARTBEAT_INTERVAL_SECS' --set-string 'extraEnvVars[1].value=42'
  --set 'extraEnvVars[2].name=AISIX_PROXY__ADDR' --set 'extraEnvVars[2].value=0.0.0.0:8080')
check "extraEnvVars overriding a name 1.5.0 rendered keeps 1.5.0's pair, the user's entry last" \
  query '[(e["name"], e["value"]) for e in pod["containers"][0]["env"] if e["name"] in ("AISIX_MANAGED__CP_BASE_URL", "AISIX_MANAGED__HEARTBEAT_INTERVAL_SECS", "AISIX_PROXY__ADDR")] == [("AISIX_PROXY__ADDR", "0.0.0.0:3000"), ("AISIX_MANAGED__CP_BASE_URL", "https://dp-manager.example.com:7944"), ("AISIX_MANAGED__HEARTBEAT_INTERVAL_SECS", "15"), ("AISIX_MANAGED__CP_BASE_URL", "https://cp.example.com"), ("AISIX_MANAGED__HEARTBEAT_INTERVAL_SECS", "42"), ("AISIX_PROXY__ADDR", "0.0.0.0:8080")]' \
  "${old_names[@]}"
check "1.5.0 never rendered control-plane names in standalone mode, so none repeats there" \
  query "$no_dups" -f "$chart/ci/standalone-values.yaml" "${old_names[@]:0:8}"
check "configSecrets becomes a secretKeyRef env var" \
  query 'env["AISIX_CACHE__REDIS__PASSWORD"]["valueFrom"]["secretKeyRef"] == {"name": "redis-auth", "key": "password"}' \
  --set 'configSecrets.cache\.redis\.password.secretName=redis-auth' --set 'configSecrets.cache\.redis\.password.key=password'
check "config values land in the file, list-typed ones included" \
  query 'cfg["observability"]["heap_profiling"]["auto_dump"]["thresholds"] == [0.7, 0.95] and cfg["proxy"]["request_id"]["accept_headers"] == ["x-aisix-request-id", "x-request-id"]' \
  -f "$chart/ci/config-values.yaml"
check "standalone mode renders no etcd or managed section" \
  query '"etcd" not in cfg and "managed" not in cfg and cfg["admin"] == {"enabled": False} and cfg["resources_file"]' \
  -f "$chart/ci/standalone-values.yaml"
admin_on=(-f "$chart/ci/standalone-values.yaml" --set admin.enabled=true --set 'admin.keys={k1,k2}')
check "admin disabled by default: admin.enabled false in the file, no admin port, env, Service or Secret" \
  query 'cfg["admin"] == {"enabled": False} and not any(p["name"] == "admin" for p in pod["containers"][0]["ports"]) and "AISIX_ADMIN__ADMIN_KEYS" not in env and not any(d["metadata"]["name"].endswith("-admin") for d in docs)' \
  -f "$chart/ci/standalone-values.yaml"
check "admin enabled: file binds the port, keys come from the chart Secret as env, ClusterIP Service on the admin port" \
  query 'cfg["admin"] == {"enabled": True, "addr": "0.0.0.0:3001"} and {"name": "admin", "containerPort": 3001, "protocol": "TCP"} in pod["containers"][0]["ports"] and env["AISIX_ADMIN__ADMIN_KEYS"]["valueFrom"]["secretKeyRef"] == {"name": "ci-aisix-admin", "key": "admin-keys"} and next(d for d in docs if d["kind"] == "Secret" and d["metadata"]["name"] == "ci-aisix-admin")["stringData"] == {"admin-keys": "k1,k2"} and next(d for d in docs if d["kind"] == "Service" and d["metadata"]["name"] == "ci-aisix-admin")["spec"]["type"] == "ClusterIP" and "k1" not in cm["data"]["config.yaml"] and all(p["name"] != "admin" for d in docs if d["kind"] == "Service" and d["metadata"]["name"] == "ci-aisix" for p in d["spec"]["ports"])' \
  "${admin_on[@]}"
check "admin with existingSecret reads that Secret and renders none of its own" \
  query 'env["AISIX_ADMIN__ADMIN_KEYS"]["valueFrom"]["secretKeyRef"] == {"name": "my-admin", "key": "keys"} and not any(d["kind"] == "Secret" and d["metadata"]["name"].endswith("-admin") for d in docs)' \
  -f "$chart/ci/standalone-values.yaml" --set admin.enabled=true --set admin.existingSecret=my-admin --set admin.existingSecretKey=keys
check "admin enabled without keys is refused" \
  refuses "admin.enabled requires admin keys" -f "$chart/ci/standalone-values.yaml" --set admin.enabled=true
check "admin enabled with a control plane is refused" \
  refuses "has no Admin API" --set admin.enabled=true --set 'admin.keys={k1}'
check "an admin key containing a comma is refused" \
  refuses "cannot contain a comma" -f "$chart/ci/standalone-values.yaml" --set admin.enabled=true --set 'admin.keys[0]=a\,b'
check "a chart-owned key under config is refused" \
  refuses "use containerPorts.proxy" --set config.proxy.addr=0.0.0.0:1
check "a credential under config is refused" \
  refuses "set it through configSecrets.cache.redis.password" --set config.cache.redis.password=x
check "a dotted key under config is refused" \
  refuses "contains a dot" --set 'config.cache\.redis\.password=x'
check "configSecrets outside the allow-list is refused" \
  refuses "not a credential-bearing setting" --set 'configSecrets.upstream\.timeout_ms.secretName=a' --set 'configSecrets.upstream\.timeout_ms.key=b'

[ "$fails" -eq 0 ] || { echo "$fails render check(s) failed"; exit 1; }
