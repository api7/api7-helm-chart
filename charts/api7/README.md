# api7ee3

![Version: 0.17.26](https://img.shields.io/badge/Version-0.17.26-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 3.8.14](https://img.shields.io/badge/AppVersion-3.8.14-informational?style=flat-square)

A Helm chart for Kubernetes

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| API7 | <support@api7.ai> | <https://api7.ai> |

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
| dashboard.extraVolumeMounts | list | `[]` |  |
| dashboard.extraVolumes | list | `[]` |  |
| dashboard.image.pullPolicy | string | `"Always"` |  |
| dashboard.image.repository | string | `"api7/api7-ee-3-integrated"` |  |
| dashboard.image.tag | string | `"v3.8.14"` |  |
| dashboard.keyCertSecret | string | `""` |  |
| dashboard.livenessProbe.failureThreshold | int | `30` |  |
| dashboard.livenessProbe.initialDelaySeconds | int | `180` |  |
| dashboard.livenessProbe.periodSeconds | int | `10` |  |
| dashboard.podLabels | object | `{}` |  |
| dashboard.readinessProbe.failureThreshold | int | `3` |  |
| dashboard.readinessProbe.initialDelaySeconds | int | `10` |  |
| dashboard.readinessProbe.periodSeconds | int | `3` |  |
| dashboard.replicaCount | int | `1` |  |
| dashboard_configuration.audit.retention_days | int | `60` |  |
| dashboard_configuration.console.addr | string | `"http://127.0.0.1:3000"` |  |
| dashboard_configuration.consumer_proxy.cache_failure_count | int | `512` |  |
| dashboard_configuration.consumer_proxy.cache_failure_ttl | int | `60` |  |
| dashboard_configuration.consumer_proxy.cache_success_count | int | `512` |  |
| dashboard_configuration.consumer_proxy.cache_success_ttl | int | `60` |  |
| dashboard_configuration.consumer_proxy.enable | bool | `false` |  |
| dashboard_configuration.database.dsn | string | `"postgres://api7ee:changeme@api7-postgresql:5432/api7ee"` |  |
| dashboard_configuration.database.max_idle_time | string | `"30s"` |  |
| dashboard_configuration.database.max_open_conns | int | `30` |  |
| dashboard_configuration.developer_proxy.cache_failure_count | int | `256` |  |
| dashboard_configuration.developer_proxy.cache_failure_ttl | int | `15` |  |
| dashboard_configuration.developer_proxy.cache_success_count | int | `256` |  |
| dashboard_configuration.developer_proxy.cache_success_ttl | int | `15` |  |
| dashboard_configuration.log.level | string | `"warn"` |  |
| dashboard_configuration.log.output | string | `"stderr"` |  |
| dashboard_configuration.prometheus.addr | string | `"http://api7-prometheus-server:9090"` |  |
| dashboard_configuration.prometheus.basic_auth.password | string | `""` |  |
| dashboard_configuration.prometheus.basic_auth.username | string | `""` |  |
| dashboard_configuration.prometheus.timeout | string | `"30s"` |  |
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
| dashboard_configuration.server.pprof.enable | bool | `false` |  |
| dashboard_configuration.server.pprof.host | string | `"127.0.0.1"` |  |
| dashboard_configuration.server.pprof.port | int | `7082` |  |
| dashboard_configuration.server.status.disable | bool | `false` |  |
| dashboard_configuration.server.status.host | string | `"127.0.0.1"` |  |
| dashboard_configuration.server.status.port | int | `7081` |  |
| dashboard_configuration.server.tls.cert_file | string | `""` |  |
| dashboard_configuration.server.tls.disable | bool | `false` |  |
| dashboard_configuration.server.tls.host | string | `"0.0.0.0"` |  |
| dashboard_configuration.server.tls.key_file | string | `""` |  |
| dashboard_configuration.server.tls.port | int | `7443` |  |
| dashboard_configuration.session_options_config.max_age | int | `86400` |  |
| dashboard_configuration.session_options_config.same_site | string | `"lax"` |  |
| dashboard_configuration.session_options_config.secure | bool | `false` |  |
| dashboard_service.annotations | object | `{}` |  |
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
| developer_portal.extraVolumeMounts | list | `[]` |  |
| developer_portal.extraVolumes | list | `[]` |  |
| developer_portal.image.pullPolicy | string | `"Always"` |  |
| developer_portal.image.repository | string | `"api7/api7-ee-developer-portal"` |  |
| developer_portal.image.tag | string | `"v3.8.14"` |  |
| developer_portal.keyCertSecret | string | `""` |  |
| developer_portal.livenessProbe.failureThreshold | int | `10` |  |
| developer_portal.livenessProbe.initialDelaySeconds | int | `60` |  |
| developer_portal.livenessProbe.periodSeconds | int | `3` |  |
| developer_portal.podLabels | object | `{}` |  |
| developer_portal.readinessProbe.failureThreshold | int | `3` |  |
| developer_portal.readinessProbe.initialDelaySeconds | int | `10` |  |
| developer_portal.readinessProbe.periodSeconds | int | `3` |  |
| developer_portal.replicaCount | int | `1` |  |
| developer_portal_configuration.database.dsn | string | `"postgres://api7ee:changeme@api7-postgresql:5432/api7ee"` |  |
| developer_portal_configuration.database.max_idle_time | string | `"30s"` |  |
| developer_portal_configuration.database.max_open_conns | int | `30` |  |
| developer_portal_configuration.enable | bool | `true` |  |
| developer_portal_configuration.log.level | string | `"warn"` |  |
| developer_portal_configuration.log.output | string | `"stderr"` |  |
| developer_portal_configuration.server.listen.host | string | `"0.0.0.0"` |  |
| developer_portal_configuration.server.listen.port | int | `4321` |  |
| developer_portal_configuration.server.listen.tls.cert_file | string | `""` |  |
| developer_portal_configuration.server.listen.tls.enabled | bool | `true` |  |
| developer_portal_configuration.server.listen.tls.key_file | string | `""` |  |
| developer_portal_configuration.server.status.disable | bool | `false` |  |
| developer_portal_configuration.server.status.host | string | `"127.0.0.1"` |  |
| developer_portal_configuration.server.status.port | int | `4322` |  |
| developer_portal_service.annotations | object | `{}` |  |
| developer_portal_service.ingress.annotations | object | `{}` |  |
| developer_portal_service.ingress.className | string | `""` |  |
| developer_portal_service.ingress.enabled | bool | `false` |  |
| developer_portal_service.ingress.hosts[0].host | string | `"developer-portal.local"` |  |
| developer_portal_service.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| developer_portal_service.ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| developer_portal_service.ingress.tls | list | `[]` |  |
| developer_portal_service.port | int | `4321` |  |
| developer_portal_service.type | string | `"ClusterIP"` |  |
| dp_manager.extraEnvVars | list | `[]` |  |
| dp_manager.extraVolumeMounts | list | `[]` |  |
| dp_manager.extraVolumes | list | `[]` |  |
| dp_manager.image.pullPolicy | string | `"Always"` |  |
| dp_manager.image.repository | string | `"api7/api7-ee-dp-manager"` |  |
| dp_manager.image.tag | string | `"v3.8.14"` |  |
| dp_manager.livenessProbe.failureThreshold | int | `10` |  |
| dp_manager.livenessProbe.initialDelaySeconds | int | `60` |  |
| dp_manager.livenessProbe.periodSeconds | int | `3` |  |
| dp_manager.podLabels | object | `{}` |  |
| dp_manager.readinessProbe.failureThreshold | int | `3` |  |
| dp_manager.readinessProbe.initialDelaySeconds | int | `10` |  |
| dp_manager.readinessProbe.periodSeconds | int | `3` |  |
| dp_manager.replicaCount | int | `1` |  |
| dp_manager_configuration.consumer_cache.evict_interval | string | `"5s"` |  |
| dp_manager_configuration.consumer_cache.max_ttl | string | `"2h"` |  |
| dp_manager_configuration.consumer_cache.size | int | `50000` |  |
| dp_manager_configuration.database.dsn | string | `"postgres://api7ee:changeme@api7-postgresql:5432/api7ee"` |  |
| dp_manager_configuration.database.max_idle_time | string | `"30s"` |  |
| dp_manager_configuration.database.max_open_conns | int | `30` |  |
| dp_manager_configuration.log.level | string | `"warn"` |  |
| dp_manager_configuration.log.output | string | `"stderr"` |  |
| dp_manager_configuration.prometheus.addr | string | `"http://api7-prometheus-server:9090"` |  |
| dp_manager_configuration.prometheus.basic_auth.password | string | `""` |  |
| dp_manager_configuration.prometheus.basic_auth.username | string | `""` |  |
| dp_manager_configuration.prometheus.remote_write_path | string | `"/api/v1/write"` |  |
| dp_manager_configuration.prometheus.timeout | string | `"30s"` |  |
| dp_manager_configuration.prometheus.tls.ca_file | string | `""` |  |
| dp_manager_configuration.prometheus.tls.cert_file | string | `""` |  |
| dp_manager_configuration.prometheus.tls.enable_client_cert | bool | `false` |  |
| dp_manager_configuration.prometheus.tls.insecure_skip_verify | bool | `false` |  |
| dp_manager_configuration.prometheus.tls.key_file | string | `""` |  |
| dp_manager_configuration.prometheus.tls.server_name | string | `""` |  |
| dp_manager_configuration.rate_limit.count | int | `1000` |  |
| dp_manager_configuration.rate_limit.enable | bool | `false` |  |
| dp_manager_configuration.rate_limit.time_window | int | `1` |  |
| dp_manager_configuration.server.listen.host | string | `"0.0.0.0"` |  |
| dp_manager_configuration.server.listen.port | int | `7900` |  |
| dp_manager_configuration.server.pprof.enable | bool | `false` |  |
| dp_manager_configuration.server.pprof.host | string | `"127.0.0.1"` |  |
| dp_manager_configuration.server.pprof.port | int | `7902` |  |
| dp_manager_configuration.server.status.disable | bool | `false` |  |
| dp_manager_configuration.server.status.host | string | `"127.0.0.1"` |  |
| dp_manager_configuration.server.status.port | int | `7901` |  |
| dp_manager_configuration.server.tls.host | string | `"0.0.0.0"` |  |
| dp_manager_configuration.server.tls.port | int | `7943` |  |
| dp_manager_service.annotations | object | `{}` |  |
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
| global.storageClass | string | `""` |  |
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
| postgresql.image.registry | string | `"docker.io"` |  |
| postgresql.image.repository | string | `"api7/postgresql"` |  |
| postgresql.image.tag | string | `"15.4.0-debian-11-r45"` |  |
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
| prometheus.server.image.registry | string | `"docker.io"` |  |
| prometheus.server.image.repository | string | `"api7/prometheus"` |  |
| prometheus.server.image.tag | string | `"2.48.1-debian-11-r0"` |  |
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

