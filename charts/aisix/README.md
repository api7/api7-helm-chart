# aisix

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

A Helm chart for AISIX AI Gateway

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| API7 | <support@api7.ai> | <https://api7.ai> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | etcd | 8.7.7 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| admin | object | `{"annotations":{},"containerPort":3001,"enabled":true,"ingress":{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"aisix-admin.local","paths":["/ui","/aisix/admin"]}],"tls":[]},"ip":"0.0.0.0","servicePort":3001,"type":"ClusterIP"}` | AISIX admin service settings (port 3001) — Admin API and UI |
| admin.containerPort | int | `3001` | Container port |
| admin.enabled | bool | `true` | Enable admin service |
| admin.ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"aisix-admin.local","paths":["/ui","/aisix/admin"]}],"tls":[]}` | Using ingress access AISIX admin service |
| admin.ingress.annotations | object | `{}` | Ingress annotations |
| admin.ingress.className | string | `""` | IngressClass that will be be used to implement the Ingress |
| admin.ip | string | `"0.0.0.0"` | which ip to listen on for the admin service |
| admin.servicePort | int | `3001` | Service port |
| admin.type | string | `"ClusterIP"` | admin service type |
| affinity | object | `{}` | Set affinity for deploy |
| autoscaling.enabled | bool | `false` |  |
| autoscaling.maxReplicas | int | `10` |  |
| autoscaling.minReplicas | int | `1` |  |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| autoscaling.targetMemoryUtilizationPercentage | int | `80` |  |
| deployment.admin.adminKey | string | `""` | Admin API key. Used to create an internal Secret when existingSecret is not set. Required when existingSecret is not set. |
| deployment.admin.existingSecret | string | `""` | Name of an existing Secret that contains an admin key field. If set, adminKey above is ignored and the key is read from the Secret. |
| deployment.admin.existingSecretKey | string | `"admin-key"` | Key inside the existing Secret that holds the admin key value |
| deployment.etcd.host | list | `["http://etcd.host:2379"]` | List of etcd hosts. Ignored when etcd.enabled is true (auto-constructed). |
| deployment.etcd.prefix | string | `"/aisix"` | Key prefix used by aisix in etcd |
| deployment.etcd.timeout | int | `30` | etcd request timeout in seconds |
| etcd | object | `{"auth":{"rbac":{"create":false,"rootPassword":""},"tls":{"certFilename":"","certKeyFilename":"","enabled":false,"existingSecret":"","sni":"","verify":false}},"enabled":false,"image":{"repository":"api7/etcd"},"replicaCount":3,"service":{"port":2379}}` | etcd subchart (bitnami/etcd) |
| etcd.auth.rbac.create | bool | `false` | No authentication by default. Enable RBAC (set create: true and configure rootPassword) for production or multi-tenant clusters to prevent unauthenticated etcd access. |
| etcd.auth.rbac.rootPassword | string | `""` | root password for etcd. Requires etcd.auth.rbac.create to be true. |
| etcd.auth.tls.certFilename | string | `""` | etcd client cert filename using in etcd.auth.tls.existingSecret |
| etcd.auth.tls.certKeyFilename | string | `""` | etcd client cert key filename using in etcd.auth.tls.existingSecret |
| etcd.auth.tls.enabled | bool | `false` | enable etcd client certificate |
| etcd.auth.tls.existingSecret | string | `""` | name of the secret contains etcd client cert |
| etcd.auth.tls.sni | string | `""` | specify the TLS Server Name Indication extension, the ETCD endpoint hostname will be used when this setting is unset. |
| etcd.auth.tls.verify | bool | `false` | whether to verify the etcd endpoint certificate when setup a TLS connection to etcd |
| etcd.enabled | bool | `false` | Install etcd as a subchart. Set false to use an external etcd. |
| extraEnvVars | list | `[]` | Additional environment variables |
| extraEnvVarsCM | string | `""` |  |
| extraEnvVarsSecret | string | `""` |  |
| extraInitContainers | list | `[]` | Additional init containers |
| extraVolumeMounts | list | `[]` | Additional volume mounts |
| extraVolumes | list | `[]` | Additional volumes |
| fullnameOverride | string | `""` |  |
| gateway | object | `{"annotations":{},"containerPort":3000,"externalIPs":[],"externalTrafficPolicy":"Cluster","ingress":{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"aisix.local","paths":["/"]}],"tls":[]},"ip":"0.0.0.0","nodePort":"","servicePort":3000,"type":"NodePort"}` | AISIX proxy service settings (port 3000) — user traffic |
| gateway.containerPort | int | `3000` | Container port |
| gateway.externalIPs | list | `[]` | IPs for which nodes in the cluster will also accept traffic for the service |
| gateway.externalTrafficPolicy | string | `"Cluster"` | Setting how the Service route external traffic |
| gateway.ingress | object | `{"annotations":{},"className":"","enabled":false,"hosts":[{"host":"aisix.local","paths":["/"]}],"tls":[]}` | Using ingress access AISIX proxy service |
| gateway.ingress.annotations | object | `{}` | Ingress annotations |
| gateway.ingress.className | string | `""` | IngressClass that will be be used to implement the Ingress |
| gateway.ip | string | `"0.0.0.0"` | which ip to listen on for the proxy service |
| gateway.nodePort | string | `""` | Optional static nodePort (only relevant when type is NodePort) |
| gateway.servicePort | int | `3000` | Service port |
| gateway.type | string | `"NodePort"` | proxy service type |
| global.imagePullSecrets | list | `[]` | Global Docker registry secret names as an array |
| image.pullPolicy | string | `"IfNotPresent"` | AISIX image pull policy |
| image.repository | string | `"ghcr.io/api7/aisix"` | AISIX image repository |
| image.tag | string | `"0.1.0"` | AISIX image tag; overrides the chart appVersion |
| livenessProbe | object | `{}` | Kubernetes liveness probe override |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` | Node labels for pod assignment |
| podAnnotations | object | `{}` | Annotations to add to the pod |
| podLabels | object | `{}` | Labels to add to the pod |
| podSecurityContext | object | `{}` | Set the securityContext for AISIX pods |
| readinessProbe | object | `{}` | Kubernetes readiness probe override |
| replicaCount | int | `1` | Number of AISIX replicas |
| resources | object | `{}` | Set pod resource requests & limits |
| securityContext | object | `{}` | Set the securityContext for AISIX container |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `false` | Specifies whether a service account should be created |
| serviceAccount.name | string | `""` | The name of the service account to use. |
| timezone | string | `""` | timezone for the container, e.g. "UTC" or "Asia/Shanghai" |
| tolerations | list | `[]` | List of node taints to tolerate |
| updateStrategy | object | `{}` |  |

