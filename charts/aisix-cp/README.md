# aisix-cp

![Version: 1.3.0](https://img.shields.io/badge/Version-1.3.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.3.0](https://img.shields.io/badge/AppVersion-1.3.0-informational?style=flat-square)

Helm chart for AISIX control plane (cp-api, dp-manager, dashboard)

AISIX is an AI gateway: it fronts LLM providers with routing, rate limiting,
budgets, caching, guardrails, and observability behind an OpenAI-compatible API.
This chart installs the **control plane** — the console and management services
that configure the gateways and collect what they report.

It installs three services and, by default, a PostgreSQL database:

* `cp-api` — the Admin API, and the externally reachable entry point. It also
  reverse-proxies the dashboard, so the console and the API share one origin.
* `dp-manager` — issues gateway certificates over mutual TLS and delivers
  configuration to the gateways.
* `dashboard` — the Next.js console, reached through `cp-api`.
* PostgreSQL — the shared datastore. The chart deploys a bundled single
  instance by default, or connects to an [external database](#external-postgresql).

The gateways are **not** installed by this chart. Install them separately with
the [`aisix`](../aisix/README.md) chart, or any of the other options in the
[on-premises installation guide](https://docs.api7.ai/ai-gateway/on-premises/deployment);
they connect out to `dp-manager`, so the control plane needs no inbound access
to gateway hosts.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| API7 | <support@api7.ai> | <https://api7.ai> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql | 12.12.10 |

## Prerequisites

* Kubernetes v1.23+
* Helm v3+
* OpenSSL, to generate the secrets below
* Four secrets, which have no defaults you can deploy with. The chart **fails
  the render** while any of them still holds its placeholder, so an install with
  none of them set stops before anything reaches the cluster:

  | Value | Generate with |
  | --- | --- |
  | `secrets.masterKey` | `openssl rand -base64 32` |
  | `secrets.betterAuthSecret` | `openssl rand -base64 48` |
  | `postgresql.auth.postgresPassword` | `openssl rand -hex 24` |
  | `postgresql.auth.password` | `openssl rand -hex 24` |

  Use **URL-safe** database passwords — `openssl rand -hex 24`, not
  `-base64`. The password of whichever role serves application connections is
  embedded in a `postgres://` DSN, and `+`, `/` and `=` corrupt it. That role is
  `postgres` by default, because `postgresql.auth.usePostgresUserForAppConnections`
  defaults to `true`; set both passwords URL-safe and the question does not
  arise. The two `postgresql.auth.*` values are read only when
  `postgresql.builtin` is `true` (the default) and
  `postgresql.auth.existingSecret` is empty.

**Keep `secrets.masterKey`.** It encrypts stored provider credentials and the
private key of the certificate authority that issued your gateway
certificates. Neither is recoverable from a database backup without it, so an
upgrade or a reinstall that supplies a *new* key leaves the existing rows
unreadable. Store it, its `secrets.masterKeyID`, and `secrets.betterAuthSecret`
the way you store a database backup — see
[Backup and Recovery](https://docs.api7.ai/ai-gateway/on-premises/backup-and-recovery).

## Install

Generate the secrets into a values file and keep that file: it is what you
upgrade with, and it is the only copy of the master key.

```sh
cat > cp-values.yaml <<EOF
secrets:
  masterKey: "$(openssl rand -base64 32)"
  betterAuthSecret: "$(openssl rand -base64 48)"
postgresql:
  auth:
    postgresPassword: "$(openssl rand -hex 24)"
    password: "$(openssl rand -hex 24)"
EOF
```

Then install the chart:

```sh
helm repo add api7 https://charts.api7.ai
helm repo update

helm install aisix-cp api7/aisix-cp --namespace aisix --create-namespace \
  --version 1.3.0 \
  -f cp-values.yaml
```

Or pass the four values on the command line instead of keeping a file — the
same install, as long as you record what you generated:

```sh
helm install aisix-cp api7/aisix-cp --namespace aisix --create-namespace \
  --version 1.3.0 \
  --set secrets.masterKey="$(openssl rand -base64 32)" \
  --set secrets.betterAuthSecret="$(openssl rand -base64 48)" \
  --set postgresql.auth.postgresPassword="$(openssl rand -hex 24)" \
  --set postgresql.auth.password="$(openssl rand -hex 24)"
```

`cp-api` runs the schema migration before it binds its port, so its first pod
can take a while to turn ready. A `startupProbe` covers that; wait for the pods:

```sh
kubectl -n aisix rollout status deploy/aisix-cp-api
```

### Reach the console

All three services are `ClusterIP` by default. `cp-api` serves both the Admin
API and the dashboard, so one port-forward reaches everything:

```sh
kubectl -n aisix port-forward svc/aisix-cp-api 8080:8080
```

Open `http://localhost:8080` while it runs. Sign-in is checked against the
origin in `api.publicBaseURL`, which defaults to `http://localhost:8080` and
matches this port-forward (`127.0.0.1` works too). Reaching the console at any
other address — an Ingress, a LoadBalancer, a different port — is refused at
sign-in with an "address not allowed" error until you either point
`api.publicBaseURL` at that address and upgrade, or add it to
`AISIX_TRUSTED_ORIGINS` through `ui.extraEnvVars`, which is additive and so
covers a console reached through more than one hostname.

On first visit, select **Create an account**, register the first user, accept
the agreement, and create the first organization. The account you create this
way is the deployment's first administrator; there is no seeded password.

### Attach a gateway

Set `api.dpmgrBaseURL` to the address gateways will dial and upgrade the
release. It is both the endpoint the console writes into the install commands
it generates and the host `dp-manager` seeds into the TLS server certificate it
presents — left empty it does neither, and a gateway dialing an IP literal
fails the handshake with nothing logged to say why.

The console's generated commands carry a gateway image, taken from
`api.dpImage`. Left empty — the default — it follows the chart's `appVersion`,
so this release hands out `docker.io/api7/aisix:1.3.0`.
Set it only to pin a different image, and remember that a value set explicitly
carries forward across upgrades, so gateways added later come up on the old
image.

## Upgrade

The control-plane chart and the gateway chart ship with the same `version` and
`appVersion` every release, so both move to the same release tag. **Upgrade the
control plane first, then the gateways** — a gateway may lag the control plane,
not the other way round. Take a database backup before you start.

```sh
helm repo update

helm upgrade aisix-cp api7/aisix-cp --namespace aisix -f cp-values.yaml
```

Upgrade with your own values file rather than `--reuse-values`: the same four
secrets must be supplied again, and `--reuse-values` replays the previous
release's fully resolved values, chart defaults included, so a default this
chart changed — the probe budgets among them — is not adopted. If you never
kept a file, `helm get values aisix-cp` prints the overrides the release was
installed with.

Wait for the `cp-api` pods to become ready before upgrading the gateways: the
schema migration runs on first start under the new version.

`cp-api` refuses to start when the database was last run by a release older
than this one supports upgrading from, naming the version it found and the
oldest it accepts. Upgrade to a supported version first; to proceed anyway,
after taking a backup, pass `AISIX_ALLOW_UNSUPPORTED_UPGRADE=1` through
`api.extraEnvVars`. See
[Upgrade](https://docs.api7.ai/ai-gateway/on-premises/upgrade).

## Uninstall

```sh
helm uninstall aisix-cp --namespace aisix
```

Two things deliberately survive it. The bundled PostgreSQL PVC is not owned by
the release, so the database — and everything in it — stays until you delete it
by hand. The chart's own Secret carries `helm.sh/resource-policy: keep`, so the
master key survives too, which is what lets a reinstall read the data that is
still there. Remove them only when you mean to discard the deployment:

```sh
kubectl -n aisix get pvc                                # find the database volume
kubectl -n aisix delete pvc data-aisix-cp-postgresql-0
kubectl -n aisix delete secret aisix-cp-secrets
```

## Configuration examples

The full list of values is in the [Parameters](#parameters) table below. Put
these in your values file and pass it with `-f`.

### External PostgreSQL

The bundled PostgreSQL is a single instance and is not a production database.
Point the control plane at one you operate instead — provision the role and
privileges it needs first, per
[External Database](https://docs.api7.ai/ai-gateway/on-premises/external-database):

```yaml
postgresql:
  builtin: false

externalDatabase:
  host: postgres.example.com
  port: 5432
  username: aisix
  database: aisix_cloud
  existingSecret: aisix-cp-db          # key: password
  sslmode: require
```

```sh
kubectl -n aisix create secret generic aisix-cp-db \
  --from-literal=password='<url-safe-password>'
```

`externalDatabase.existingSecret` reads the password from a Secret you manage,
under the key `password`; `externalDatabase.password` takes it inline instead.
The external database must be reachable before the control plane starts — only
the bundled mode gets a wait-for-database init container. The two
`postgresql.auth.*` passwords are not read in this mode, and the placeholder
rejection is skipped with them, but `secrets.masterKey` and
`secrets.betterAuthSecret` are still required.

### Private PostgreSQL CA trust for the dashboard

When external PostgreSQL uses a private CA, the dashboard's Node.js PostgreSQL
client needs to trust that CA. Otherwise database-backed authentication can fail
with `SELF_SIGNED_CERT_IN_CHAIN` even while the dashboard page is reachable.

Provision a ConfigMap named `aisix-postgres-ca` in the **dashboard namespace**,
containing the public PEM CA certificate under the key `ca.crt`. Then add these
values to your existing external-database configuration:

```yaml
ui:
  extraEnvVars:
    - name: NODE_EXTRA_CA_CERTS
      value: /etc/aisix/postgres-ca/ca.crt
  extraVolumes:
    - name: postgres-ca
      configMap:
        name: aisix-postgres-ca
        items:
          - key: ca.crt
            path: ca.crt
  extraVolumeMounts:
    - name: postgres-ca
      mountPath: /etc/aisix/postgres-ca
      readOnly: true
```

For a Secret-backed volume, replace `configMap.name` with `secret.secretName`
and keep the same `items` mapping. Only the public CA certificate is needed;
do not distribute the CA private key. Kubernetes cannot mount a ConfigMap or
Secret from another namespace, so CA distribution is the operator's responsibility.

These lists append to the built-in Next.js cache volume and mount. Choose unique
volume names and mount paths; do not reuse `next-cache` or `/app/.next/cache`.
The defaults are empty and preserve the existing deployment behavior.

Keep PostgreSQL TLS certificate verification enabled. After updating or rotating
the CA, roll out the dashboard again: Node.js loads `NODE_EXTRA_CA_CERTS` when
the process starts, and this chart does not automatically restart Pods when an
externally managed certificate changes. Manage the CA resource and these values
in your deployment source so subsequent GitOps syncs preserve the configuration.

### A console served from another origin

`cp-api` proxies the dashboard, so a normal install has one origin and nothing
is ever cross-origin — which is why `api.corsAllowedOrigins` is empty by
default and writes no CORS headers at all. Populate it only to let a dashboard
served from somewhere else call this API directly, such as a frontend-only
preview deployment:

```yaml
api:
  publicBaseURL: https://console.example.com
  corsAllowedOrigins:
    - https://console.example.com
    - https://*-api7ai.vercel.app
```

An entry is a bare origin (`https://host[:port]`), or `https://*` plus a host
suffix starting with `-` or `.` and naming at least three labels. It must be
spelled the way a **browser** serializes an origin: no path, query, fragment,
userinfo or trailing dot, no bare `*`, https only (loopback may use http), a
punycode host, no default port written out. The chart applies cp-api's own
rules and fails the render on anything else, so a value that installs is one
cp-api will start with. Read a wildcard suffix as collision-resistance rather
than a boundary — it is a byte suffix, and a shared preview host allocates
names first-come-first-served — so a grant that needs a real boundary belongs
on a domain you control.

### OpenShift

The chart installs under the default `restricted-v2` security context
constraint. Since 1.3.0 it pins no UID: the pod security contexts for `api`,
`dpm` and `ui` carry only `runAsNonRoot` and `seccompProfile`, so the platform
assigns the UID and GID, and the only paths written at runtime are `emptyDir`
volumes. No custom SCC, `anyuid`, or service-account change is needed.

The bundled PostgreSQL is a dependency chart and still pins its own UID, which
a parent chart cannot make conditional. Turn its two security contexts off at
install time:

```sh
helm install aisix-cp api7/aisix-cp --namespace aisix --create-namespace \
  --version 1.3.0 \
  -f cp-values.yaml \
  --set postgresql.primary.podSecurityContext.enabled=false \
  --set postgresql.primary.containerSecurityContext.enabled=false
```

Nothing else needs disabling — in particular do not turn off
`postgresql.shmVolume`, or PostgreSQL falls back to the runtime's 64Mi
`/dev/shm` and parallel queries fail with `could not resize shared memory
segment`. Using an [external database](#external-postgresql) avoids the
question entirely, and is the better production choice on any platform.

To pin a fixed UID back — on a cluster that does not assign one, or to match
existing volume ownership — set the three keys the defaults leave out. These
are the values releases before 1.3.0 pinned:

```yaml
api:
  podSecurityContext:
    runAsUser: 10001
    runAsGroup: 101
    fsGroup: 101
dpm:
  podSecurityContext:
    runAsUser: 10001
    runAsGroup: 101
    fsGroup: 101
ui:
  podSecurityContext:
    runAsUser: 1001
    runAsGroup: 65533
    fsGroup: 65533
```

### Prometheus metrics

`cp-api` serves its own operational metrics — the `aisix_cp_` family — on a
separate listener and a separate `ClusterIP` Service, never on the API port.
It is on by default; create a ServiceMonitor for it with:

```yaml
api:
  metrics:
    serviceMonitor:
      enabled: true
      labels:
        release: prometheus
```

## Parameters

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| api.affinity | object | `{}` |  |
| api.corsAllowedOrigins | list | `[]` |  |
| api.dpImage | string | `""` |  |
| api.dpmgrBaseURL | string | `""` |  |
| api.extraEnvVars | list | `[]` |  |
| api.image.pullPolicy | string | `"IfNotPresent"` |  |
| api.image.repository | string | `"docker.io/api7/aisix-cp-api"` |  |
| api.image.tag | string | `""` |  |
| api.metrics.enabled | bool | `true` |  |
| api.metrics.port | int | `9090` |  |
| api.metrics.service.annotations | object | `{}` |  |
| api.metrics.service.port | int | `9090` |  |
| api.metrics.serviceMonitor.enabled | bool | `false` |  |
| api.metrics.serviceMonitor.interval | string | `"30s"` |  |
| api.metrics.serviceMonitor.labels | object | `{}` |  |
| api.metrics.serviceMonitor.metricRelabelings | list | `[]` |  |
| api.metrics.serviceMonitor.namespace | string | `""` |  |
| api.metrics.serviceMonitor.relabelings | list | `[]` |  |
| api.metrics.serviceMonitor.scrapeTimeout | string | `""` |  |
| api.nodeSelector | object | `{}` |  |
| api.notifyAllowPrivateURLs | bool | `false` |  |
| api.oauthEnabled | bool | `false` |  |
| api.playgroundAllowPrivateIPs | bool | `false` |  |
| api.podSecurityContext.runAsNonRoot | bool | `true` |  |
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
| api.service.nodePort | string | `""` |  |
| api.service.port | int | `8080` |  |
| api.service.type | string | `"ClusterIP"` |  |
| api.tolerations | list | `[]` |  |
| dpm.affinity | object | `{}` |  |
| dpm.extraEnvVars | list | `[]` |  |
| dpm.image.pullPolicy | string | `"IfNotPresent"` |  |
| dpm.image.repository | string | `"docker.io/api7/aisix-cp-dpm"` |  |
| dpm.image.tag | string | `""` |  |
| dpm.nodeSelector | object | `{}` |  |
| dpm.podSecurityContext.runAsNonRoot | bool | `true` |  |
| dpm.podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| dpm.replicaCount | int | `1` |  |
| dpm.resources.limits.cpu | string | `"1"` |  |
| dpm.resources.limits.memory | string | `"512Mi"` |  |
| dpm.resources.requests.cpu | string | `"100m"` |  |
| dpm.resources.requests.memory | string | `"128Mi"` |  |
| dpm.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| dpm.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| dpm.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| dpm.service.healthListen | string | `":7946"` |  |
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
| twoDSN.enabled | bool | `false` |  |
| twoDSN.existingSecret | string | `""` |  |
| twoDSN.existingSecretKey | string | `"serving-password"` |  |
| twoDSN.servingPassword | string | `""` |  |
| ui.affinity | object | `{}` |  |
| ui.defaultLocale | string | `"en"` |  |
| ui.extraEnvVars | list | `[]` |  |
| ui.extraVolumeMounts | list | `[]` | Additional mounts for the dashboard container. Use readOnly for CA certificates. |
| ui.extraVolumes | list | `[]` | Additional volumes for the dashboard Pod (for example, a private database CA). |
| ui.image.pullPolicy | string | `"IfNotPresent"` |  |
| ui.image.repository | string | `"docker.io/api7/aisix-cp-ui"` |  |
| ui.image.tag | string | `""` |  |
| ui.nodeSelector | object | `{}` |  |
| ui.podSecurityContext.runAsNonRoot | bool | `true` |  |
| ui.podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| ui.replicaCount | int | `1` |  |
| ui.resources.limits.cpu | string | `"500m"` |  |
| ui.resources.limits.memory | string | `"256Mi"` |  |
| ui.resources.requests.cpu | string | `"50m"` |  |
| ui.resources.requests.memory | string | `"64Mi"` |  |
| ui.securityContext.allowPrivilegeEscalation | bool | `false` |  |
| ui.securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| ui.securityContext.readOnlyRootFilesystem | bool | `true` |  |
| ui.service.nodePort | string | `""` |  |
| ui.service.port | int | `3000` |  |
| ui.service.type | string | `"ClusterIP"` |  |
| ui.tolerations | list | `[]` |  |
