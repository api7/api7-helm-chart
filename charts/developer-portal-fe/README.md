# API7 Developer Portal Frontend Helm Chart

This Helm chart deploys the API7 Developer Portal Frontend, a Next.js application that provides a user-facing interface for the API7 Developer Portal.

## Introduction

The API7 Developer Portal consists of two main components:

- **Portal API (Backend)**: Already deployed as part of the `api7` umbrella chart, listening on port 4321
- **Developer Portal FE (Frontend)**: This chart, a Next.js application listening on port 3001

This chart creates an independent deployment for the Developer Portal Frontend with its own PostgreSQL database for user authentication and management.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure (if using built-in PostgreSQL with persistence)

## Installing the Chart

To install the chart with the release name `my-dev-portal`:

```bash
helm install my-dev-portal ./charts/developer-portal-fe
```

The command deploys the Developer Portal Frontend on the Kubernetes cluster with the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `my-dev-portal` deployment:

```bash
helm uninstall my-dev-portal
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Parameters

### Application Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `developerPortal.replicaCount` | Number of replicas | `1` |
| `developerPortal.image.repository` | Image repository | `api7/api7-ee-developer-portal-fe` |
| `developerPortal.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `developerPortal.image.tag` | Image tag | `v0.5.7` |
| `developerPortal.resources` | Resource limits and requests | `{}` |
| `developerPortal.extraEnvVars` | Extra environment variables | `[]` |
| `developerPortal.extraVolumes` | Extra volumes | `[]` |
| `developerPortal.extraVolumeMounts` | Extra volume mounts | `[]` |
| `developerPortal.podLabels` | Additional labels for pods | `{}` |
| `developerPortal.podAnnotations` | Additional annotations for pods | `{}` |
| `developerPortal.topologySpreadConstraints` | Topology spread constraints | `[]` |
| `developerPortal.tlsRejectUnauthorized` | Enable TLS verification (set to false for self-signed certs) | `true` |
| `developerPortal.livenessProbe.initialDelaySeconds` | Liveness probe initial delay | `30` |
| `developerPortal.livenessProbe.periodSeconds` | Liveness probe period | `10` |
| `developerPortal.livenessProbe.failureThreshold` | Liveness probe failure threshold | `10` |
| `developerPortal.readinessProbe.initialDelaySeconds` | Readiness probe initial delay | `10` |
| `developerPortal.readinessProbe.periodSeconds` | Readiness probe period | `5` |
| `developerPortal.readinessProbe.failureThreshold` | Readiness probe failure threshold | `3` |

### Portal API Connection

| Parameter | Description | Default |
|-----------|-------------|---------|
| `portal.url` | Portal API endpoint | `https://api7-developer-portal:4321` |
| `portal.token` | Portal token (plain text) | `""` |
| `portal.existingSecret` | Reference to existing secret containing portal token | `""` |
| `portal.existingSecretKey` | Key in existing secret for portal token | `portal-token` |

### Database Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `db.url` | PostgreSQL connection string | `postgres://portal:portal123@developer-portal-fe-postgresql:5432/portal` |
| `db.existingSecret` | Reference to existing secret containing database URL | `""` |
| `db.existingSecretKey` | Key in existing secret for database URL | `db-url` |

### Authentication Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `auth.secret` | Better Auth secret key (at least 32 characters) | `""` |
| `auth.existingSecret` | Reference to existing secret containing auth secret | `""` |
| `auth.existingSecretKey` | Key in existing secret for auth secret | `auth-secret` |

### Application URL Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `app.baseURL` | Base URL for the application | `http://localhost` |
| `app.trustedOrigins` | Trusted origins for CORS | `["http://localhost"]` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.containerPort` | Container port | `3001` |
| `service.annotations` | Service annotations | `{}` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.hosts` | Ingress hosts configuration | See values.yaml |
| `ingress.tls` | TLS configuration | `[]` |

### PostgreSQL Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.builtin` | Enable built-in PostgreSQL | `true` |
| `postgresql.fullnameOverride` | Override PostgreSQL full name | `developer-portal-fe-postgresql` |
| `postgresql.image.registry` | PostgreSQL image registry | `docker.io` |
| `postgresql.image.repository` | PostgreSQL image repository | `postgres` |
| `postgresql.image.tag` | PostgreSQL image tag | `16` |
| `postgresql.auth.username` | PostgreSQL username | `portal` |
| `postgresql.auth.password` | PostgreSQL password | `portal123` |
| `postgresql.auth.database` | PostgreSQL database | `portal` |
| `postgresql.primary.persistence.size` | PostgreSQL persistence size | `10Gi` |

### Common Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `imagePullSecret` | Image pull secret name | `""` |
| `nameOverride` | Override the name of the chart | `""` |
| `fullnameOverride` | Override the full name of the release | `""` |
| `serviceAccount.create` | Create a service account | `true` |
| `serviceAccount.annotations` | Service account annotations | `{}` |
| `serviceAccount.name` | Service account name | `""` |
| `podAnnotations` | Pod annotations | `{}` |
| `podSecurityContext` | Pod security context | `{}` |
| `securityContext` | Container security context | `{}` |
| `nodeSelector` | Node selector | `{}` |
| `tolerations` | Tolerations | `[]` |
| `affinity` | Affinity | `{}` |
| `topologySpreadConstraints` | Topology spread constraints | `[]` |
| `resources` | Global resource limits and requests | `{}` |

## Configuration Examples

### Using External PostgreSQL

To use an external PostgreSQL database:

```yaml
postgresql:
  builtin: false

db:
  url: "postgres://username:password@external-postgres-host:5432/portal_db"
```

### Using Existing Secrets

For production deployments, it's recommended to use existing secrets:

```yaml
portal:
  existingSecret: "portal-secrets"
  existingSecretKey: "portal-token"

auth:
  existingSecret: "auth-secrets"
  existingSecretKey: "auth-secret"

db:
  existingSecret: "db-secrets"
  existingSecretKey: "db-url"
```

Create the secrets manually:

```bash
kubectl create secret generic portal-secrets --from-literal=portal-token='your-portal-token'
kubectl create secret generic auth-secrets --from-literal=auth-secret='your-auth-secret'
kubectl create secret generic db-secrets --from-literal=db-url='postgres://...'
```

### Enabling Ingress

To enable ingress with TLS:

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: developer-portal.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: developer-portal-tls
      hosts:
        - developer-portal.example.com
```

### Disabling TLS Verification (Development Only)

For self-signed certificates in development:

```yaml
developerPortal:
  tlsRejectUnauthorized: false
```

**Warning**: This should never be used in production.

## Architecture

```
┌──────────────────────────────────────┐
│  api7 umbrella chart (existing)      │
│  ┌──────────────┐                    │
│  │  Portal API  │                    │
│  │ (backend)    │                    │
│  │  :4321       │                    │
│  └──────┬───────┘                    │
│         │                            │
│   PostgreSQL (shared api7ee)         │
└─────────┼──────────────────────────┬─┘
          │                          │
          │ portal.url + token       │
          ▼                          │
┌──────────────────────────────────┐ │
│  developer-portal-fe chart       │ │
│  ┌────────────────────┐          │ │
│  │ Developer Portal   │◄─────────┘ │
│  │ FE (Next.js)       │            │
│  │  :3001             │            │
│  └────────┬───────────┘            │
│           │                        │
│     PostgreSQL                     │
│     (dedicated for FE users)       │
└──────────────────────────────────┘
```

## Health Checks

The application exposes a `/healthz` endpoint on port 3001 for both liveness and readiness probes.

## Upgrading

### To 0.2.0

No breaking changes.

## License

Copyright © 2024 API7.ai

## Support

For support, please contact support@api7.ai or visit https://api7.ai
