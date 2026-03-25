# developer-portal-fe

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.5.7](https://img.shields.io/badge/AppVersion-0.5.7-informational?style=flat-square)

A Helm chart for API7 Developer Portal Frontend

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
| affinity | object | `{}` |  |
| app.baseURL | string | `"http://localhost"` |  |
| app.trustedOrigins[0] | string | `"http://localhost"` |  |
| auth.existingSecret | string | `""` |  |
| auth.existingSecretKey | string | `"auth-secret"` |  |
| auth.secret | string | `""` |  |
| db.existingSecret | string | `""` |  |
| db.existingSecretKey | string | `"db-url"` |  |
| db.url | string | `"postgres://portal:portal123@developer-portal-fe-postgresql:5432/portal"` |  |
| developerPortal.extraEnvVars | list | `[]` |  |
| developerPortal.extraVolumeMounts | list | `[]` |  |
| developerPortal.extraVolumes | list | `[]` |  |
| developerPortal.image.pullPolicy | string | `"IfNotPresent"` |  |
| developerPortal.image.repository | string | `"api7/api7-ee-developer-portal-fe"` |  |
| developerPortal.image.tag | string | `"v0.5.7"` |  |
| developerPortal.livenessProbe.failureThreshold | int | `10` |  |
| developerPortal.livenessProbe.initialDelaySeconds | int | `30` |  |
| developerPortal.livenessProbe.path | string | `"/"` |  |
| developerPortal.livenessProbe.periodSeconds | int | `10` |  |
| developerPortal.podAnnotations | object | `{}` |  |
| developerPortal.podLabels | object | `{}` |  |
| developerPortal.readinessProbe.failureThreshold | int | `3` |  |
| developerPortal.readinessProbe.initialDelaySeconds | int | `10` |  |
| developerPortal.readinessProbe.path | string | `"/"` |  |
| developerPortal.readinessProbe.periodSeconds | int | `5` |  |
| developerPortal.replicaCount | int | `1` |  |
| developerPortal.resources | object | `{}` |  |
| developerPortal.tlsRejectUnauthorized | bool | `true` |  |
| developerPortal.topologySpreadConstraints | list | `[]` |  |
| fullnameOverride | string | `""` |  |
| imagePullSecret | string | `""` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `""` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"developer-portal.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| portal.existingSecret | string | `""` |  |
| portal.existingSecretKey | string | `"portal-token"` |  |
| portal.token | string | `""` |  |
| portal.url | string | `"https://api7-developer-portal:4321"` |  |
| postgresql.auth.database | string | `"portal"` |  |
| postgresql.auth.password | string | `"portal123"` |  |
| postgresql.auth.username | string | `"portal"` |  |
| postgresql.builtin | bool | `true` |  |
| postgresql.fullnameOverride | string | `"developer-portal-fe-postgresql"` |  |
| postgresql.primary.persistence.enabled | bool | `true` |  |
| postgresql.primary.persistence.size | string | `"10Gi"` |  |
| postgresql.primary.service.ports.postgresql | int | `5432` |  |
| resources | object | `{}` |  |
| securityContext | object | `{}` |  |
| service.annotations | object | `{}` |  |
| service.containerPort | int | `3001` |  |
| service.port | int | `80` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |
| topologySpreadConstraints | list | `[]` |  |

