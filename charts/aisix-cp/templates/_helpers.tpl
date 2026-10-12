{{/*
Expand the name of the chart.
*/}}
{{- define "aisix-cp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "aisix-cp.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aisix-cp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "aisix-cp.labels" -}}
helm.sh/chart: {{ include "aisix-cp.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: aisix-cp
{{- end }}

{{/*
Selector labels for a component.
Usage: {{ include "aisix-cp.selectorLabels" (dict "root" . "component" "api") }}
*/}}
{{- define "aisix-cp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aisix-cp.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
PostgreSQL host — uses builtin subchart service name or external host.
*/}}
{{- define "aisix-cp.pgHost" -}}
{{- if .Values.postgresql.builtin }}
{{- if .Values.postgresql.fullnameOverride }}
{{- .Values.postgresql.fullnameOverride }}
{{- else }}
{{- printf "%s-postgresql" .Release.Name }}
{{- end }}
{{- else }}
{{- required "externalDatabase.host is required when postgresql.builtin is false" .Values.externalDatabase.host }}
{{- end }}
{{- end }}

{{/*
PostgreSQL port.
*/}}
{{- define "aisix-cp.pgPort" -}}
{{- if .Values.postgresql.builtin }}
{{- .Values.postgresql.primary.service.ports.postgresql }}
{{- else }}
{{- .Values.externalDatabase.port }}
{{- end }}
{{- end }}

{{/*
PostgreSQL username.
*/}}
{{- define "aisix-cp.pgUser" -}}
{{- if .Values.postgresql.builtin }}
{{- if .Values.postgresql.auth.usePostgresUserForAppConnections }}
{{- "postgres" }}
{{- else }}
{{- .Values.postgresql.auth.username }}
{{- end }}
{{- else }}
{{- .Values.externalDatabase.username }}
{{- end }}
{{- end }}

{{/*
PostgreSQL database name.
*/}}
{{- define "aisix-cp.pgDatabase" -}}
{{- if .Values.postgresql.builtin }}
{{- .Values.postgresql.auth.database }}
{{- else }}
{{- .Values.externalDatabase.database }}
{{- end }}
{{- end }}

{{/*
PostgreSQL SSL mode.
*/}}
{{- define "aisix-cp.pgSSLMode" -}}
{{- if .Values.postgresql.builtin }}
{{- "disable" }}
{{- else }}
{{- .Values.externalDatabase.sslmode | default "disable" }}
{{- end }}
{{- end }}

{{/*
Database URL WITHOUT its password, for the rendered config files. The
password never enters a ConfigMap: each binary reads it from its
*_DATABASE_PASSWORD env var (wired from the database Secret) and splices it
into this DSN at startup.
*/}}
{{- define "aisix-cp.databaseURL" -}}
postgres://{{ include "aisix-cp.pgUser" . }}@{{ include "aisix-cp.pgHost" . }}:{{ include "aisix-cp.pgPort" . }}/{{ include "aisix-cp.pgDatabase" . }}?sslmode={{ include "aisix-cp.pgSSLMode" . }}
{{- end }}

{{/*
Serving database URL for two-DSN mode: same host/port/db, but connecting
as the non-superuser cp_api_app role. No password, as above.
*/}}
{{- define "aisix-cp.servingDatabaseURL" -}}
postgres://cp_api_app@{{ include "aisix-cp.pgHost" . }}:{{ include "aisix-cp.pgPort" . }}/{{ include "aisix-cp.pgDatabase" . }}?sslmode={{ include "aisix-cp.pgSSLMode" . }}
{{- end }}

{{/*
Where each component's rendered config file is mounted. Not under
/etc/aisix, which in the cp-api image holds the baked pricing snapshot.
*/}}
{{- define "aisix-cp.configDir" -}}
/etc/aisix-cp
{{- end }}

{{/*
Validated secrets.retiredMasterKeys as a list of dicts:
id (the MasterKeyID), envSuffix (the id as a RETIRED_* env-var suffix —
":" becomes "_", which the binaries translate back) and secretKey (the key
in the chart Secret).
*/}}
{{- define "aisix-cp.retiredMasterKeys" -}}
{{- $out := list }}
{{- range $id, $value := .Values.secrets.retiredMasterKeys }}
{{- if not (regexMatch "^[a-z0-9:-]+$" $id) }}
{{- fail (printf "secrets.retiredMasterKeys: %q is not a master key id — ids use lowercase letters, digits, \":\" and \"-\" (e.g. env:2026-q1)" $id) }}
{{- end }}
{{- if not $value }}
{{- fail (printf "secrets.retiredMasterKeys.%s is empty: set the base64 key it used, or remove the entry" $id) }}
{{- end }}
{{- $suffix := replace ":" "_" $id }}
{{- $out = append $out (dict "id" $id "envSuffix" $suffix "secretKey" (printf "retired-master-key-%s" $suffix)) }}
{{- end }}
{{- toJson $out }}
{{- end }}

{{/*
Name of the Secret holding the cp_api_app serving-role password.
*/}}
{{- define "aisix-cp.servingPasswordSecretName" -}}
{{- if .Values.twoDSN.existingSecret }}
{{- .Values.twoDSN.existingSecret }}
{{- else }}
{{- include "aisix-cp.secretName" . }}
{{- end }}
{{- end }}

{{/*
Secret key holding the cp_api_app serving-role password.
*/}}
{{- define "aisix-cp.servingPasswordSecretKey" -}}
{{- if .Values.twoDSN.existingSecret }}
{{- .Values.twoDSN.existingSecretKey | default "serving-password" }}
{{- else }}
{{- "serving-password" }}
{{- end }}
{{- end }}

{{/*
Secret name for aisix-cp secrets.
*/}}
{{- define "aisix-cp.secretName" -}}
{{ include "aisix-cp.fullname" . }}-secrets
{{- end }}

{{/*
Name of the Secret containing the PostgreSQL password.
*/}}
{{- define "aisix-cp.pgSecretName" -}}
{{- if .Values.postgresql.builtin }}
{{- if .Values.postgresql.auth.existingSecret }}
{{- .Values.postgresql.auth.existingSecret }}
{{- else if .Values.postgresql.fullnameOverride }}
{{- .Values.postgresql.fullnameOverride }}
{{- else }}
{{- printf "%s-postgresql" .Release.Name }}
{{- end }}
{{- else if .Values.externalDatabase.existingSecret }}
{{- .Values.externalDatabase.existingSecret }}
{{- else }}
{{- printf "%s-external-db" (include "aisix-cp.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Secret key containing the PostgreSQL password for application connections.
*/}}
{{- define "aisix-cp.pgPasswordSecretKey" -}}
{{- if and .Values.postgresql.builtin .Values.postgresql.auth.usePostgresUserForAppConnections }}
{{- "postgres-password" }}
{{- else }}
{{- "password" }}
{{- end }}
{{- end }}

{{/*
ServiceAccount name.
*/}}
{{- define "aisix-cp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "aisix-cp.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image pull secrets from global config.
*/}}
{{- define "aisix-cp.imagePullSecrets" -}}
{{- with .Values.global.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Init container that blocks until PostgreSQL accepts connections.
Reuses the same PG image shipped by the chart so no extra pull is needed.
*/}}
{{- define "aisix-cp.pgWaitInitContainer" -}}
- name: wait-for-pg
  image: "{{ .Values.postgresql.image.registry }}/{{ .Values.postgresql.image.repository }}:{{ .Values.postgresql.image.tag }}"
  imagePullPolicy: IfNotPresent
  env:
    - name: PGPASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "aisix-cp.pgSecretName" . }}
          key: {{ include "aisix-cp.pgPasswordSecretKey" . }}
  command:
    - sh
    - -c
    - |
      until pg_isready -h {{ include "aisix-cp.pgHost" . }} -p {{ include "aisix-cp.pgPort" . }} -U {{ include "aisix-cp.pgUser" . }}; do
        echo "waiting for postgresql..."
        sleep 2
      done
{{- end }}

{{/*
Whether the chart's own Secret carries the first administrator's password
(key bootstrap-admin-password): the bootstrap is on, it is not read from
api.bootstrapAdmin.existingSecret, and either a password was given or the
chart generates one (on-premises only — a SaaS control plane ignores the
bootstrap).
*/}}
{{- define "aisix-cp.bootstrapAdminPasswordManaged" -}}
{{- $b := .Values.api.bootstrapAdmin | default dict -}}
{{- if and $b.email (not $b.existingSecret) (or $b.password (ne (.Values.api.deploymentMode | default "on-premises") "saas")) -}}
true
{{- end -}}
{{- end }}

{{/*
The first administrator's password as the chart stores it: the one given,
else the one this release's Secret already holds (so helm upgrade keeps
it), else a new random one. `lookup` answers nothing under `helm template`
and GitOps renderers, which therefore generate a new one on every render —
those deployments set api.bootstrapAdmin.password or existingSecret.
*/}}
{{- define "aisix-cp.bootstrapAdminPassword" -}}
{{- $b := .Values.api.bootstrapAdmin | default dict -}}
{{- if $b.password -}}
{{- $b.password -}}
{{- else -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace (include "aisix-cp.secretName" .) -}}
{{- if and $existing $existing.data (hasKey $existing.data "bootstrap-admin-password") -}}
{{- index $existing.data "bootstrap-admin-password" | b64dec -}}
{{- else -}}
{{- randAlphaNum 24 -}}
{{- end -}}
{{- end -}}
{{- end }}
