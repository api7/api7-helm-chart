# developer-portal-fe

![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.14.0](https://img.shields.io/badge/AppVersion-0.14.0-informational?style=flat-square)

A Helm chart for API7 Developer Portal Frontend

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| API7 | <support@api7.ai> | <https://api7.ai> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql | 12.12.10 |

## Install

```sh
helm repo add api7 https://charts.api7.ai
helm repo update

helm install developer-portal-fe api7/developer-portal-fe --namespace api7 --create-namespace
```

## Configuring the portal application

The chart renders the application's `config.yaml` from `developerPortal.config`,
which is passed through verbatim. Any field the application's config schema
accepts can be set there — `app.name`, `app.desc`, `auth.emailAndPassword`,
`auth.genericOAuthProviders`, `db.ssl`, and so on — without waiting for a chart
release. Which fields exist depends on the deployed application version
(`developerPortal.image.tag`).

The connection settings stay with the chart and are merged in last, so they
always win over `developerPortal.config`:

| Config path | Comes from |
| :--- | :--- |
| `portal.url` | `portal.url` |
| `portal.token` | `${PORTAL_TOKEN}` — Secret (`portal.existingSecret`) |
| `db.url` | `${DB_URL}` — Secret (`db.existingSecret`) |
| `auth.secret` | `${AUTH_SECRET}` — Secret (`auth.existingSecret`) |
| `app.baseURL`, `app.trustedOrigins` | `app.baseURL`, `app.trustedOrigins` |

Changing `developerPortal.config` rolls the Pods automatically — the Deployment
carries a checksum of the rendered ConfigMap.

### Keep credentials out of the ConfigMap

`developerPortal.config` is rendered into a ConfigMap, so it is the wrong place
for a client secret or a database password. The application substitutes
`${VAR}` and `${VAR:default}` in every string value of `config.yaml` at startup,
so put a placeholder in the config and inject the real value as an environment
variable with `developerPortal.extraEnvVars`:

```yaml
developerPortal:
  config:
    auth:
      genericOAuthProviders:
        - providerId: keycloak
          discoveryUrl: https://sso.example.com/realms/main/.well-known/openid-configuration
          clientId: devportal
          clientSecret: ${OIDC_CLIENT_SECRET}
  extraEnvVars:
    - name: OIDC_CLIENT_SECRET
      valueFrom:
        secretKeyRef:
          name: devportal-oidc
          key: client-secret
```

A missing variable is a startup error, not an empty string — the Pod fails
fast instead of running with a blank secret.

### Examples

Name and describe the portal:

```yaml
developerPortal:
  config:
    app:
      name: "Example APIs"
      desc: "Everything you need to build on Example."
```

Turn off password sign-in and require two-factor authentication:

```yaml
developerPortal:
  config:
    auth:
      emailAndPassword:
        enabled: false
      twoFactor:
        enabled: true
        required: true
```

Connect to a managed PostgreSQL that requires TLS, in its own schema:

```yaml
developerPortal:
  config:
    db:
      schema: portal
      ssl:
        rejectUnauthorized: true
        ca: ${DB_CA_PEM}
      pool:
        max: 30
        min: 2
```

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
| developerPortal.config | object | `{"app":{"name":"Developer Portal"}}` | Developer Portal application config, rendered verbatim into `config.yaml` |
| developerPortal.extraEnvVars | list | `[]` |  |
| developerPortal.extraVolumeMounts | list | `[]` |  |
| developerPortal.extraVolumes | list | `[]` |  |
| developerPortal.image.pullPolicy | string | `"IfNotPresent"` |  |
| developerPortal.image.repository | string | `"api7/api7-ee-developer-portal-fe"` |  |
| developerPortal.image.tag | string | `"v0.14.0"` |  |
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
| postgresql.image.registry | string | `"docker.io"` |  |
| postgresql.image.repository | string | `"api7/postgresql"` |  |
| postgresql.image.tag | string | `"15.4.0-debian-11-r45"` |  |
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

## Upgrading

### To 0.2.0

The bundled application moves from 0.5.7 to 0.14.0, which requires `auth.secret`
to be at least 32 characters — a shorter secret fails validation at startup.
Rotate it before upgrading (`openssl rand -base64 32`); rotating signs existing
users out, so they will have to sign in again.

`auth.socialProviders` is the one config field to avoid on this application
version: its schema is mis-declared upstream and the Pod fails to start when the
field is set. Use `auth.genericOAuthProviders` instead.
