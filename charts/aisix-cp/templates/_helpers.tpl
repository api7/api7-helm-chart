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
Database URL constructed from postgresql config.
Uses $(PGPASSWORD) env var substitution for runtime secret injection.
*/}}
{{- define "aisix-cp.databaseURL" -}}
postgres://{{ include "aisix-cp.pgUser" . }}:$(PGPASSWORD)@{{ include "aisix-cp.pgHost" . }}:{{ include "aisix-cp.pgPort" . }}/{{ include "aisix-cp.pgDatabase" . }}?sslmode={{ include "aisix-cp.pgSSLMode" . }}
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
