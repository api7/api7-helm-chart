# aisix

![Version: 0.12.0](https://img.shields.io/badge/Version-0.12.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.12.0](https://img.shields.io/badge/AppVersion-0.12.0-informational?style=flat-square)

Helm chart for the AISIX AI gateway data plane

AISIX is an AI gateway: it fronts LLM providers with routing, rate limiting, budgets,
caching, guardrails, and observability behind an OpenAI-compatible API. This chart
installs the **data plane** — the component that serves live AI traffic.

The data plane is configured by the AISIX control plane, not by this chart. It
connects out to the control plane's data-plane manager over mutual TLS, using a
gateway certificate bundle issued from the console, and receives its models, API
keys, and policies from there. Install the control plane first — with the
[`aisix-cp`](../aisix-cp/README.md) chart, or any of the other options in the
[on-premises installation guide](https://docs.api7.ai/ai-gateway/on-premises/deployment).

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
* An AISIX control plane, reachable from the cluster
* A gateway certificate bundle for the environment this gateway should serve

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

Every field of the gateway's configuration file is reachable as an environment
variable named `AISIX_<SECTION>__<FIELD>`:

```yaml
extraEnvVars:
  - name: AISIX_OBSERVABILITY__LOG_LEVEL
    value: debug
  - name: AISIX_CACHE__BACKEND
    value: redis
```

## Parameters

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for the gateway pods |
| autoscaling.behavior | object | `{}` | `spec.behavior` for the HPA. Empty uses the Kubernetes defaults (immediate scale-up, 5-minute scale-down stabilization). A gateway that carries long streaming responses usually wants a gentler scale-down, e.g. `scaleDown: {policies: [{type: Pods, value: 1, periodSeconds: 60}]}` |
| autoscaling.enabled | bool | `false` | Create a HorizontalPodAutoscaler for the gateway Deployment |
| autoscaling.extraMetrics | list | `[]` | Extra `spec.metrics` entries appended verbatim — Pods / Object / External metrics such as a Prometheus adapter series |
| autoscaling.maxReplicas | int | `10` | Upper replica bound |
| autoscaling.minReplicas | int | `2` | Lower replica bound |
| autoscaling.targetCPUUtilizationPercentage | int | `70` | Target average CPU utilization, in percent of the CPU request. Set to null to drop the CPU metric |
| autoscaling.targetMemoryUtilizationPercentage | string | `nil` | Target average memory utilization, in percent of the memory request. Null by default: gateway memory tracks in-flight streams more than load |
| containerPorts.metrics | int | `9090` | Port the Prometheus metrics listener binds inside the container |
| containerPorts.proxy | int | `3000` | Port the proxy listener binds inside the container. The image carries the `CAP_NET_BIND_SERVICE` file capability, so a privileged port works without running as root — see `securityContext` below |
| controlPlane.baseURL | string | `""` | Data-plane manager mTLS endpoint the gateway connects out to, e.g. `https://dpm.example.com:7944`. Required. |
| controlPlane.certificate.ca | string | `""` | CA bundle PEM. Used only when `existingSecret` is empty |
| controlPlane.certificate.caKey | string | `"ca.pem"` | Secret key holding the CA bundle PEM |
| controlPlane.certificate.cert | string | `""` | Client certificate PEM. Used only when `existingSecret` is empty |
| controlPlane.certificate.certKey | string | `"cert.pem"` | Secret key holding the client certificate PEM |
| controlPlane.certificate.existingSecret | string | `""` | Read the bundle from an existing Secret instead of the PEM values below. Recommended: it keeps the private key out of your values file |
| controlPlane.certificate.key | string | `""` | Private key PEM. Used only when `existingSecret` is empty |
| controlPlane.certificate.keyKey | string | `"key.pem"` | Secret key holding the private key PEM |
| controlPlane.etcdEndpoint | string | `""` | Control-plane etcd endpoint as bare `host:port`. Leave empty unless the control plane publishes an etcd endpoint distinct from `baseURL` |
| controlPlane.heartbeatIntervalSeconds | int | `15` | Heartbeat interval in seconds. The control plane marks a gateway connected on its first heartbeat. Clamped to [5, 300] by the gateway |
| extraEnvVars | list | `[]` | Extra environment variables for the gateway container. Every gateway configuration field is reachable as `AISIX_<SECTION>__<FIELD>` |
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
| podSecurityContext.fsGroup | int | `10001` |  |
| podSecurityContext.runAsNonRoot | bool | `true` |  |
| podSecurityContext.runAsUser | int | `10001` |  |
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
| service.nodePort | string | `""` | Proxy Service nodePort, when `service.type` is NodePort or LoadBalancer |
| service.port | int | `80` | Proxy Service port |
| service.type | string | `"ClusterIP"` | Proxy Service type |
| serviceAccount.annotations | object | `{}` | ServiceAccount annotations |
| serviceAccount.create | bool | `true` | Create a ServiceAccount for the gateway |
| serviceAccount.name | string | `""` | ServiceAccount name. Defaults to the release fullname |
| startupProbe.enabled | bool | `true` | Gate liveness and readiness until the proxy listener is bound. The budget here (period x threshold) must stay longer than the gateway's own boot retries — it connects to the control plane before it binds, retrying for about 25s — or a recoverable boot race becomes a crash loop. |
| startupProbe.failureThreshold | int | `30` |  |
| startupProbe.periodSeconds | int | `2` |  |
| terminationGracePeriodSeconds | int | `1230` | Seconds the whole termination sequence may take, from the pod being marked for deletion to SIGKILL. It covers the `preStop` sleep, the gateway's own drain window, and the in-flight drain that follows — the gateway drains without a deadline of its own, so this value is the real cap. The default is sized to protect request success rate across a rolling update, and the trade-off is that a rolling update can take longer: it budgets two chained requests at the ten-minute timeout mainstream agent clients default to, plus the `preStop` sleep. It is a budget, not a guarantee — a response still running when it expires is cut. See "Termination and draining" in the README. |
| tolerations | list | `[]` | Tolerations for the gateway pods |
| topologySpreadConstraints | list | `[]` | Topology spread constraints, e.g. to spread replicas across zones |
| updateStrategy | object | `{}` | Deployment update strategy |
