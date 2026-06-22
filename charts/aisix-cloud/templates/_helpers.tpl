{{/*
Expand the name of the chart.
*/}}
{{- define "aisix-cloud.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "aisix-cloud.fullname" -}}
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
{{- define "aisix-cloud.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "aisix-cloud.labels" -}}
helm.sh/chart: {{ include "aisix-cloud.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: aisix-cloud
{{- end }}

{{/*
Selector labels for a component.
Usage: {{ include "aisix-cloud.selectorLabels" (dict "root" . "component" "api") }}
*/}}
{{- define "aisix-cloud.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aisix-cloud.name" .root }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
PostgreSQL host — uses builtin subchart service name or external host.
*/}}
{{- define "aisix-cloud.pgHost" -}}
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
{{- define "aisix-cloud.pgPort" -}}
{{- if .Values.postgresql.builtin }}
{{- .Values.postgresql.primary.service.ports.postgresql }}
{{- else }}
{{- .Values.externalDatabase.port }}
{{- end }}
{{- end }}

{{/*
PostgreSQL username.
*/}}
{{- define "aisix-cloud.pgUser" -}}
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
{{- define "aisix-cloud.pgDatabase" -}}
{{- if .Values.postgresql.builtin }}
{{- .Values.postgresql.auth.database }}
{{- else }}
{{- .Values.externalDatabase.database }}
{{- end }}
{{- end }}

{{/*
PostgreSQL SSL mode.
*/}}
{{- define "aisix-cloud.pgSSLMode" -}}
{{- if .Values.postgresql.builtin }}
{{- "disable" }}
{{- else }}
{{- .Values.externalDatabase.sslmode | default "disable" }}
{{- end }}
{{- end }}

{{/*
Database URL constructed from postgresql config.
Uses $(PGPASSWORD) env var substitution for runtime secret injection.
*/}}
{{- define "aisix-cloud.databaseURL" -}}
postgres://{{ include "aisix-cloud.pgUser" . }}:$(PGPASSWORD)@{{ include "aisix-cloud.pgHost" . }}:{{ include "aisix-cloud.pgPort" . }}/{{ include "aisix-cloud.pgDatabase" . }}?sslmode={{ include "aisix-cloud.pgSSLMode" . }}
{{- end }}

{{/*
Secret name for aisix-cloud secrets.
*/}}
{{- define "aisix-cloud.secretName" -}}
{{ include "aisix-cloud.fullname" . }}-secrets
{{- end }}

{{/*
Name of the Secret containing the PostgreSQL password.
*/}}
{{- define "aisix-cloud.pgSecretName" -}}
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
{{- printf "%s-external-db" (include "aisix-cloud.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Secret key containing the PostgreSQL password for application connections.
*/}}
{{- define "aisix-cloud.pgPasswordSecretKey" -}}
{{- if and .Values.postgresql.builtin .Values.postgresql.auth.usePostgresUserForAppConnections }}
{{- "postgres-password" }}
{{- else }}
{{- "password" }}
{{- end }}
{{- end }}

{{/*
ServiceAccount name.
*/}}
{{- define "aisix-cloud.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "aisix-cloud.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image pull secrets from global config.
*/}}
{{- define "aisix-cloud.imagePullSecrets" -}}
{{- with .Values.global.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Init container that blocks until PostgreSQL accepts connections.
Reuses the same PG image shipped by the chart so no extra pull is needed.
*/}}
{{- define "aisix-cloud.pgWaitInitContainer" -}}
- name: wait-for-pg
  image: "{{ .Values.postgresql.image.registry }}/{{ .Values.postgresql.image.repository }}:{{ .Values.postgresql.image.tag }}"
  imagePullPolicy: IfNotPresent
  env:
    - name: PGPASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "aisix-cloud.pgSecretName" . }}
          key: {{ include "aisix-cloud.pgPasswordSecretKey" . }}
  command:
    - sh
    - -c
    - |
      until pg_isready -h {{ include "aisix-cloud.pgHost" . }} -p {{ include "aisix-cloud.pgPort" . }} -U {{ include "aisix-cloud.pgUser" . }}; do
        echo "waiting for postgresql..."
        sleep 2
      done
{{- end }}
