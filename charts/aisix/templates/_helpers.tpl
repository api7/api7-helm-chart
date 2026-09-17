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
Standalone mode: the directory the startup config is mounted in, the file the
gateway reads from it, and the resources file it points at. Both live under
their own directory so neither mount shadows the image's own
/etc/aisix/config.managed.yaml.
*/}}
{{- define "aisix.standaloneConfigDir" -}}/etc/aisix/standalone{{- end }}
{{- define "aisix.standaloneConfigPath" -}}{{ include "aisix.standaloneConfigDir" . }}/config.yaml{{- end }}
{{- define "aisix.standaloneResourcesDir" -}}/etc/aisix/resources{{- end }}
{{- define "aisix.standaloneResourcesPath" -}}{{ include "aisix.standaloneResourcesDir" . }}/resources.yaml{{- end }}

{{/*
Name of the Secret or ConfigMap holding resources.yaml.
*/}}
{{- define "aisix.resourcesObjectName" -}}
{{- if .Values.standalone.existingSecret }}
{{- .Values.standalone.existingSecret }}
{{- else if .Values.standalone.existingConfigMap }}
{{- .Values.standalone.existingConfigMap }}
{{- else }}
{{- printf "%s-resources" (include "aisix.fullname" .) }}
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
Multiple proxy listeners.

`listeners` empty is the single-listener default and every one of these is
inert, so a default render is unchanged.

"aisix.proxyPortName" is the port the probes target: the first listener, or
the built-in "proxy" port.

"aisix.proxyListenerTLS" is non-empty when that first listener terminates TLS,
so the probes know to speak HTTPS to it.

"aisix.proxyListenersJson" builds the AISIX_PROXY__LISTENERS value. The gateway
takes the whole list as one JSON document — indexed environment variables are
not a form it accepts — and reads TLS material from files, so each TLS listener
points at the directory its Secret is mounted in.
*/}}
{{- define "aisix.proxyPortName" -}}
{{- if .Values.listeners }}{{ (first .Values.listeners).name }}{{ else }}proxy{{ end }}
{{- end }}

{{- define "aisix.proxyListenerTLSDir" -}}/etc/aisix/tls/{{ .name }}{{- end }}

{{- define "aisix.proxyListenerTLS" -}}
{{- if .Values.listeners }}
{{- with (first .Values.listeners).tls }}{{ if .secretName }}true{{ end }}{{ end }}
{{- end }}
{{- end }}

{{- define "aisix.proxyListenersJson" -}}
{{- $listeners := list }}
{{- range $listener := .Values.listeners }}
{{- $entry := dict "addr" (printf "0.0.0.0:%d" (int $listener.containerPort)) }}
{{- if $listener.tls }}
{{- if $listener.tls.secretName }}
{{- $dir := include "aisix.proxyListenerTLSDir" $listener }}
{{- $_ := set $entry "tls" (dict "cert_file" (printf "%s/tls.crt" $dir) "key_file" (printf "%s/tls.key" $dir)) }}
{{- end }}
{{- end }}
{{- $listeners = append $listeners $entry }}
{{- end }}
{{- toJson $listeners }}
{{- end }}

{{/*
Reject value combinations that render successfully but cannot run.
*/}}
{{- define "aisix.validateValues" -}}
{{- if .Values.controlPlane.enabled }}
{{- if not .Values.controlPlane.baseURL }}
{{- fail "controlPlane.baseURL is required: set it to the data-plane manager endpoint shown in the control plane's Data planes view (or set controlPlane.enabled=false to run standalone)" }}
{{- end }}
{{- if not .Values.controlPlane.certificate.existingSecret }}
{{- if not (and .Values.controlPlane.certificate.cert .Values.controlPlane.certificate.key .Values.controlPlane.certificate.ca) }}
{{- fail "a gateway certificate bundle is required: set controlPlane.certificate.existingSecret, or all three of controlPlane.certificate.{cert,key,ca}" }}
{{- end }}
{{- end }}
{{- else }}
{{- $sources := 0 }}
{{- if .Values.standalone.resources }}{{ $sources = add1 $sources }}{{ end }}
{{- if .Values.standalone.existingSecret }}{{ $sources = add1 $sources }}{{ end }}
{{- if .Values.standalone.existingConfigMap }}{{ $sources = add1 $sources }}{{ end }}
{{- if ne $sources 1 }}
{{- fail "controlPlane.enabled=false requires exactly one resource source: standalone.resources, standalone.existingSecret, or standalone.existingConfigMap" }}
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
{{- $names := list }}
{{- $ports := list }}
{{- range $i, $listener := .Values.listeners }}
{{- if not $listener.name }}
{{- fail (printf "listeners[%d].name is required: it names both the container port and the Service port" $i) }}
{{- end }}
{{- if not $listener.containerPort }}
{{- fail (printf "listeners[%d] (%s) requires containerPort" $i $listener.name) }}
{{- end }}
{{- if not $listener.servicePort }}
{{- fail (printf "listeners[%d] (%s) requires servicePort" $i $listener.name) }}
{{- end }}
{{- if has $listener.name $names }}
{{- fail (printf "listeners[%d]: duplicate name %s — listener names must be unique" $i $listener.name) }}
{{- end }}
{{- if has (int $listener.containerPort) $ports }}
{{- fail (printf "listeners[%d] (%s): duplicate containerPort %d — the gateway rejects two listeners on one address" $i $listener.name (int $listener.containerPort)) }}
{{- end }}
{{- $names = append $names $listener.name }}
{{- $ports = append $ports (int $listener.containerPort) }}
{{- end }}
{{- end }}
