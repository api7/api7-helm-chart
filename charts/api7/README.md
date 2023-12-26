# api7ee3

![Version: 0.3.0](https://img.shields.io/badge/Version-0.3.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 3.0.0](https://img.shields.io/badge/AppVersion-3.0.0-informational?style=flat-square)

A Helm chart for Kubernetes

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql | 12.12.10 |
| https://charts.bitnami.com/bitnami | prometheus | 0.1.4 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| busybox.image.repository | string | `"docker.io/busybox"` |  |
| busybox.image.tag | float | `1.28` |  |
| dashboard.image.pullPolicy | string | `"IfNotPresent"` |  |
| dashboard.image.repository | string | `"api7/api7-ee-3-integrated"` |  |
| dashboard.image.tag | string | `"v3.2.6.0"` |  |
| dashboard.replicaCount | int | `1` |  |
| dashboard_configuration.authentication_config.session_secret | string | `"changeme"` |  |
| dashboard_configuration.console.addr | string | `"http://127.0.0.1:3000"` |  |
| dashboard_configuration.database.postgres.addr | string | `"api7ee3-postgresql:5432"` |  |
| dashboard_configuration.database.postgres.database | string | `"api7ee"` |  |
| dashboard_configuration.database.postgres.password | string | `"changeme"` |  |
| dashboard_configuration.database.postgres.user | string | `"api7ee"` |  |
| dashboard_configuration.database.type | string | `"postgres"` |  |
| dashboard_configuration.log.level | string | `"info"` |  |
| dashboard_configuration.log.output | string | `"stderr"` |  |
| dashboard_configuration.login.source | string | `"DB"` |  |
| dashboard_configuration.oauth2_config.callback_url | string | `""` |  |
| dashboard_configuration.oauth2_config.client_id | string | `"5778c01f-2236-4261-92e9-a7ca4eb180b7"` |  |
| dashboard_configuration.oauth2_config.client_secret | string | `"f840329b-1653-4336-a95a-d0cc5aa54a91"` |  |
| dashboard_configuration.oauth2_config.issuer | string | `"http://api7ee3-keycloak/realms/master"` |  |
| dashboard_configuration.oauth2_config.redirect_url | string | `""` |  |
| dashboard_configuration.prometheus.addr | string | `"http://api7ee3-prometheus-server:9090"` |  |
| dashboard_configuration.prometheus.whitelist[0] | string | `"/api/v1/query_range"` |  |
| dashboard_configuration.prometheus.whitelist[1] | string | `"/api/v1/query"` |  |
| dashboard_configuration.prometheus.whitelist[2] | string | `"/api/v1/format_query"` |  |
| dashboard_configuration.prometheus.whitelist[3] | string | `"/api/v1/series"` |  |
| dashboard_configuration.prometheus.whitelist[4] | string | `"/api/v1/labels"` |  |
| dashboard_configuration.server.cors.access_control_allow_credentials | string | `"false"` |  |
| dashboard_configuration.server.cors.access_control_allow_headers | string | `"*"` |  |
| dashboard_configuration.server.cors.access_control_allow_methods | string | `"*"` |  |
| dashboard_configuration.server.cors.access_control_allow_origin | string | `"*"` |  |
| dashboard_configuration.server.cors.enabled | bool | `false` |  |
| dashboard_configuration.server.listen.host | string | `"0.0.0.0"` |  |
| dashboard_configuration.server.listen.port | int | `7080` |  |
| dashboard_configuration.session_options_config.same_site | string | `"lax"` |  |
| dashboard_configuration.session_options_config.secure | bool | `false` |  |
| dashboard_configuration.user_manager.logout_url | string | `"https://login.api7.ai/v2/logout"` |  |
| dashboard_configuration.user_manager.oidc_provider | string | `"keycloak"` |  |
| dashboard_service.port | int | `7080` |  |
| dashboard_service.type | string | `"ClusterIP"` |  |
| dp_manager.image.pullPolicy | string | `"IfNotPresent"` |  |
| dp_manager.image.repository | string | `"api7/api7-ee-dp-manager"` |  |
| dp_manager.image.tag | string | `"v3.2.6.0"` |  |
| dp_manager.replicaCount | int | `1` |  |
| dp_manager_configuration.database.postgres.addr | string | `"api7ee3-postgresql:5432"` |  |
| dp_manager_configuration.database.postgres.database | string | `"api7ee"` |  |
| dp_manager_configuration.database.postgres.password | string | `"changeme"` |  |
| dp_manager_configuration.database.postgres.user | string | `"api7ee"` |  |
| dp_manager_configuration.database.type | string | `"postgres"` |  |
| dp_manager_configuration.log.level | string | `"info"` |  |
| dp_manager_configuration.log.output | string | `"stderr"` |  |
| dp_manager_configuration.prometheus.addr | string | `"http://api7ee3-prometheus-server:9090"` |  |
| dp_manager_configuration.server.listen.host | string | `"0.0.0.0"` |  |
| dp_manager_configuration.server.listen.port | int | `7900` |  |
| dp_manager_configuration.server.status_listen.host | string | `"0.0.0.0"` |  |
| dp_manager_configuration.server.status_listen.port | int | `7901` |  |
| dp_manager_service.port | int | `7900` |  |
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
| postgresql.host | string | `"api7ee3-postgresql"` |  |
| postgresql.port | int | `5432` |  |
| prometheus.alertmanager.enabled | bool | `false` |  |
| prometheus.builtin | bool | `true` |  |
| prometheus.server.enableAdminAPI | bool | `true` |  |
| prometheus.server.enableRemoteWriteReceiver | bool | `true` |  |
| prometheus.server.service.ports.http | int | `9090` |  |
| prometheus.server.service.type | string | `"ClusterIP"` |  |
| resources | object | `{}` |  |
| securityContext | object | `{}` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |

