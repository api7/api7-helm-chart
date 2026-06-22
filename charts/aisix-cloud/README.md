# aisix-cloud

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

Helm chart for AISIX-Cloud control plane (cp-api, dp-manager, dashboard)

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| API7 | <support@api7.ai> | <https://api7.ai> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql | 12.12.10 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| api.affinity | object | `{}` |  |
| api.dpImage | string | `""` |  |
| api.dpmgrBaseURL | string | `""` |  |
| api.extraEnvVars | list | `[]` |  |
| api.image.pullPolicy | string | `"IfNotPresent"` |  |
| api.image.repository | string | `"ghcr.io/api7/aisix-cp-api"` |  |
| api.image.tag | string | `""` |  |
| api.nodeSelector | object | `{}` |  |
| api.oauthEnabled | bool | `false` |  |
| api.podSecurityContext.fsGroup | int | `101` |  |
| api.podSecurityContext.runAsGroup | int | `101` |  |
| api.podSecurityContext.runAsNonRoot | bool | `true` |  |
| api.podSecurityContext.runAsUser | int | `10001` |  |
| api.podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| api.publicBaseURL | string | `"http://localhost:8080"` |  |
| api.replicaCount | int | `1` |  |
| api.resources.limits.cpu | string | `"1"` |  |
| api.resources.limits.memory | string | `"512Mi"` |  |
| api.resources.requests.cpu | string | `"100m"` |  |
| api.resources.requests.memory | string | `"128Mi"` |  |
| api.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| api.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| api.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| api.service.port | int | `8080` |  |
| api.service.type | string | `"ClusterIP"` |  |
| api.tolerations | list | `[]` |  |
| dpm.affinity | object | `{}` |  |
| dpm.extraEnvVars | list | `[]` |  |
| dpm.image.pullPolicy | string | `"IfNotPresent"` |  |
| dpm.image.repository | string | `"ghcr.io/api7/aisix-cp-dpm"` |  |
| dpm.image.tag | string | `""` |  |
| dpm.nodeSelector | object | `{}` |  |
| dpm.podSecurityContext.fsGroup | int | `101` |  |
| dpm.podSecurityContext.runAsGroup | int | `101` |  |
| dpm.podSecurityContext.runAsNonRoot | bool | `true` |  |
| dpm.podSecurityContext.runAsUser | int | `10001` |  |
| dpm.podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| dpm.replicaCount | int | `1` |  |
| dpm.resources.limits.cpu | string | `"1"` |  |
| dpm.resources.limits.memory | string | `"512Mi"` |  |
| dpm.resources.requests.cpu | string | `"100m"` |  |
| dpm.resources.requests.memory | string | `"128Mi"` |  |
| dpm.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| dpm.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| dpm.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| dpm.service.nodePort | string | `""` |  |
| dpm.service.port | int | `7944` |  |
| dpm.service.type | string | `"ClusterIP"` |  |
| dpm.tolerations | list | `[]` |  |
| externalDatabase.database | string | `"aisix_cloud"` |  |
| externalDatabase.existingSecret | string | `""` |  |
| externalDatabase.host | string | `""` |  |
| externalDatabase.password | string | `""` |  |
| externalDatabase.port | int | `5432` |  |
| externalDatabase.sslmode | string | `"disable"` |  |
| externalDatabase.username | string | `"aisix"` |  |
| global.imagePullSecrets | list | `[]` |  |
| global.storageClass | string | `""` |  |
| postgresql.auth.database | string | `"aisix_cloud"` |  |
| postgresql.auth.existingSecret | string | `""` |  |
| postgresql.auth.password | string | `"changeme"` |  |
| postgresql.auth.postgresPassword | string | `"changeme"` |  |
| postgresql.auth.usePostgresUserForAppConnections | bool | `true` |  |
| postgresql.auth.username | string | `"aisix"` |  |
| postgresql.builtin | bool | `true` |  |
| postgresql.fullnameOverride | string | `""` |  |
| postgresql.image.registry | string | `"docker.io"` |  |
| postgresql.image.repository | string | `"api7/postgresql"` |  |
| postgresql.image.tag | string | `"15.4.0-debian-11-r45"` |  |
| postgresql.primary.persistence.size | string | `"8Gi"` |  |
| postgresql.primary.service.ports.postgresql | int | `5432` |  |
| secrets.betterAuthSecret | string | `"CHANGE_ME_GENERATE_WITH_openssl_rand_-base64_48"` |  |
| secrets.masterKey | string | `"CHANGE_ME_GENERATE_WITH_openssl_rand_-base64_32"` |  |
| secrets.masterKeyID | string | `"env:default"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| ui.affinity | object | `{}` |  |
| ui.defaultLocale | string | `"en"` |  |
| ui.extraEnvVars | list | `[]` |  |
| ui.image.pullPolicy | string | `"IfNotPresent"` |  |
| ui.image.repository | string | `"ghcr.io/api7/aisix-cp-ui"` |  |
| ui.image.tag | string | `""` |  |
| ui.nodeSelector | object | `{}` |  |
| ui.podSecurityContext.fsGroup | int | `65533` |  |
| ui.podSecurityContext.runAsGroup | int | `65533` |  |
| ui.podSecurityContext.runAsNonRoot | bool | `true` |  |
| ui.podSecurityContext.runAsUser | int | `1001` |  |
| ui.podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| ui.replicaCount | int | `1` |  |
| ui.resources.limits.cpu | string | `"500m"` |  |
| ui.resources.limits.memory | string | `"256Mi"` |  |
| ui.resources.requests.cpu | string | `"50m"` |  |
| ui.resources.requests.memory | string | `"64Mi"` |  |
| ui.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| ui.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| ui.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| ui.service.port | int | `3000` |  |
| ui.service.type | string | `"ClusterIP"` |  |
| ui.tolerations | list | `[]` |  |

