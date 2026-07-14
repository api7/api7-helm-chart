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

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for the DaemonSet Pods |
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
| securityContext | object | `{"appArmorProfile":{"type":"Unconfined"},"capabilities":{"add":["BPF","PERFMON","SYS_PTRACE"]},"runAsUser":0,"seccompProfile":{"type":"Unconfined"}}` | Container security context. The defaults grant exactly what the eBPF collector needs: run as root, the CAP_BPF / CAP_PERFMON / CAP_SYS_PTRACE capabilities, and unconfined seccomp/AppArmor so BPF, perf events, and ptrace of target processes are permitted |
| service.annotations | object | `{}` | Service annotations |
| service.containerPort | int | `8080` | Container port the UI listens on |
| service.port | int | `8080` | Service port |
| service.type | string | `"ClusterIP"` | Service type. The debug UI is not a hardened multi-user service; keep it ClusterIP and reach a specific node's Pod with `kubectl port-forward` |
| serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount |
| serviceAccount.create | bool | `true` | Create a ServiceAccount for the collector |
| serviceAccount.name | string | `""` | Name of the ServiceAccount to use. Generated from the fullname when empty |
| tolerations | list | `[]` | Tolerations for the DaemonSet Pods (e.g. to also run on control-plane nodes) |
| updateStrategy | object | `{}` | Update strategy for the DaemonSet |

