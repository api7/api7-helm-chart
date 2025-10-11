{{/*
Expand the name of the chart.
*/}}
{{- define "api7-ingress-controller-manager.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "api7-ingress-controller-manager.name.fullname" -}}
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
{{- define "api7-ingress-controller-manager.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{/*
Common labels
*/}}
{{- define "api7-ingress-controller-manager.labels" -}}
helm.sh/chart: {{ include "api7-ingress-controller-manager.chart" . }}
{{ include "api7-ingress-controller-manager.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "api7-ingress-controller-manager.selectorLabels" -}}
{{- if .Values.labelsOverride }}
{{- tpl (.Values.labelsOverride | toYaml) . }}
{{- else }}
app.kubernetes.io/name: {{ include "api7-ingress-controller-manager.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{- end }}

{{/*
Webhook service name - ensure it stays within 63 character limit
*/}}
{{- define "api7-ingress-controller-manager.webhook.serviceName" -}}
{{- $suffix := "-webhook-svc" -}}
{{- $maxLen := sub 63 (len $suffix) | int -}}
{{- $baseName := include "api7-ingress-controller-manager.name.fullname" . | trunc $maxLen | trimSuffix "-" -}}
{{- printf "%s%s" $baseName $suffix -}}
{{- end }}

{{/*
Webhook secret name - ensure it stays within 63 character limit
*/}}
{{- define "api7-ingress-controller-manager.webhook.secretName" -}}
{{- $suffix := "-webhook-cert" -}}
{{- $maxLen := sub 63 (len $suffix) | int -}}
{{- $baseName := include "api7-ingress-controller-manager.name.fullname" . | trunc $maxLen | trimSuffix "-" -}}
{{- printf "%s%s" $baseName $suffix -}}
{{- end }}
