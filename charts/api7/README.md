# api7ee3

![Version: 0.14.0](https://img.shields.io/badge/Version-0.14.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 3.0.0](https://img.shields.io/badge/AppVersion-3.0.0-informational?style=flat-square)

A Helm chart for Kubernetes

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql | 12.12.10 |
| https://charts.bitnami.com/bitnami | prometheus | 0.5.1 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| busybox.image.repository | string | `"docker.io/busybox"` |  |
| busybox.image.tag | float | `1.28` |  |
| dashboard.extraEnvVars | list | `[]` |  |
| dashboard.image.pullPolicy | string | `"Always"` |  |
| dashboard.image.repository | string | `"api7/api7-ee-3-integrated"` |  |
| dashboard.image.tag | string | `"v3.2.13.0"` |  |
| dashboard.keyCertSecret | string | `""` |  |
| dashboard.replicaCount | int | `1` |  |
| dashboard_configuration.console.addr | string | `"http://127.0.0.1:3000"` |  |
| dashboard_configuration.database.dsn | string | `"postgres://api7ee:changeme@api7-postgresql:5432/api7ee"` |  |
| dashboard_configuration.log.level | string | `"warn"` |  |
| dashboard_configuration.log.output | string | `"stderr"` |  |
| dashboard_configuration.login.source | string | `"DB"` |  |
| dashboard_configuration.prometheus.addr | string | `"http://api7-prometheus-server:9090"` |  |
| dashboard_configuration.prometheus.basic_auth.password | string | `""` |  |
| dashboard_configuration.prometheus.basic_auth.username | string | `""` |  |
| dashboard_configuration.prometheus.tls.ca_file | string | `""` |  |
| dashboard_configuration.prometheus.tls.cert_file | string | `""` |  |
| dashboard_configuration.prometheus.tls.enable_client_cert | bool | `false` |  |
| dashboard_configuration.prometheus.tls.insecure_skip_verify | bool | `false` |  |
| dashboard_configuration.prometheus.tls.key_file | string | `""` |  |
| dashboard_configuration.prometheus.tls.server_name | string | `""` |  |
| dashboard_configuration.prometheus.whitelist[0] | string | `"/api/v1/query_range"` |  |
| dashboard_configuration.prometheus.whitelist[1] | string | `"/api/v1/query"` |  |
| dashboard_configuration.prometheus.whitelist[2] | string | `"/api/v1/format_query"` |  |
| dashboard_configuration.prometheus.whitelist[3] | string | `"/api/v1/series"` |  |
| dashboard_configuration.prometheus.whitelist[4] | string | `"/api/v1/labels"` |  |
| dashboard_configuration.server.listen.disable | bool | `true` |  |
| dashboard_configuration.server.listen.host | string | `"0.0.0.0"` |  |
| dashboard_configuration.server.listen.port | int | `7080` |  |
| dashboard_configuration.server.tls.cert_file | string | `""` |  |
| dashboard_configuration.server.tls.disable | bool | `false` |  |
| dashboard_configuration.server.tls.host | string | `"0.0.0.0"` |  |
| dashboard_configuration.server.tls.key_file | string | `""` |  |
| dashboard_configuration.server.tls.port | int | `7443` |  |
| dashboard_configuration.session_options_config.same_site | string | `"lax"` |  |
| dashboard_configuration.session_options_config.secure | bool | `false` |  |
| dashboard_service.ingress.annotations | object | `{}` |  |
| dashboard_service.ingress.className | string | `""` |  |
| dashboard_service.ingress.enabled | bool | `false` |  |
| dashboard_service.ingress.hosts[0].host | string | `"dashboard.local"` |  |
| dashboard_service.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| dashboard_service.ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| dashboard_service.ingress.tls | list | `[]` |  |
| dashboard_service.port | int | `7080` |  |
| dashboard_service.tlsPort | int | `7443` |  |
| dashboard_service.type | string | `"ClusterIP"` |  |
| developer_portal.extraEnvVars | list | `[]` |  |
| developer_portal.image.pullPolicy | string | `"IfNotPresent"` |  |
| developer_portal.image.repository | string | `"api7/api7-developer-portal"` |  |
| developer_portal.image.tag | string | `"v0.0.3"` |  |
| developer_portal.replicaCount | int | `1` |  |
| developer_portal_configuration.enable | bool | `true` |  |
| developer_portal_configuration.server.listen.host | string | `"0.0.0.0"` |  |
| developer_portal_configuration.server.listen.port | int | `4321` |  |
| developer_portal_service.port | int | `4321` |  |
| developer_portal_service.type | string | `"ClusterIP"` |  |
| dp_manager.extraEnvVars | list | `[]` |  |
| dp_manager.image.pullPolicy | string | `"Always"` |  |
| dp_manager.image.repository | string | `"api7/api7-ee-dp-manager"` |  |
| dp_manager.image.tag | string | `"v3.2.13.0"` |  |
| dp_manager.replicaCount | int | `1` |  |
| dp_manager_configuration.database.dsn | string | `"postgres://api7ee:changeme@api7-postgresql:5432/api7ee"` |  |
| dp_manager_configuration.log.level | string | `"warn"` |  |
| dp_manager_configuration.log.output | string | `"stderr"` |  |
| dp_manager_configuration.prometheus.addr | string | `"http://api7-prometheus-server:9090"` |  |
| dp_manager_configuration.prometheus.basic_auth.password | string | `""` |  |
| dp_manager_configuration.prometheus.basic_auth.username | string | `""` |  |
| dp_manager_configuration.prometheus.tls.ca_file | string | `""` |  |
| dp_manager_configuration.prometheus.tls.cert_file | string | `""` |  |
| dp_manager_configuration.prometheus.tls.enable_client_cert | bool | `false` |  |
| dp_manager_configuration.prometheus.tls.insecure_skip_verify | bool | `false` |  |
| dp_manager_configuration.prometheus.tls.key_file | string | `""` |  |
| dp_manager_configuration.prometheus.tls.server_name | string | `""` |  |
| dp_manager_configuration.server.listen.host | string | `"0.0.0.0"` |  |
| dp_manager_configuration.server.listen.port | int | `7900` |  |
| dp_manager_configuration.server.tls.host | string | `"0.0.0.0"` |  |
| dp_manager_configuration.server.tls.port | int | `7943` |  |
| dp_manager_service.ingress.annotations | object | `{}` |  |
| dp_manager_service.ingress.className | string | `""` |  |
| dp_manager_service.ingress.enabled | bool | `false` |  |
| dp_manager_service.ingress.hosts[0].host | string | `"dp-manager.local"` |  |
| dp_manager_service.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| dp_manager_service.ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| dp_manager_service.ingress.tls | list | `[]` |  |
| dp_manager_service.port | int | `7900` |  |
| dp_manager_service.tlsPort | int | `7943` |  |
| dp_manager_service.type | string | `"ClusterIP"` |  |
| fullnameOverride | string | `""` |  |
| imagePullSecret | string | `""` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| postgresql.auth.database | string | `"api7ee"` |  |
| postgresql.auth.password | string | `"changeme"` |  |
| postgresql.auth.username | string | `"api7ee"` |  |
| postgresql.builtin | bool | `true` |  |
| postgresql.fullnameOverride | string | `"api7-postgresql"` |  |
| postgresql.primary.persistence.size | string | `"256Gi"` |  |
| postgresql.primary.service.ports.postgresql | int | `5432` |  |
| postgresql.readReplicas.persistence.size | string | `"256Gi"` |  |
| postgresql.readReplicas.service.ports.postgresql | int | `5432` |  |
| prometheus.alertmanager.enabled | bool | `false` |  |
| prometheus.builtin | bool | `true` |  |
| prometheus.fullnameOverride | string | `"api7-prometheus"` |  |
| prometheus.server.configuration | string | `""` |  |
| prometheus.server.enableAdminAPI | bool | `true` |  |
| prometheus.server.enableRemoteWriteReceiver | bool | `true` |  |
| prometheus.server.existingSecret | string | `""` |  |
| prometheus.server.persistence.enabled | bool | `true` |  |
| prometheus.server.persistence.size | string | `"120Gi"` |  |
| prometheus.server.rbac.create | bool | `false` |  |
| prometheus.server.service.ports.http | int | `9090` |  |
| prometheus.server.service.type | string | `"ClusterIP"` |  |
| prometheus.server.serviceAccount.create | bool | `false` |  |
| resources | object | `{}` |  |
| securityContext | object | `{}` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |

