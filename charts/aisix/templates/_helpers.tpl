{{/*
Expand the name of the chart.
*/}}
{{- define "aisix.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
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
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: aisix
{{- end }}

{{/*
Selector labels
*/}}
{{- define "aisix.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aisix.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: gateway
{{- end }}

{{/*
ServiceAccount name.
*/}}
{{- define "aisix.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "aisix.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image pull secrets.
*/}}
{{- define "aisix.imagePullSecrets" -}}
{{- with .Values.global.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Name of the Secret holding the gateway certificate bundle.
*/}}
{{- define "aisix.certSecretName" -}}
{{- if .Values.controlPlane.certificate.existingSecret }}
{{- .Values.controlPlane.certificate.existingSecret }}
{{- else }}
{{- printf "%s-mtls" (include "aisix.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Name of the Secret holding the rate-limit Redis URL.
*/}}
{{- define "aisix.redisSecretName" -}}
{{- if .Values.rateLimit.redis.existingSecret }}
{{- .Values.rateLimit.redis.existingSecret }}
{{- else }}
{{- printf "%s-ratelimit" (include "aisix.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Secret key holding the rate-limit Redis URL.
*/}}
{{- define "aisix.redisSecretKey" -}}
{{- if .Values.rateLimit.redis.existingSecret }}
{{- .Values.rateLimit.redis.existingSecretKey | default "redis-url" }}
{{- else }}
{{- "redis-url" }}
{{- end }}
{{- end }}

{{/*
Reject value combinations that render successfully but cannot run.
*/}}
{{- define "aisix.validateValues" -}}
{{- if not .Values.controlPlane.baseURL }}
{{- fail "controlPlane.baseURL is required: set it to the data-plane manager endpoint shown in the control plane's Data planes view" }}
{{- end }}
{{- if not .Values.controlPlane.certificate.existingSecret }}
{{- if not (and .Values.controlPlane.certificate.cert .Values.controlPlane.certificate.key .Values.controlPlane.certificate.ca) }}
{{- fail "a gateway certificate bundle is required: set controlPlane.certificate.existingSecret, or all three of controlPlane.certificate.{cert,key,ca}" }}
{{- end }}
{{- end }}
{{- if and .Values.autoscaling.enabled .Values.keda.enabled }}
{{- fail "autoscaling.enabled and keda.enabled are mutually exclusive: two controllers writing spec.replicas fight over the replica count" }}
{{- end }}
{{- if and .Values.keda.enabled (not .Values.keda.triggers) }}
{{- fail "keda.enabled requires at least one entry in keda.triggers" }}
{{- end }}
{{- if eq .Values.rateLimit.backend "redis" }}
{{- if not (or .Values.rateLimit.redis.url .Values.rateLimit.redis.existingSecret) }}
{{- fail "rateLimit.backend=redis requires rateLimit.redis.url or rateLimit.redis.existingSecret" }}
{{- end }}
{{- end }}
{{- end }}
