{{/*
Expand the name of the chart.
*/}}
{{- define "apisix-ingress-controller.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "apisix-ingress-controller.fullname" -}}
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
{{- define "apisix-ingress-controller.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "apisix-ingress-controller.labels" -}}
helm.sh/chart: {{ include "apisix-ingress-controller.chart" . }}
{{ include "apisix-ingress-controller.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "apisix-ingress-controller.selectorLabels" -}}
{{- if .Values.labelsOverride }}
{{- tpl (.Values.labelsOverride | toYaml) . }}
{{- else }}
app.kubernetes.io/name: {{ include "apisix-ingress-controller.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "apisix-ingress-controller.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "apisix-ingress-controller.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "apisix-ingress-controller.namespace" -}}
{{- default .Release.Namespace .Values.namespace -}}
{{- end -}}

{{/*
Key to use to fetch admin token from secret
*/}}
{{- define "apisix-ingress-controller.credentials.secretAdminKey" -}}
{{- if .Values.config.dashboard.existingSecretAdminKeyKey }}
{{- .Values.config.dashboard.existingSecretAdminKeyKey }}
{{- else }}
{{- "adminKey" }}
{{- end }}
{{- end }}
