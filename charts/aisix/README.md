# aisix

![Version: 1.5.0](https://img.shields.io/badge/Version-1.5.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.5.0](https://img.shields.io/badge/AppVersion-1.5.0-informational?style=flat-square)

Helm chart for the AISIX AI gateway data plane

AISIX is an AI gateway: it fronts LLM providers with routing, rate limiting, budgets,
caching, guardrails, and observability behind an OpenAI-compatible API. This chart
installs the **data plane** — the component that serves live AI traffic.

The chart installs it in either of two modes, chosen with `controlPlane.enabled`.

By default the gateway is configured by the AISIX control plane, not by this
chart. It connects out to the control plane's data-plane manager over mutual TLS,
using a gateway certificate bundle issued from the console, and receives its
models, API keys, and policies from there. Install the control plane first — with
the [`aisix-cp`](../aisix-cp/README.md) chart, or any of the other options in the
[on-premises installation guide](https://docs.api7.ai/ai-gateway/on-premises/deployment).

With `controlPlane.enabled: false` the gateway runs standalone, as the
open-source AI gateway with no control plane at all: every resource comes from
one declarative `resources.yaml` you supply through the chart. See
[Standalone mode](#standalone-mode-no-control-plane) below.

**Homepage:** <https://api7.ai>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| API7 | <support@api7.ai> | <https://api7.ai> |

## Source Code

* <https://github.com/api7/api7-helm-chart>

## Prerequisites

* Kubernetes v1.23+
* Helm v3+
* For the default mode: an AISIX control plane reachable from the cluster, and a
  gateway certificate bundle for the environment this gateway should serve
* For standalone mode: a `resources.yaml` declaring the provider keys, models and
  caller API keys the gateway should serve

## Install

In the console, open the target environment's **Data planes** view and issue a
gateway certificate. Keep the three PEM values — the private key is shown only once.

Put them in a Secret so the private key never lands in a values file:

```sh
kubectl create namespace aisix
kubectl -n aisix create secret generic aisix-gateway-certificate \
  --from-file=cert.pem=./cert.pem \
  --from-file=key.pem=./key.pem \
  --from-file=ca.pem=./ca.pem
```

Then install the chart, pointing it at the data-plane manager endpoint from the
same view:

```sh
helm repo add api7 https://charts.api7.ai
helm repo update

helm install aisix api7/aisix --namespace aisix \
  --set controlPlane.baseURL=https://dp-manager.example.com:7944 \
  --set controlPlane.certificate.existingSecret=aisix-gateway-certificate
```

The gateway appears in the environment's **Data planes** view once its first
heartbeat lands. Each replica registers as its own instance; they share one
certificate.

## Uninstall

```sh
helm delete aisix --namespace aisix
```

## Standalone mode (no control plane)

Set `controlPlane.enabled: false` to run the open-source gateway on its own.
Nothing under `controlPlane` is read, no certificate bundle is needed, and the
gateway reads every resource — provider keys, models, caller API keys,
guardrails, MCP servers, rate-limit policies — from one `resources.yaml`. The
chart renders a startup configuration pointing at it, mounts it read-only at
`/etc/aisix/resources/resources.yaml`. The file is the only way resources are
declared: the Admin API, off by default, only reads them (see
[Admin API](#admin-api)).

Supply the file through exactly one of `standalone.resources`,
`standalone.existingSecret`, or `standalone.existingConfigMap`; setting none or
more than one fails the render.

`standalone.resources` takes the file inline, as a map, and renders it into a
chart-managed Secret — a Secret rather than a ConfigMap because provider keys are
credentials. Credentials do not have to live in your values file even so: a
`${VAR}` reference is resolved from the container's environment when the file
loads, so the value itself can come from `extraEnvVars` or from a Secret you
manage separately.

```yaml
controlPlane:
  enabled: false

standalone:
  resources:
    _format_version: "1"
    provider_keys:
      - display_name: openai-main
        provider: openai
        adapter: openai
        api_key: ${OPENAI_API_KEY}
        api_base: https://api.openai.com/v1
    models:
      - display_name: gpt-4o-mini
        provider: openai
        model_name: gpt-4o-mini
        provider_key: openai-main
    api_keys:
      - display_name: my-caller
        key_env: CALLER_API_KEY
        allowed_models:
          - gpt-4o-mini

extraEnvVars:
  - name: OPENAI_API_KEY
    valueFrom:
      secretKeyRef:
        name: openai-credentials
        key: api-key
  - name: CALLER_API_KEY
    valueFrom:
      secretKeyRef:
        name: aisix-caller-keys
        key: my-caller
```

`standalone.existingSecret` and `standalone.existingConfigMap` read the file from
an object you already manage, under the key `resources.yaml`:

```sh
kubectl -n aisix create secret generic aisix-resources \
  --from-file=resources.yaml=./resources.yaml
```

```yaml
controlPlane:
  enabled: false

standalone:
  existingSecret: aisix-resources
```

Validate a file before you install it, without starting a listener:

```sh
docker run --rm -v "$(pwd):/work:ro" \
  --entrypoint /usr/local/bin/aisix api7/aisix:<appVersion> \
  validate --resources /work/resources.yaml
```

The file's own schema — every resource kind and field — is documented in the
[open-source gateway quickstart](https://docs.api7.ai/ai-gateway/getting-started/gateway-quickstart)
and the reference pages it links.

### Applying a change

The gateway re-reads `resources.yaml` on `SIGHUP` only, and this chart never
sends one, so a rollout is what applies a change.

Editing `standalone.resources` and running `helm upgrade` does that on its own:
the pod template carries a checksum of the rendered file, so the change rolls the
pods. Editing the Secret or ConfigMap behind `standalone.existingSecret` /
`standalone.existingConfigMap` does not — Kubernetes updates the mounted file in
place and nothing tells the gateway. Apply it with:

```sh
kubectl rollout restart deploy/<release>-aisix -n <namespace>
```

### What is not available

Standalone mode has no control plane, so there is no console, no usage or budget
reporting, and no per-environment configuration distribution.

### Admin API

The gateway's Admin API is off by default. With `admin.enabled: true` the chart
binds it on `containerPorts.admin` (3001) and publishes it on its own ClusterIP
Service, `<fullname>-admin` (`aisix-admin` for a release named `aisix`) — never
on the proxy Service. Against the resources file it is read-only: `/admin/v1/*`
lists and gets what the gateway loaded, including model status, and every
request there needs one of the admin keys as `Authorization: Bearer <key>` or
`x-api-key: <key>`. The same listener serves the Playground,
`POST /playground/chat/completions`, which takes a caller API key exactly like
the proxy.

The admin keys come from `admin.keys`, rendered into a chart-managed Secret, or
from a Secret you manage, named by `admin.existingSecret` (key
`admin.existingSecretKey`, default `admin-keys`; several keys comma-separated).
Either way they reach the gateway as the `AISIX_ADMIN__ADMIN_KEYS` environment
variable from that Secret and are never written to the config ConfigMap.
Enabling the API without keys fails the render, and so does enabling it with
`controlPlane.enabled: true`: a gateway connected to a control plane has no
Admin API.

```yaml
controlPlane:
  enabled: false
admin:
  enabled: true
  existingSecret: aisix-admin-keys
```

```sh
kubectl create secret generic aisix-admin-keys -n aisix --from-literal=admin-keys="$(openssl rand -hex 24)"
kubectl port-forward -n aisix svc/aisix-admin 3001:3001
curl -H "Authorization: Bearer <key>" http://127.0.0.1:3001/admin/v1/models
```

A release that already binds the Admin API through `AISIX_ADMIN__*` variables in
`extraEnvVars` keeps working unchanged, since the environment overrides the
config file; moving those settings to `admin` also gives the API its Service.

## Termination and draining

`terminationGracePeriodSeconds` defaults to 1230 seconds, far above the
Kubernetes default of 30. It is sized to protect request success rate across a
rolling update; the trade-off is that a rolling update can take longer.

On SIGTERM the gateway answers `/readyz` with 503 and keeps serving. It stops
accepting only once nothing is left in flight, and it drains with no deadline of
its own — so this value is the real cap on the whole sequence, and the `preStop`
sleep counts against it. When the cap expires Kubernetes sends SIGKILL, and every
request still in flight fails in the caller's hands.

The default is derived from how HTTP clients behave, not from any particular
workload. The gateway retires a keep-alive connection by marking its response
`Connection: close`, so the client learns of the retirement in a response it is
already receiving and the close that follows cannot race with a request being
dispatched onto that connection. What the gateway will not do is close a
connection the client has not been told about, which is the race a blind
server-side close creates.

Streaming responses are the case that does not fit. A stream that was already
sending when SIGTERM arrived has its headers on the wire, and HTTP/1.1 offers no
way to mark a connection retired after that. It runs to completion and goes back
to the client's pool unmarked; the client may reuse it once, and that response is
generated during the drain, carries `Connection: close`, and ends the chain
there.

So the drain has to cover two chained requests rather than one, and the default
budgets a ten-minute request for each — the timeout Claude Code, the Anthropic
SDKs, and the OpenAI Python and Node SDKs all default to — plus the 30s `preStop`
sleep. Client retries do not extend it: a retry is a new request, either on a
fresh connection the balancer routes to a pod that is not terminating, or on the
one reuse already counted here.

Treat it as a budget rather than a guarantee. A client's timeout reliably bounds
a non-streaming call, but it need not bound a stream that keeps producing output
— httpx, which the OpenAI Python SDK uses, measures inactivity between chunks
rather than total duration. A response still running when the grace period
expires is cut, so raise the value if your workloads stream for longer than it
allows.

Raising the value costs nothing while nothing runs that long: a pod exits as soon
as its last request finishes, so this is a ceiling and not a duration. Lower it
if your callers use a shorter timeout — the same arithmetic with a five-minute
client timeout gives 630 — or if you would rather bound how long a rolling update
may take, and accept that the longest streaming responses are cut.

## Configuration examples

The full list of values is in the [Parameters](#parameters) table below. Put these
in a `values.yaml` and pass it with `-f values.yaml`.

### Autoscale on CPU

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70
```

Requires `metrics-server` in the cluster. A replica the autoscaler adds is kept out
of the Service until its readiness probe passes, which happens only after it has
loaded its configuration from the control plane — so a scaling event never routes
traffic to a gateway that cannot serve it.

Scale-down is guarded from the other side, in two stages that cover the two ways
a balancer can learn a pod is going away.

A balancer that watches the Kubernetes API — a Service, or a cloud load balancer
wired to one — sees the endpoint removed the moment the pod is marked for
deletion. That removal and SIGTERM are concurrent, so the `preStop` sleep holds
the pod in place while it propagates.

A balancer that polls a health check instead sees nothing during that sleep: the
pod is still fully ready. It is covered by the gateway itself, which on SIGTERM
answers `/readyz` with 503 while continuing to accept for
`shutdown.min_drain_secs` (30s by default) — long enough for the next health
check to withdraw it. Point such a check at `/readyz`, not at a bare TCP connect:
a TCP check cannot see readiness at all, so the only signal it ever gets is the
listener closing, which is the very event the drain exists to avoid.

Only then does the gateway stop accepting, and only once nothing is left in
flight. What caps the whole sequence is `terminationGracePeriodSeconds`, covered
in [Termination and draining](#termination-and-draining) above.

### Autoscale on request load with KEDA

CPU is a proxy for load; the gateway's own metrics are the real signal. With
[KEDA](https://keda.sh) installed, scale on a Prometheus query instead:

```yaml
metrics:
  serviceMonitor:
    enabled: true

keda:
  enabled: true
  minReplicas: 2
  maxReplicas: 20
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://prometheus.monitoring.svc:9090
        query: sum(rate(aisix_llm_requests_total[2m]))
        threshold: "100"
```

`autoscaling` and `keda` are mutually exclusive — enabling both fails the render
rather than letting two controllers fight over the replica count.

### Share rate-limit counters across replicas

Rate-limit counters are per-replica by default, so N replicas enforce N× every
configured limit. Before running more than one replica — including any replica an
autoscaler adds — point the gateway at a shared Redis:

```yaml
rateLimit:
  backend: redis
  redis:
    url: redis://redis.default.svc:6379
```

Use `rateLimit.redis.existingSecret` instead when the URL carries a password.

### Publish the gateway through a load balancer

```yaml
service:
  type: LoadBalancer
  port: 80
  # Preserve the client source IP, which the gateway uses for IP allowlists.
  externalTrafficPolicy: Local
```

### Serve HTTPS and plain HTTP together

By default the gateway serves one plain-HTTP proxy listener, on
`containerPorts.proxy`, published as `service.port`. Set `listeners` to serve
several at once — each on its own port, with its own TLS:

```yaml
listeners:
  - name: https                 # port name, shared by the container port and the Service port
    containerPort: 3443
    servicePort: 443
    nodePort: 0                 # optional; only for non-ClusterIP Service types
    tls:
      secretName: aisix-proxy-tls   # kubernetes.io/tls Secret (keys tls.crt / tls.key)
  - name: http
    containerPort: 3000
    servicePort: 80
```

A non-empty `listeners` is the complete set of proxy listeners and replaces the
single default one: nothing binds `containerPorts.proxy`, and `service.port` /
`service.nodePort` are not read — each entry carries its own. There is still one
proxy Service; it publishes a port per entry. Every listener serves the same
routes, `/livez` and `/readyz` included, so the probes target the first entry
(over HTTPS when that entry terminates TLS; the kubelet does not verify the
certificate). This needs a gateway image that supports `proxy.listeners`.

TLS material is read from files, so each TLS listener needs a
`kubernetes.io/tls` Secret; the chart mounts it read-only at
`/etc/aisix/tls/<name>`. Create it from a certificate and key you already have:

```sh
kubectl -n aisix create secret tls aisix-proxy-tls \
  --cert=./tls.crt --key=./tls.key
```

Or have [cert-manager](https://cert-manager.io) issue and renew it into the same
Secret:

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: aisix-proxy-tls
  namespace: aisix
spec:
  secretName: aisix-proxy-tls
  dnsNames:
    - gateway.example.com
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
```

A rotated certificate reaches the gateway as a changed file in that mount; roll
the pods to pick it up with
`kubectl rollout restart deploy/<release>-aisix -n <namespace>`.

### Bind a privileged port

The image carries the `CAP_NET_BIND_SERVICE` file capability, so the gateway binds
low ports without running as root:

```yaml
containerPorts:
  proxy: 80
```

### Survive node drains

```yaml
podDisruptionBudget:
  enabled: true
  minAvailable: 50%

topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: ScheduleAnyway
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: aisix
```

### Set any other gateway configuration

The gateway reads its settings from a configuration file the chart renders into
a ConfigMap, in both modes. `config` in `values.yaml` mirrors that file key for
key — the same section and key names as the gateway's own `config.example.yaml`
— and lists every setting with the gateway's default, so change only what you
need:

```yaml
config:
  observability:
    log_level: debug
  upstream:
    pool_idle_timeout_secs: 15
  proxy:
    real_ip:
      trusted_proxies: ["10.0.0.0/8"]
      recursive: true
```

A `null` leaves the key to the gateway's default. A change rolls the pods on
`helm upgrade`.

A few keys are set by the chart from its other values and are rejected under
`config` with a message naming the value to use instead: the proxy and metrics
addresses (`containerPorts`), `proxy.listeners` (`listeners`),
`ratelimit.backend` and the rate-limit Redis URL (`rateLimit`), the
control-plane connection (`controlPlane`), and the standalone resources file
(`standalone`). The list is in the chart's `config-policy.yaml`.

Settings that hold a credential never go into the ConfigMap. Put the value in a
Secret and name it under `configSecrets`, keyed by the configuration path; the
chart hands it to the gateway as an environment variable that overrides the
file:

```yaml
config:
  cache:
    backend: redis
    redis:
      mode: single
configSecrets:
  cache.redis.url:
    secretName: aisix-cache-redis
    key: url
  cache.redis.password:
    secretName: aisix-cache-redis
    key: password
```

`configSecrets` accepts `cache.redis.url`, `cache.redis.username`,
`cache.redis.password`, `ratelimit.redis.username` and
`ratelimit.redis.password`.

`extraEnvVars` is for system-level environment variables such as `TZ`, and for
the variables a standalone resources file references. An `AISIX_*` variable set
there still overrides the file, as it always has.

Overriding a variable the chart sets itself through `extraEnvVars` is only a
compatibility path for existing deployments, and the `extraEnvVars` value still
wins. For a name chart 1.5.0 set (such as `AISIX_MANAGED__CP_BASE_URL` or
`AISIX_MANAGED__HEARTBEAT_INTERVAL_SECS`) the chart keeps rendering its own
entry ahead of yours, so a Helm 3 upgrade from 1.5.0 does not drop the override;
the container then lists the name twice, which Helm 4 server-side apply
rejects. New installs set the value in its own key in `values.yaml` or under
`config` instead.

## Parameters

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| admin.enabled | bool | `false` | Bind the Admin API on `containerPorts.admin` and create the admin Service. Requires `controlPlane.enabled=false` and admin keys from `keys` or `existingSecret` |
| admin.existingSecret | string | `""` | Read the admin keys from an existing Secret instead, so they stay out of your values file. The value is one key, or several separated by commas |
| admin.existingSecretKey | string | `"admin-keys"` | Secret key holding the admin keys |
| admin.keys | list | `[]` | Admin keys, rendered into a chart-managed Secret and passed to the gateway from it. A key cannot contain a comma |
| admin.service.annotations | object | `{}` | Extra annotations for the admin Service |
| admin.service.port | int | `3001` | Admin Service port |
| affinity | object | `{}` | Affinity rules for the gateway pods |
| autoscaling.behavior | object | `{}` | `spec.behavior` for the HPA. Empty uses the Kubernetes defaults (immediate scale-up, 5-minute scale-down stabilization). A gateway that carries long streaming responses usually wants a gentler scale-down, e.g. `scaleDown: {policies: [{type: Pods, value: 1, periodSeconds: 60}]}` |
| autoscaling.enabled | bool | `false` | Create a HorizontalPodAutoscaler for the gateway Deployment |
| autoscaling.extraMetrics | list | `[]` | Extra `spec.metrics` entries appended verbatim — Pods / Object / External metrics such as a Prometheus adapter series |
| autoscaling.maxReplicas | int | `10` | Upper replica bound |
| autoscaling.minReplicas | int | `2` | Lower replica bound |
| autoscaling.targetCPUUtilizationPercentage | int | `70` | Target average CPU utilization, in percent of the CPU request. Set to null to drop the CPU metric |
| autoscaling.targetMemoryUtilizationPercentage | string | `nil` | Target average memory utilization, in percent of the memory request. Null by default: gateway memory tracks in-flight streams more than load |
| config.bedrock_endpoint_url | string | `nil` | Deployment-wide AWS Bedrock endpoint override for bedrock guardrails, e.g. a LocalStack URL. Null uses the AWS SDK default |
| config.cache.backend | string | `"memory"` | Legacy cache backend switch, `memory` or `redis`. `redis` requires `cache.redis`. Which cache serves a request is chosen per cache policy |
| config.cache.redis | object | `nil` | Shared Redis for the response cache, e.g. `{mode: single}`; the redis cache is built only when this is set. Keys: `mode` (single, cluster, sentinel), `nodes`, `sentinels`, `master_name`, `database`, `tls`, `timeout_secs`. `url`, `username` and `password` go through `configSecrets` |
| config.downstream.idle_timeout_secs | int | `0` | Seconds an idle client connection is held. 0 never closes it |
| config.downstream.sse_keepalive_interval_secs | int | `15` | Seconds between SSE keepalive comments on a stalled stream |
| config.etcd.dial_timeout_ms | int | `5000` | Bound on one dial to the control plane's etcd, in milliseconds. 0 means unbounded |
| config.etcd.request_timeout_ms | int | `nil` | Bound on one etcd request, in milliseconds. Null means unbounded |
| config.managed.cp_ca_cert_file | string | `nil` | Extra CA bundle trusted for the control-plane connection, when it serves a private-CA certificate. Mount the file through `extraVolumes` |
| config.managed.dp_id_file | string | `"/var/lib/aisix/dp_id"` | File the gateway id is persisted in |
| config.managed.mtls_dir | string | `"/var/lib/aisix/mtls"` | Directory the materialised mTLS bundle is written to |
| config.managed.snapshot_cache_enabled | bool | `false` | Persist a configuration snapshot for recovery while etcd is unreachable. The snapshot holds unencrypted credentials |
| config.managed.snapshot_cache_path | string | `nil` | Snapshot location. Null uses `/var/lib/aisix/config_cache.json` |
| config.observability.access_log | bool | `true` | Write an access-log line per request |
| config.observability.debug.addr | string | `"127.0.0.1:9091"` | Diagnostics listener address. Loopback keeps it off the network |
| config.observability.debug.enabled | bool | `true` | Serve the unauthenticated heap-profile endpoint (`/debug/pprof/heap`) |
| config.observability.heap_profiling.auto_dump.dir | string | `"/var/lib/aisix/heap"` | Directory the profiles are written to |
| config.observability.heap_profiling.auto_dump.enabled | bool | `true` | Write a heap profile as resident memory nears the memory limit |
| config.observability.heap_profiling.auto_dump.keep | int | `5` | Newest profiles kept |
| config.observability.heap_profiling.auto_dump.thresholds | list | `[0.8,0.9]` | Fractions of the memory limit that each trigger one profile |
| config.observability.log_level | string | `"info"` | Log level: trace, debug, info, warn or error |
| config.observability.metrics.buckets | object | `{"a2a_ttfb":null,"guardrail_latency":null,"request_e2e_latency":null,"request_ttft":null}` | Per-metric histogram bucket edges in seconds. Null keeps that metric's default buckets |
| config.observability.metrics.client_type_rules | list | `[]` | User-Agent to `client_type` mapping rules, first match wins, e.g. `[{pattern: "^py-billing-batcher/", client: billing-batcher}]` |
| config.observability.metrics.labels | object | `{}` | Complete optional label list per metric, e.g. `{aisix_request_ttft_seconds: [model, provider]}`. Omitted metrics keep their default labels |
| config.observability.metrics.prometheus.enabled | bool | `true` | Serve Prometheus metrics on the metrics listener (`containerPorts.metrics`) |
| config.observability.metrics.prometheus.path | string | `"/metrics"` | Metrics path |
| config.observability.service_name | string | `"aisix"` | Service name reported in telemetry |
| config.observability.usage_event.request_headers | list | `[]` | Request headers whose values every usage event records (lowercase names; credential headers and duplicates are refused at startup) |
| config.proxy.real_ip.header | string | `"x-forwarded-for"` | Header carrying the client IP |
| config.proxy.real_ip.recursive | bool | `false` | Walk the header right to left past every trusted proxy |
| config.proxy.real_ip.trusted_proxies | list | `[]` | CIDRs (or bare IPs) of proxies trusted to set the client-IP header |
| config.proxy.request_body_limit_bytes | int | `0` | Request-body size cap in bytes. 0 means no cap |
| config.proxy.request_id.accept_headers | list | `["x-aisix-request-id"]` | Headers a caller may supply its own request id in. Add `x-request-id` only when no proxy in front stamps it |
| config.proxy.thread_per_core | bool | `nil` | Thread-per-core serving topology. Null uses the gateway default (on for Linux) |
| config.proxy.url_rewrites | list | `[]` | Entry-level URL rewrite rules, first match wins, e.g. `[{name: per-server-mcp, match: "^/mcp-servers/([^/]+)/mcp$", rewrite: "/mcp/$1"}]` |
| config.proxy.workers | int | `nil` | Worker count. Null uses the gateway default |
| config.ratelimit.concurrency_ttl_secs | int | `300` | Seconds a concurrency-limit slot is held at most |
| config.ratelimit.redis | object | `nil` | Extra settings for the shared rate-limit Redis selected by `rateLimit.backend: redis`, e.g. `{timeout_secs: 2}` or `{mode: cluster, nodes: [...]}`. Same keys as `cache.redis`; the URL comes from `rateLimit.redis`, `username` and `password` go through `configSecrets` |
| config.shutdown.min_drain_secs | int | `30` | Seconds the gateway keeps accepting after SIGTERM while `/readyz` reports 503. `terminationGracePeriodSeconds` must cover it |
| config.upstream.connect_timeout_ms | int | `5000` | Connect timeout in milliseconds |
| config.upstream.pool_idle_timeout_secs | int | `30` | Seconds an idle pooled connection is kept. Lower it when a load balancer or NAT between the gateway and the provider closes idle connections sooner |
| config.upstream.pool_max_idle_per_host | int | `nil` | Idle pooled connections kept per host. Null means unbounded |
| config.upstream.retries | int | `2` | Retry budget every dispatch starts from |
| config.upstream.stream_timeout_ms | int | `0` | Streaming idle timeout in milliseconds. 0 means none |
| config.upstream.tcp_keepalive_interval_secs | int | `30` | TCP keepalive probe interval in seconds |
| config.upstream.tcp_keepalive_retries | int | `5` | TCP keepalive probes before the connection is dropped |
| config.upstream.tcp_keepalive_secs | int | `60` | TCP keepalive idle time in seconds |
| config.upstream.timeout_ms | int | `6000000` | Request timeout for calls to LLM providers, in milliseconds |
| config.upstream.tls.ca_file | string | `nil` | Extra CA bundle, added to the platform trust store, for every upstream TLS handshake. Mount the file through `extraVolumes` |
| config.upstream.tls.client_cert_file | string | `nil` | Client certificate for mutual TLS to upstreams |
| config.upstream.tls.client_key_file | string | `nil` | Client key for mutual TLS to upstreams |
| config.upstream.tls.verify | bool | `true` | Verify upstream certificates. false accepts any certificate — test use only |
| configSecrets | object | `{}` | Configuration keys that hold a credential, each read from a Secret you supply and handed to the gateway as an environment variable (which overrides the config file), never written to the ConfigMap. Keyed by the configuration path: `cache.redis.url`, `cache.redis.username`, `cache.redis.password`, `ratelimit.redis.username` or `ratelimit.redis.password`. For example `{cache.redis.password: {secretName: redis-auth, key: password}}` |
| containerPorts.admin | int | `3001` | Port the Admin API listener binds inside the container. Bound only when `admin.enabled` is true |
| containerPorts.metrics | int | `9090` | Port the Prometheus metrics listener binds inside the container |
| containerPorts.proxy | int | `3000` | Port the proxy listener binds inside the container. Nothing binds it when `listeners` is set — that list then carries every proxy port, and the gateway keeps requiring this address only to ignore it. The image carries the `CAP_NET_BIND_SERVICE` file capability, so a privileged port works without running as root — see `securityContext` below |
| controlPlane.baseURL | string | `""` | Data-plane manager mTLS endpoint the gateway connects out to, e.g. `https://dpm.example.com:7944`. Required. |
| controlPlane.certificate.ca | string | `""` | CA bundle PEM. Used only when `existingSecret` is empty |
| controlPlane.certificate.caKey | string | `"ca.pem"` | Secret key holding the CA bundle PEM |
| controlPlane.certificate.cert | string | `""` | Client certificate PEM. Used only when `existingSecret` is empty |
| controlPlane.certificate.certKey | string | `"cert.pem"` | Secret key holding the client certificate PEM |
| controlPlane.certificate.existingSecret | string | `""` | Read the bundle from an existing Secret instead of the PEM values below. Recommended: it keeps the private key out of your values file |
| controlPlane.certificate.key | string | `""` | Private key PEM. Used only when `existingSecret` is empty |
| controlPlane.certificate.keyKey | string | `"key.pem"` | Secret key holding the private key PEM |
| controlPlane.enabled | bool | `true` | Read configuration from an AISIX control plane. Set to false to run standalone, from the `resources.yaml` file configured under `standalone` |
| controlPlane.etcdEndpoint | string | `""` | Control-plane etcd endpoint as bare `host:port`. Leave empty unless the control plane publishes an etcd endpoint distinct from `baseURL` |
| controlPlane.heartbeatIntervalSeconds | int | `15` | Heartbeat interval in seconds. The control plane marks a gateway connected on its first heartbeat. Clamped to [5, 300] by the gateway |
| extraEnvVars | list | `[]` | Extra environment variables for the gateway container: system-level environment variables (such as `TZ`) and variables referenced by the resources file. Gateway settings belong in `config`. Overriding a variable the chart sets itself is only a compatibility path for existing deployments: for a name chart 1.5.0 set, the rendered container then lists it twice, which Helm 4 server-side apply rejects. New installs set the value in its own key or under `config` |
| extraVolumeMounts | list | `[]` | Extra volume mounts for the gateway container |
| extraVolumes | list | `[]` | Extra volumes for the gateway pod |
| fullnameOverride | string | `""` | Override the fully qualified resource name prefix |
| global.imagePullSecrets | list | `[]` | Image pull secrets applied to every pod created by this chart |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"docker.io/api7/aisix"` | Gateway image repository |
| image.tag | string | `""` | Image tag. Empty resolves to the chart `appVersion` |
| keda.annotations | object | `{}` | Extra annotations for the ScaledObject |
| keda.behavior | object | `{}` | `behavior` for the HPA KEDA creates. Empty uses the Kubernetes defaults |
| keda.cooldownPeriod | int | `300` | Seconds to wait after the last trigger fires before scaling down |
| keda.enabled | bool | `false` | Create a KEDA ScaledObject for the gateway Deployment |
| keda.fallback | object | `{}` | Replica count to fall back to when a trigger source is unreachable, e.g. `{failureThreshold: 3, replicas: 4}` |
| keda.maxReplicas | int | `10` | Upper replica bound |
| keda.minReplicas | int | `2` | Lower replica bound |
| keda.pollingInterval | int | `15` | How often KEDA evaluates the triggers, in seconds |
| keda.restoreToOriginalReplicaCount | bool | `false` | Restore the original replica count when the ScaledObject is deleted |
| keda.triggers | list | `[]` | KEDA triggers. Required when `keda.enabled` is true. For example: `[{type: prometheus, metadata: {serverAddress: "http://prometheus:9090", query: "sum(rate(aisix_llm_requests_total[2m]))", threshold: "100"}}]` |
| listeners | list | `[]` | Proxy listeners, one entry per port. Empty keeps the single plain-HTTP listener described by `containerPorts.proxy` and `service.port` — see "Serve HTTPS and plain HTTP together" above |
| livenessProbe.enabled | bool | `true` |  |
| livenessProbe.failureThreshold | int | `3` |  |
| livenessProbe.initialDelaySeconds | int | `10` |  |
| livenessProbe.periodSeconds | int | `10` |  |
| metrics.enabled | bool | `true` | Publish the gateway's Prometheus metrics on a separate ClusterIP Service, so scraping never rides the (possibly public) proxy Service |
| metrics.service.annotations | object | `{}` | Extra annotations for the metrics Service |
| metrics.service.port | int | `9090` | Metrics Service port |
| metrics.serviceMonitor.enabled | bool | `false` | Create a Prometheus Operator ServiceMonitor for the metrics Service |
| metrics.serviceMonitor.interval | string | `"30s"` | Scrape interval |
| metrics.serviceMonitor.labels | object | `{}` | Extra labels, e.g. the `release` label your Prometheus selects on |
| metrics.serviceMonitor.metricRelabelings | list | `[]` | Metric relabeling rules |
| metrics.serviceMonitor.namespace | string | `""` | Namespace to create the ServiceMonitor in. Empty uses the release namespace |
| metrics.serviceMonitor.relabelings | list | `[]` | Scrape-time relabeling rules |
| metrics.serviceMonitor.scrapeTimeout | string | `""` | Scrape timeout. Empty leaves the Prometheus default |
| nameOverride | string | `""` | Override the chart name used in resource names |
| nodeSelector | object | `{}` | Node selector for the gateway pods |
| podAnnotations | object | `{}` | Annotations for the gateway pods |
| podDisruptionBudget.enabled | bool | `false` | Create a PodDisruptionBudget so voluntary disruptions (node drains, cluster upgrades) cannot take the whole gateway down at once |
| podDisruptionBudget.maxUnavailable | int | `1` | Maximum unavailable pods |
| podDisruptionBudget.minAvailable | string | `""` | Minimum available pods. Takes precedence over `maxUnavailable` |
| podLabels | object | `{}` | Labels for the gateway pods |
| podSecurityContext.runAsNonRoot | bool | `true` |  |
| podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| preStopSleepSeconds | int | `30` | Seconds to sleep in a `preStop` hook before the gateway receives SIGTERM. Endpoint removal and SIGTERM are concurrent, so without this pause a terminating pod can still be handed new connections by a kube-proxy that has not caught up. Set to 0 to drop the hook.  This covers balancers that learn about the pod from the Kubernetes API. One that polls a health check instead learns nothing here — the pod is still fully ready throughout the sleep — and is covered by the gateway's own drain window (`shutdown.min_drain_secs`, 30s by default), which starts at SIGTERM with `/readyz` already answering 503. |
| priorityClassName | string | `""` | Pod priority class |
| rateLimit.backend | string | `"memory"` | Rate-limit counter backend: `memory` (per-replica) or `redis` (shared) |
| rateLimit.redis.existingSecret | string | `""` | Read the connection URL from an existing Secret instead, so a URL carrying a password stays out of your values file |
| rateLimit.redis.existingSecretKey | string | `"redis-url"` | Secret key holding the connection URL |
| rateLimit.redis.url | string | `""` | Redis connection URL, e.g. `redis://redis.default.svc:6379`. Required when `rateLimit.backend` is redis and `existingSecret` is empty |
| readinessProbe.enabled | bool | `true` |  |
| readinessProbe.failureThreshold | int | `3` |  |
| readinessProbe.periodSeconds | int | `3` |  |
| replicaCount | int | `2` | Number of gateway replicas. Ignored once `autoscaling.enabled` or `keda.enabled` is true — the autoscaler owns the replica count from then on and the Deployment omits `spec.replicas` so `helm upgrade` cannot reset it. |
| resources.limits.memory | string | `"1Gi"` |  |
| resources.requests.cpu | string | `"500m"` |  |
| resources.requests.memory | string | `"256Mi"` |  |
| securityContext.allowPrivilegeEscalation | bool | `false` |  |
| securityContext.capabilities.add[0] | string | `"NET_BIND_SERVICE"` |  |
| securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| securityContext.readOnlyRootFilesystem | bool | `true` |  |
| service.annotations | object | `{}` | Extra annotations for the proxy Service, e.g. cloud load-balancer settings |
| service.externalTrafficPolicy | string | `""` | `externalTrafficPolicy` for the proxy Service. `Local` preserves the client source IP on NodePort / LoadBalancer types |
| service.nodePort | string | `""` | Proxy Service nodePort, when `service.type` is NodePort or LoadBalancer. Unused when `listeners` is set — each entry there carries its own `nodePort` |
| service.port | int | `80` | Proxy Service port. Unused when `listeners` is set — each entry there carries its own `servicePort` |
| service.type | string | `"ClusterIP"` | Proxy Service type |
| serviceAccount.annotations | object | `{}` | ServiceAccount annotations |
| serviceAccount.create | bool | `true` | Create a ServiceAccount for the gateway |
| serviceAccount.name | string | `""` | ServiceAccount name. Defaults to the release fullname |
| standalone.existingConfigMap | string | `""` | Read `resources.yaml` from an existing ConfigMap instead, under key `resources.yaml`. Use only when every credential in it is a `${VAR}` reference resolved from `extraEnvVars` |
| standalone.existingSecret | string | `""` | Read `resources.yaml` from an existing Secret instead, under key `resources.yaml`. Recommended when the file carries literal credentials |
| standalone.resources | object | `{}` | Inline `resources.yaml` content, as a map. Rendered into a chart-managed Secret, because provider keys are credentials. Values may reference environment variables as `${VAR}` — supply them through `extraEnvVars` — so the credential itself need not live in this file |
| startupProbe.enabled | bool | `true` | Gate liveness and readiness until the proxy listener is bound. In etcd mode that happens only after the gateway's first configuration apply succeeds, so the budget here (period x threshold) has to cover reaching the configuration source and applying what it holds — not merely starting the process. How long that apply takes scales with how much configuration the environment holds, so the 300s default (2s x 150) is deliberately generous headroom for a large one rather than a bound tuned to a measured boot. The period stays short so an ordinary boot still passes within a couple of seconds and rollouts are not slowed by the headroom; only the pathological case waits.  The budget is also wide enough to contain the gateway's own retry schedule. It keeps retrying the configuration read on an exponential backoff — capped at a minute between attempts — for as long as it is up, and binds the moment one attempt succeeds. A configuration source that comes back inside the budget is therefore retried while the budget still has room, and the instance binds on its own, with no restart. A budget much shorter than the backoff's cap truncates that schedule instead, and kills the container in the gap before the retry that would have worked.  Once the budget does expire the kubelet kills and restarts the container — the Pod is not recreated — which remains the intended outcome for a source that stays unreachable: an instance that has never applied a configuration has nothing to serve, and the restarted container simply resumes the same wait. Boots that bind immediately — file mode, and an etcd-mode boot that restores a usable snapshot cache — are unaffected. |
| startupProbe.failureThreshold | int | `150` |  |
| startupProbe.periodSeconds | int | `2` |  |
| terminationGracePeriodSeconds | int | `1230` | Seconds the whole termination sequence may take, from the pod being marked for deletion to SIGKILL. It covers the `preStop` sleep, the gateway's own drain window, and the in-flight drain that follows — the gateway drains without a deadline of its own, so this value is the real cap. The default is sized to protect request success rate across a rolling update, and the trade-off is that a rolling update can take longer: it budgets two chained requests at the ten-minute timeout mainstream agent clients default to, plus the `preStop` sleep. It is a budget, not a guarantee — a response still running when it expires is cut. See "Termination and draining" in the README. |
| tolerations | list | `[]` | Tolerations for the gateway pods |
| topologySpreadConstraints | list | `[]` | Topology spread constraints, e.g. to spread replicas across zones |
| updateStrategy | object | `{}` | Deployment update strategy |
