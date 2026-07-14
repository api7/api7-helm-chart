# ngxdig

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

eBPF on-CPU flame graphs and guided CPU/memory/latency diagnosis for OpenResty/Nginx, deployed as a per-node collector

**Homepage:** <https://github.com/api7/ngx-flame>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| API7 | <support@api7.ai> | <https://api7.ai> |

## Source Code

* <https://github.com/api7/ngx-flame>

## Install

```sh
helm repo add api7 https://charts.api7.ai
helm repo update

helm install ngxdig api7/ngxdig --namespace ngxdig --create-namespace
```

ngxdig is deployed as a DaemonSet — one collector Pod per node — so it can
profile the OpenResty/Nginx (and APISIX) worker processes running on that node.

## Accessing the debug UI

Most deployments run a single collector — one node, or the DaemonSet pinned to
one node (see below) — so the `ClusterIP` Service the chart creates points at
that one Pod. For quick local access, port-forward straight to the collector
Pod:

```sh
kubectl -n ngxdig port-forward \
  $(kubectl -n ngxdig get pod -l app.kubernetes.io/name=ngxdig -o jsonpath='{.items[0].metadata.name}') \
  8080:8080
# then open http://127.0.0.1:8080/
```

The UI is not a hardened multi-user service — keep it on a trusted network and
prefer a port-forward over a public ingress. When the DaemonSet spans several
nodes, each collector only sees its own node's processes, so select the Pod on
the node you want with `--field-selector spec.nodeName=<node>`.

## Run on specific node(s) only

Usually you only want a collector on the node running the workload you are
debugging, not every node. Restrict the DaemonSet with a `nodeSelector`; the
controller then creates a Pod only on matching nodes.

Pin to a single node by its built-in `kubernetes.io/hostname` label (the value
is the node name shown by `kubectl get nodes`):

```sh
helm install ngxdig api7/ngxdig --namespace ngxdig --create-namespace \
  --set nodeSelector."kubernetes\.io/hostname"=<node-name>
```

To target a group of nodes, label them first and select by that label:

```sh
kubectl label node <node-a> <node-b> ngxdig=enabled
```

```yaml
# values.yaml
nodeSelector:
  ngxdig: enabled
```

For rules that `nodeSelector` cannot express, use `affinity` instead. Note that
for a DaemonSet you should not set the Pod's `.spec.nodeName` directly — node
placement is owned by the DaemonSet controller, and `nodeSelector`/`affinity`
is the supported way to constrain it.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for the DaemonSet Pods |
| containerPort | int | `8080` | Port the ngxdig UI listens on inside the container |
| extraArgs | list | `[]` | Extra arguments appended to the `ngxdig ui` command |
| extraEnvVars | list | `[]` | Extra environment variables for the collector container |
| extraVolumeMounts | list | `[]` | Extra volume mounts for the collector container |
| extraVolumes | list | `[]` | Extra volumes for the collector Pod |
| fullnameOverride | string | `""` | Override the fully qualified release name |
| hostBtf.enabled | bool | `true` | Mount the node's kernel BTF read-only. Required by the eBPF collector to resolve kernel types without DWARF |
| hostBtf.path | string | `"/sys/kernel/btf"` | Host path to the kernel BTF directory |
| hostPID | bool | `true` | Share the host PID namespace so the collector can see Nginx/OpenResty worker processes elsewhere on the node. Required to profile targets outside the collector's own Pod |
| image.pullPolicy | string | `"Always"` | Image pull policy. Defaults to Always because the image tag is the moving `latest`, so nodes must re-pull to pick up newer builds |
| image.repository | string | `"api7/ngxdig"` | ngxdig image repository |
| image.tag | string | `"latest"` | Image tag. Defaults to the chart appVersion when left empty |
| imagePullSecrets | list | `[]` | Image pull secrets for a private registry |
| livenessProbe | object | `{"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":10,"periodSeconds":15}` | Liveness probe for the collector container |
| nameOverride | string | `""` | Override the chart name |
| nodeSelector | object | `{}` | Node selector for the DaemonSet Pods |
| output.path | string | `"/out"` | Directory inside the container where run artifacts are written |
| output.sizeLimit | string | `""` | sizeLimit for the artifact emptyDir volume. No limit when empty |
| podAnnotations | object | `{}` | Additional annotations for the Pods |
| podLabels | object | `{}` | Additional labels for the Pods |
| podSecurityContext | object | `{}` | Pod-level security context |
| readinessProbe | object | `{"httpGet":{"path":"/","port":"http"},"initialDelaySeconds":5,"periodSeconds":10}` | Readiness probe for the collector container |
| resources | object | `{}` | Resource requests and limits for the collector container |
| securityContext | object | `{"appArmorProfile":{"type":"Unconfined"},"capabilities":{"add":["BPF","PERFMON","SYS_PTRACE","SYS_ADMIN"]},"runAsUser":0,"seccompProfile":{"type":"Unconfined"}}` | Container security context. The defaults grant exactly what the eBPF collector needs: run as root, and the CAP_BPF / CAP_PERFMON / CAP_SYS_PTRACE / CAP_SYS_ADMIN capabilities with unconfined seccomp/AppArmor so BPF, perf events, ptrace, and the perf_uprobe PMU attachments used by `cpu-on` and `latency` are all permitted. CAP_SYS_ADMIN is the smallest addition that satisfies the uprobe perf_event check — `--privileged` is not required |
| service.annotations | object | `{}` | Service annotations |
| service.port | int | `8080` | Service port |
| service.type | string | `"ClusterIP"` | Service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount |
| serviceAccount.create | bool | `true` | Create a ServiceAccount for the collector |
| serviceAccount.name | string | `""` | Name of the ServiceAccount to use. Generated from the fullname when empty |
| tolerations | list | `[]` | Tolerations for the DaemonSet Pods (e.g. to also run on control-plane nodes) |
| updateStrategy | object | `{}` | Update strategy for the DaemonSet |
