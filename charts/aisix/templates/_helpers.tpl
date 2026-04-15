{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "aisix.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "aisix.fullname" -}}
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
{{- define "aisix.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "aisix.labels" -}}
helm.sh/chart: {{ include "aisix.chart" . }}
{{ include "aisix.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "aisix.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aisix.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "aisix.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "aisix.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Scheme to use while connecting etcd
*/}}
{{- define "aisix.etcd.scheme" -}}
{{- if .Values.etcd.auth.tls.enabled }}
{{- "https" }}
{{- else }}
{{- "http" }}
{{- end }}
{{- end }}

{{/*
Etcd host URL(s) to inject into config.yaml.
When etcd subchart is enabled, construct the in-cluster FQDN automatically.
When disabled, use the user-supplied deployment.etcd.host list.
*/}}
{{- define "aisix.etcd.hosts" -}}
{{- if .Values.etcd.enabled }}
{{- $scheme := include "aisix.etcd.scheme" . }}
{{- if .Values.etcd.fullnameOverride }}
- "{{ $scheme }}://{{ .Values.etcd.fullnameOverride }}:{{ .Values.etcd.service.port }}"
{{- else }}
- "{{ $scheme }}://{{ .Release.Name }}-etcd.{{ .Release.Namespace }}.svc.cluster.local:{{ .Values.etcd.service.port }}"
{{- end }}
{{- else }}
{{- toYaml .Values.deployment.etcd.host }}
{{- end }}
{{- end }}
