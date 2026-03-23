{{/*
Expand the name of the chart.
*/}}
{{- define "developer-portal-fe.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "developer-portal-fe.fullname" -}}
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
{{- define "developer-portal-fe.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "developer-portal-fe.labels" -}}
helm.sh/chart: {{ include "developer-portal-fe.chart" . }}
{{ include "developer-portal-fe.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "developer-portal-fe.selectorLabels" -}}
app.kubernetes.io/name: {{ include "developer-portal-fe.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "developer-portal-fe.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "developer-portal-fe.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Renders a value that contains template.
Usage:
{{ include "developer-portal-fe.tplvalues.render" (dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "developer-portal-fe.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else}}
        {{- tpl (.value | toYaml) .context }}
    {{- end}}
{{- end -}}

{{/*
Get the secret name for portal token, auth secret, and db url
*/}}
{{- define "developer-portal-fe.secretName" -}}
{{- if .Values.portal.existingSecret }}
{{- .Values.portal.existingSecret }}
{{- else }}
{{- include "developer-portal-fe.fullname" . }}-secrets
{{- end }}
{{- end }}
