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
* Secrets, which have no defaults you can deploy with. **The chart fails the
  render** while one is missing or still holds its placeholder, so an install
  that supplies none of them stops before anything reaches the cluster. Two are
  needed in every mode:

  | Value | Generate with |
  | --- | --- |
  | `secrets.masterKey` | `openssl rand -base64 32` |
  | `secrets.betterAuthSecret` | `openssl rand -base64 48` |

  The database credentials depend on which database you use. With the bundled
  PostgreSQL — `postgresql.builtin: true`, the default — set both of these,
  unless `postgresql.auth.existingSecret` supplies them instead:

  | Value | Generate with |
  | --- | --- |
  | `postgresql.auth.postgresPassword` | `openssl rand -hex 24` |
  | `postgresql.auth.password` | `openssl rand -hex 24` |

  With an [external database](#external-postgresql) neither is read; that mode
  needs `externalDatabase.existingSecret` or `externalDatabase.password`
  instead, and fails the render with neither.

  Whichever mode, use a **URL-safe** database password — `openssl rand -hex 24`,
  not `-base64`. The password of the role that serves application connections is
  embedded in a `postgres://` DSN, and `+`, `/` and `=` corrupt it. On the
  bundled database that role is `postgres` by default, because
  `postgresql.auth.usePostgresUserForAppConnections` defaults to `true`; set
  both passwords URL-safe and the question does not arise.

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

Upgrade with your own values file rather than `--reuse-values`: the same
secrets must be supplied again, and `--reuse-values` replays the previous
release's fully resolved values, chart defaults included, so a default this
chart changed — the probe budgets among them — is not adopted. If you never
kept a file, `helm get values aisix-cp --namespace aisix` prints the overrides
the release was installed with.

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
One of the two is required — with neither, the render fails.
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
| api.affinity | object | `{}` | Affinity rules for the cp-api pod |
| api.corsAllowedOrigins | list | `[]` | Browser origins allowed to call cp-api cross-origin, as bare origins (scheme://host[:port]). Empty — the default — writes no CORS headers at all, which is what a normal install wants: cp-api serves the API and proxies the dashboard, so the browser has only one origin and nothing is ever cross-origin. Populate it only to let a dashboard served from somewhere else reach this API directly, such as a frontend-only PR preview. An entry is a bare origin (https://host[:port]), or `https://*` plus a suffix naming at least three labels (`https://*-api7ai.vercel.app`) — a PR preview's host carries the branch name, so an exact list would mean redeploying cp-api for every pull request. Read the suffix as collision-resistance, NOT as a guarantee: it is a byte suffix, and on a shared host like `.vercel.app` another account can claim a name ending the same way, so a grant that needs a real boundary belongs on a domain you control. Every entry must be spelled the way a BROWSER serializes an origin, and the chart refuses one that is not, naming the spelling to use — a bare `*`, a path, query, fragment or userinfo, a trailing dot, a non-https origin (loopback may use http), an internationalized host given as anything but punycode, a numeric last label that is not a dotted quad, an IPv6 address in any spelling but the one it is sent in, the scheme's default port written out, a port with a leading zero, and a port above 65535. cp-api applies the same rules at startup, so a value this chart accepts is one it will start with. |
| api.dpImage | string | `""` | Gateway image the console hands out in the install snippets it generates for a new data plane |
| api.dpmgrBaseURL | string | `""` | dp-manager /dp/* mTLS endpoint that data-plane hosts dial, as baked into the generated install snippets. Also passed to the dpm deployment, which seeds this host into the TLS server certificate it presents — so an IP address works here, not only a DNS name. When dpm.service.type is NodePort, use https://<node-ip>:<dpm-node-port>. |
| api.extraEnvVars | list | `[]` | Extra environment for cp-api. This is also where AISIX_ALLOW_UNSUPPORTED_UPGRADE=1 goes when an upgrade has to proceed from a release older than this one supports upgrading from — cp-api refuses that upgrade at startup and names the version it needs. |
| api.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| api.image.repository | string | `"docker.io/api7/aisix-cp-api"` | cp-api image repository |
| api.image.tag | string | `""` | Image tag |
| api.metrics.enabled | bool | `true` | Serve Prometheus metrics from cp-api. On by default, matching the gateway chart so both planes are scraped the same way; the port is reachable only inside the cluster (ClusterIP). cp-api binds nothing unless this sets the address, so turning it off leaves the port genuinely unbound inside the pod rather than merely unexposed by the Service. |
| api.metrics.port | int | `9090` | Port the metrics listener binds inside the container |
| api.metrics.service.annotations | object | `{}` | Extra annotations for the metrics Service, e.g. scrape hints for a Prometheus that discovers by annotation rather than ServiceMonitor |
| api.metrics.service.port | int | `9090` | Metrics Service port, on a separate ClusterIP Service so scraping never rides the API Service |
| api.metrics.serviceMonitor.enabled | bool | `false` | Create a Prometheus Operator ServiceMonitor for the metrics Service |
| api.metrics.serviceMonitor.interval | string | `"30s"` | Scrape interval |
| api.metrics.serviceMonitor.labels | object | `{}` | Extra labels, e.g. the `release` label your Prometheus selects on |
| api.metrics.serviceMonitor.metricRelabelings | list | `[]` | Metric relabeling rules |
| api.metrics.serviceMonitor.namespace | string | `""` | Namespace to create the ServiceMonitor in. Empty uses the release namespace |
| api.metrics.serviceMonitor.relabelings | list | `[]` | Scrape-time relabeling rules |
| api.metrics.serviceMonitor.scrapeTimeout | string | `""` | Scrape timeout. Empty leaves the Prometheus default |
| api.nodeSelector | object | `{}` | Node selector for the cp-api pod |
| api.notifyAllowPrivateURLs | bool | `false` | Allow notification channels (budget alert webhooks / Slack) to point at private / internal addresses. Blocked by default (SSRF guard); enable only for On-Premises deployments whose webhook receivers live on an intranet the cp-api pod can route to. |
| api.oauthEnabled | bool | `false` | Offer Google / GitHub sign-in on the console's login page. Leave off unless the deployment carries OAuth client credentials |
| api.playgroundAllowPrivateIPs | bool | `false` | Allow the dashboard playground to reach LLM endpoints on private / internal networks. cp-api blocks private IPs by default (SSRF guard); enable this only for On-Premises deployments whose models live on an internal network the cp-api pod can route to. |
| api.podSecurityContext.runAsNonRoot | bool | `true` | Refuse to run the cp-api pod as root |
| api.podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` | Seccomp profile for the cp-api pod |
| api.publicBaseURL | string | `"http://localhost:8080"` | Publicly reachable cp-api URL. Better Auth validates the session JWT issuer against it, so a value that does not match the address the browser uses breaks sign-in. When api.service.type is NodePort, this must name the API NodePort endpoint (or the TLS reverse proxy in front). |
| api.replicaCount | int | `1` | Number of cp-api replicas |
| api.resources.limits.cpu | string | `"1"` | cp-api CPU limit |
| api.resources.limits.memory | string | `"512Mi"` | cp-api memory limit |
| api.resources.requests.cpu | string | `"100m"` | cp-api CPU request |
| api.resources.requests.memory | string | `"128Mi"` | cp-api memory request |
| api.securityContext.allowPrivilegeEscalation | bool | `false` | Forbid privilege escalation in the cp-api container |
| api.securityContext.capabilities.drop | list | `["ALL"]` | Linux capabilities dropped from the cp-api container |
| api.securityContext.readOnlyRootFilesystem | bool | `true` | Mount the cp-api root filesystem read-only |
| api.service.nodePort | string | `""` | Optional fixed NodePort. Used only when type is NodePort; leave empty to let Kubernetes allocate a port dynamically. Direct NodePort access is plain HTTP, so use a trusted private network or a TLS reverse proxy. |
| api.service.port | int | `8080` | cp-api Service port. This port carries both the Admin API and the Dashboard |
| api.service.type | string | `"ClusterIP"` | cp-api Service type. ClusterIP keeps it inside the cluster; use NodePort or an Ingress to reach the console from outside |
| api.tolerations | list | `[]` | Tolerations for the cp-api pod |
| dpm.affinity | object | `{}` | Affinity rules for the dp-manager pod |
| dpm.extraEnvVars | list | `[]` | Extra environment for dp-manager |
| dpm.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| dpm.image.repository | string | `"docker.io/api7/aisix-cp-dpm"` | dp-manager image repository |
| dpm.image.tag | string | `""` | Image tag |
| dpm.nodeSelector | object | `{}` | Node selector for the dp-manager pod |
| dpm.podSecurityContext.runAsNonRoot | bool | `true` | Refuse to run the dp-manager pod as root |
| dpm.podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` | Seccomp profile for the dp-manager pod |
| dpm.replicaCount | int | `1` | Number of dp-manager replicas |
| dpm.resources.limits.cpu | string | `"1"` | dp-manager CPU limit |
| dpm.resources.limits.memory | string | `"512Mi"` | dp-manager memory limit |
| dpm.resources.requests.cpu | string | `"100m"` | dp-manager CPU request |
| dpm.resources.requests.memory | string | `"128Mi"` | dp-manager memory request |
| dpm.securityContext.allowPrivilegeEscalation | bool | `false` | Forbid privilege escalation in the dp-manager container |
| dpm.securityContext.capabilities.drop | list | `["ALL"]` | Linux capabilities dropped from the dp-manager container |
| dpm.securityContext.readOnlyRootFilesystem | bool | `true` | Mount the dp-manager root filesystem read-only |
| dpm.service.healthListen | string | `":7946"` | Plain-HTTP listen address for /healthz (outbox-poller liveness), probed by the kubelet (the mTLS port 7944 cannot be probed). Set to "" to disable the health server + httpGet probes (the probes then fall back to a TCP check on the mTLS port). |
| dpm.service.nodePort | string | `""` | Optional fixed NodePort for the mTLS port. Used only when type is NodePort; leave empty to let Kubernetes allocate one |
| dpm.service.port | int | `7944` | dp-manager mTLS Service port, the one gateways dial |
| dpm.service.type | string | `"ClusterIP"` | dp-manager Service type. Use NodePort or a LoadBalancer when the gateways run outside this cluster |
| dpm.tolerations | list | `[]` | Tolerations for the dp-manager pod |
| externalDatabase.database | string | `"aisix_cloud"` | Database name |
| externalDatabase.existingSecret | string | `""` | Name of an existing Secret containing the database password (key: "password"). |
| externalDatabase.host | string | `""` | PostgreSQL host |
| externalDatabase.password | string | `""` | If existingSecret is empty, this password is used directly. Use a URL-safe value: it is embedded in a `postgres://` DSN |
| externalDatabase.port | int | `5432` | PostgreSQL port |
| externalDatabase.sslmode | string | `"disable"` | libpq sslmode for the connection, e.g. `require` or `verify-full` for a managed database reached over a network you do not control |
| externalDatabase.username | string | `"aisix"` | Database role the control plane connects as. It has to be able to run the schema migrations cp-api applies at startup |
| global.imagePullSecrets | list | `[]` | Image pull secrets applied to every pod created by this chart |
| global.storageClass | string | `""` | StorageClass for the built-in PostgreSQL volume. Empty uses the cluster's default StorageClass |
| postgresql.auth.database | string | `"aisix_cloud"` | Database name the control plane uses |
| postgresql.auth.existingSecret | string | `""` | Inject DB credentials from a pre-created Secret instead of the values below (the secure path). When set, the password fields are ignored and the placeholder rejection is skipped. |
| postgresql.auth.password | string | `"changeme"` | REQUIRED with builtin=true (unless existingSecret is set). Password for the application role. The chart REJECTS the default `changeme` at render time. Generate a URL-SAFE value with `openssl rand -hex 24`: the password is embedded in a `postgres://` DSN, so the `+`, `/` and `=` that `openssl rand -base64` produces corrupt URL parsing. PostgreSQL bakes it into the data volume on first init, so it has to stay the same across re-deploys |
| postgresql.auth.postgresPassword | string | `"changeme"` | REQUIRED with builtin=true (unless existingSecret is set). Password for the PostgreSQL superuser, under the same URL-safe rule and the same placeholder rejection as `password` above |
| postgresql.auth.usePostgresUserForAppConnections | bool | `true` | Use the built-in PostgreSQL superuser for application connections. cp-api currently runs schema and role migrations on startup, including ALTER ROLE statements that require superuser privileges. |
| postgresql.auth.username | string | `"aisix"` | Application database role cp-api connects as when usePostgresUserForAppConnections is false |
| postgresql.builtin | bool | `true` | Deploy the bundled PostgreSQL subchart. Set to false to point the control plane at the database configured under externalDatabase |
| postgresql.fullnameOverride | string | `""` | Override the generated name of the PostgreSQL resources |
| postgresql.image.registry | string | `"docker.io"` | PostgreSQL image registry |
| postgresql.image.repository | string | `"api7/postgresql"` | PostgreSQL image repository |
| postgresql.image.tag | string | `"15.4.0-debian-11-r45"` | PostgreSQL image tag |
| postgresql.primary.persistence.size | string | `"8Gi"` | Size of the PostgreSQL data volume. It holds every configured resource plus the request telemetry the console reports on |
| postgresql.primary.service.ports.postgresql | int | `5432` | PostgreSQL Service port |
| secrets.betterAuthSecret | string | `"CHANGE_ME_GENERATE_WITH_openssl_rand_-base64_48"` | REQUIRED. HMAC signing secret for Better Auth sessions. Generate with `openssl rand -base64 48`. Changing it signs every signed-in user out |
| secrets.masterKey | string | `"CHANGE_ME_GENERATE_WITH_openssl_rand_-base64_32"` | REQUIRED. Base64-encoded 32-byte AES-256 key that envelope-encrypts the stored upstream provider credentials. Generate with `openssl rand -base64 32`. It is the only thing that can decrypt what was stored under it, so a lost key means re-entering every provider key |
| secrets.masterKeyID | string | `"env:default"` | Identifier recorded alongside every value encrypted with the current master key, so a future key rotation can tell the generations apart |
| serviceAccount.annotations | object | `{}` | Annotations for the ServiceAccount, e.g. a cloud IAM role binding |
| serviceAccount.create | bool | `true` | Create a ServiceAccount for the control-plane pods |
| serviceAccount.name | string | `""` | Name of the ServiceAccount. Empty derives one from the release name; set it to use a ServiceAccount you manage yourself (create: false) |
| twoDSN.enabled | bool | `false` | Open a second, Row-Level-Security-enforced pool for tenant queries. Leave off for an On-Premises deployment |
| twoDSN.existingSecret | string | `""` | Optionally source the serving password from an existing Secret instead of servingPassword above. Key defaults to "serving-password". |
| twoDSN.existingSecretKey | string | `"serving-password"` | Key inside twoDSN.existingSecret holding the serving password |
| twoDSN.servingPassword | string | `""` | Password cp-api assigns to the cp_api_app serving role and uses in the serving DSN. Required when enabled unless existingSecret is set. Use a URL-safe value, from `openssl rand -hex 24`: it is embedded in a `postgres://` DSN, so `+`, `/` and `=` corrupt URL parsing |
| ui.affinity | object | `{}` | Affinity rules for the dashboard pod |
| ui.defaultLocale | string | `"en"` | Fixed dashboard UI language for this deployment. Supported: "en", "zh". There is no in-UI language switcher; the whole console renders in this locale (default English). Read server-side at request time. |
| ui.extraEnvVars | list | `[]` | Extra environment for the dashboard |
| ui.extraVolumeMounts | list | `[]` | Additional mounts for the dashboard container. Use readOnly for CA certificates. |
| ui.extraVolumes | list | `[]` | Additional volumes for the dashboard Pod (for example, a private database CA). |
| ui.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| ui.image.repository | string | `"docker.io/api7/aisix-cp-ui"` | Dashboard image repository |
| ui.image.tag | string | `""` | Image tag |
| ui.nodeSelector | object | `{}` | Node selector for the dashboard pod |
| ui.podSecurityContext.runAsNonRoot | bool | `true` | Refuse to run the dashboard pod as root |
| ui.podSecurityContext.seccompProfile.type | string | `"RuntimeDefault"` | Seccomp profile for the dashboard pod |
| ui.replicaCount | int | `1` | Number of dashboard replicas |
| ui.resources.limits.cpu | string | `"500m"` | Dashboard CPU limit |
| ui.resources.limits.memory | string | `"256Mi"` | Dashboard memory limit |
| ui.resources.requests.cpu | string | `"50m"` | Dashboard CPU request |
| ui.resources.requests.memory | string | `"64Mi"` | Dashboard memory request |
| ui.securityContext.allowPrivilegeEscalation | bool | `false` | Forbid privilege escalation in the dashboard container |
| ui.securityContext.capabilities.drop | list | `["ALL"]` | Linux capabilities dropped from the dashboard container |
| ui.securityContext.readOnlyRootFilesystem | bool | `true` | Mount the dashboard root filesystem read-only |
| ui.service.nodePort | string | `""` | Optional fixed NodePort. Used only when type is NodePort; leave empty to let Kubernetes allocate a port dynamically. This plain-HTTP endpoint is not a standalone Dashboard entry point: use it only behind a same-origin reverse proxy that sends Dashboard pages here and /api/* to cp-api. The proxy should terminate TLS unless it is on a trusted network. |
| ui.service.port | int | `3000` | Dashboard Service port, which cp-api proxies browser traffic to |
| ui.service.type | string | `"ClusterIP"` | Dashboard Service type |
| ui.tolerations | list | `[]` | Tolerations for the dashboard pod |
