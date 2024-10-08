# api7ee3

![Version: 0.16.15](https://img.shields.io/badge/Version-0.16.15-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 3.2.16](https://img.shields.io/badge/AppVersion-3.2.16-informational?style=flat-square)

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
| dashboard.extraVolumeMounts | list | `[]` |  |
| dashboard.extraVolumes | list | `[]` |  |
| dashboard.image.pullPolicy | string | `"Always"` |  |
| dashboard.image.repository | string | `"api7/api7-ee-3-integrated"` |  |
| dashboard.image.tag | string | `"v3.2.16.1"` |  |
| dashboard.keyCertSecret | string | `""` |  |
| dashboard.replicaCount | int | `1` |  |
| dashboard_configuration.console.addr | string | `"http://127.0.0.1:3000"` |  |
| dashboard_configuration.database.dsn | string | `"postgres://api7ee:changeme@api7-postgresql:5432/api7ee"` |  |
| dashboard_configuration.database.max_idle_conns | int | `2` |  |
| dashboard_configuration.database.max_open_conns | int | `30` |  |
| dashboard_configuration.log.level | string | `"warn"` |  |
| dashboard_configuration.log.output | string | `"stderr"` |  |
| dashboard_configuration.plugins[0] | string | `"real-ip"` |  |
| dashboard_configuration.plugins[10] | string | `"referer-restriction"` |  |
| dashboard_configuration.plugins[11] | string | `"uri-blocker"` |  |
| dashboard_configuration.plugins[12] | string | `"request-validation"` |  |
| dashboard_configuration.plugins[13] | string | `"authz-casbin"` |  |
| dashboard_configuration.plugins[14] | string | `"authz-casdoor"` |  |
| dashboard_configuration.plugins[15] | string | `"wolf-rbac"` |  |
| dashboard_configuration.plugins[16] | string | `"multi-auth"` |  |
| dashboard_configuration.plugins[17] | string | `"ldap-auth"` |  |
| dashboard_configuration.plugins[18] | string | `"forward-auth"` |  |
| dashboard_configuration.plugins[19] | string | `"saml-auth"` |  |
| dashboard_configuration.plugins[1] | string | `"error-page"` |  |
| dashboard_configuration.plugins[20] | string | `"opa"` |  |
| dashboard_configuration.plugins[21] | string | `"authz-keycloak"` |  |
| dashboard_configuration.plugins[22] | string | `"proxy-mirror"` |  |
| dashboard_configuration.plugins[23] | string | `"proxy-cache"` |  |
| dashboard_configuration.plugins[24] | string | `"api-breaker"` |  |
| dashboard_configuration.plugins[25] | string | `"limit-req"` |  |
| dashboard_configuration.plugins[26] | string | `"gzip"` |  |
| dashboard_configuration.plugins[27] | string | `"kafka-proxy"` |  |
| dashboard_configuration.plugins[28] | string | `"grpc-transcode"` |  |
| dashboard_configuration.plugins[29] | string | `"grpc-web"` |  |
| dashboard_configuration.plugins[2] | string | `"client-control"` |  |
| dashboard_configuration.plugins[30] | string | `"public-api"` |  |
| dashboard_configuration.plugins[31] | string | `"data-mask"` |  |
| dashboard_configuration.plugins[32] | string | `"opentelemetry"` |  |
| dashboard_configuration.plugins[33] | string | `"datadog"` |  |
| dashboard_configuration.plugins[34] | string | `"echo"` |  |
| dashboard_configuration.plugins[35] | string | `"loggly"` |  |
| dashboard_configuration.plugins[36] | string | `"splunk-hec-logging"` |  |
| dashboard_configuration.plugins[37] | string | `"skywalking-logger"` |  |
| dashboard_configuration.plugins[38] | string | `"google-cloud-logging"` |  |
| dashboard_configuration.plugins[39] | string | `"sls-logger"` |  |
| dashboard_configuration.plugins[3] | string | `"proxy-control"` |  |
| dashboard_configuration.plugins[40] | string | `"tcp-logger"` |  |
| dashboard_configuration.plugins[41] | string | `"rocketmq-logger"` |  |
| dashboard_configuration.plugins[42] | string | `"udp-logger"` |  |
| dashboard_configuration.plugins[43] | string | `"file-logger"` |  |
| dashboard_configuration.plugins[44] | string | `"clickhouse-logger"` |  |
| dashboard_configuration.plugins[45] | string | `"ext-plugin-post-resp"` |  |
| dashboard_configuration.plugins[46] | string | `"serverless-post-function"` |  |
| dashboard_configuration.plugins[47] | string | `"azure-functions"` |  |
| dashboard_configuration.plugins[48] | string | `"aws-lambda"` |  |
| dashboard_configuration.plugins[49] | string | `"openwhisk"` |  |
| dashboard_configuration.plugins[4] | string | `"zipkin"` |  |
| dashboard_configuration.plugins[50] | string | `"consumer-restriction"` |  |
| dashboard_configuration.plugins[51] | string | `"attach-consumer-label"` |  |
| dashboard_configuration.plugins[52] | string | `"acl"` |  |
| dashboard_configuration.plugins[53] | string | `"basic-auth"` |  |
| dashboard_configuration.plugins[54] | string | `"cors"` |  |
| dashboard_configuration.plugins[55] | string | `"csrf"` |  |
| dashboard_configuration.plugins[56] | string | `"fault-injection"` |  |
| dashboard_configuration.plugins[57] | string | `"hmac-auth"` |  |
| dashboard_configuration.plugins[58] | string | `"jwt-auth"` |  |
| dashboard_configuration.plugins[59] | string | `"key-auth"` |  |
| dashboard_configuration.plugins[5] | string | `"ext-plugin-pre-req"` |  |
| dashboard_configuration.plugins[60] | string | `"openid-connect"` |  |
| dashboard_configuration.plugins[61] | string | `"limit-count"` |  |
| dashboard_configuration.plugins[62] | string | `"redirect"` |  |
| dashboard_configuration.plugins[63] | string | `"request-id"` |  |
| dashboard_configuration.plugins[64] | string | `"proxy-rewrite"` |  |
| dashboard_configuration.plugins[65] | string | `"response-rewrite"` |  |
| dashboard_configuration.plugins[66] | string | `"workflow"` |  |
| dashboard_configuration.plugins[67] | string | `"proxy-buffering"` |  |
| dashboard_configuration.plugins[68] | string | `"tencent-cloud-cls"` |  |
| dashboard_configuration.plugins[69] | string | `"openfunction"` |  |
| dashboard_configuration.plugins[6] | string | `"mocking"` |  |
| dashboard_configuration.plugins[70] | string | `"graphql-proxy-cache"` |  |
| dashboard_configuration.plugins[71] | string | `"ext-plugin-post-req"` |  |
| dashboard_configuration.plugins[72] | string | `"graphql-limit-count"` |  |
| dashboard_configuration.plugins[73] | string | `"elasticsearch-logger"` |  |
| dashboard_configuration.plugins[74] | string | `"kafka-logger"` |  |
| dashboard_configuration.plugins[75] | string | `"body-transformer"` |  |
| dashboard_configuration.plugins[76] | string | `"traffic-split"` |  |
| dashboard_configuration.plugins[77] | string | `"degraphql"` |  |
| dashboard_configuration.plugins[78] | string | `"http-logger"` |  |
| dashboard_configuration.plugins[79] | string | `"cas-auth"` |  |
| dashboard_configuration.plugins[7] | string | `"serverless-pre-function"` |  |
| dashboard_configuration.plugins[80] | string | `"traffic-label"` |  |
| dashboard_configuration.plugins[81] | string | `"oas-validator"` |  |
| dashboard_configuration.plugins[82] | string | `"api7-traffic-split"` |  |
| dashboard_configuration.plugins[83] | string | `"limit-conn"` |  |
| dashboard_configuration.plugins[84] | string | `"prometheus"` |  |
| dashboard_configuration.plugins[85] | string | `"syslog"` |  |
| dashboard_configuration.plugins[86] | string | `"ip-restriction"` |  |
| dashboard_configuration.plugins[87] | string | `"mqtt-proxy"` |  |
| dashboard_configuration.plugins[88] | string | `"ai-proxy"` |  |
| dashboard_configuration.plugins[89] | string | `"ai-prompt-template"` |  |
| dashboard_configuration.plugins[8] | string | `"batch-requests"` |  |
| dashboard_configuration.plugins[90] | string | `"ai-prompt-decorator"` |  |
| dashboard_configuration.plugins[9] | string | `"ua-restriction"` |  |
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
| developer_portal.image.pullPolicy | string | `"IfNotPresent"` |  |
| developer_portal.image.repository | string | `"api7/api7-developer-portal"` |  |
| developer_portal.image.tag | string | `"v0.1.2"` |  |
| developer_portal.keyCertSecret | string | `""` |  |
| developer_portal.replicaCount | int | `1` |  |
| developer_portal_configuration.enable | bool | `true` |  |
| developer_portal_configuration.server.listen.host | string | `"0.0.0.0"` |  |
| developer_portal_configuration.server.listen.port | int | `4321` |  |
| developer_portal_configuration.server.listen.tls.enabled | bool | `true` |  |
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
| dp_manager.image.tag | string | `"v3.2.16.1"` |  |
| dp_manager.replicaCount | int | `1` |  |
| dp_manager_configuration.database.dsn | string | `"postgres://api7ee:changeme@api7-postgresql:5432/api7ee"` |  |
| dp_manager_configuration.database.max_idle_conns | int | `2` |  |
| dp_manager_configuration.database.max_open_conns | int | `30` |  |
| dp_manager_configuration.log.level | string | `"warn"` |  |
| dp_manager_configuration.log.output | string | `"stderr"` |  |
| dp_manager_configuration.prometheus.addr | string | `"http://api7-prometheus-server:9090"` |  |
| dp_manager_configuration.prometheus.basic_auth.password | string | `""` |  |
| dp_manager_configuration.prometheus.basic_auth.username | string | `""` |  |
| dp_manager_configuration.prometheus.timeout | string | `"30s"` |  |
| dp_manager_configuration.prometheus.tls.ca_file | string | `""` |  |
| dp_manager_configuration.prometheus.tls.cert_file | string | `""` |  |
| dp_manager_configuration.prometheus.tls.enable_client_cert | bool | `false` |  |
| dp_manager_configuration.prometheus.tls.insecure_skip_verify | bool | `false` |  |
| dp_manager_configuration.prometheus.tls.key_file | string | `""` |  |
| dp_manager_configuration.prometheus.tls.server_name | string | `""` |  |
| dp_manager_configuration.server.listen.host | string | `"0.0.0.0"` |  |
| dp_manager_configuration.server.listen.port | int | `7900` |  |
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

