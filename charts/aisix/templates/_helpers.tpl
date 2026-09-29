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
The directory the chart-rendered startup config is mounted in and the file the
gateway reads from it; the standalone resources file; and the control-plane
mTLS bundle. Each lives under its own directory so no mount shadows the image's
own /etc/aisix/config.managed.yaml.
*/}}
{{- define "aisix.configDir" -}}/etc/aisix/chart{{- end }}
{{- define "aisix.configPath" -}}{{ include "aisix.configDir" . }}/config.yaml{{- end }}
{{- define "aisix.cpCertDir" -}}/etc/aisix/cp-mtls{{- end }}
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

"aisix.proxyListenersJson" builds the `proxy.listeners` list of the rendered
config file, as JSON. The gateway reads TLS material from files, so each TLS
listener points at the directory its Secret is mounted in.
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
"aisix.configPathSet" prints "true" when the dotted path .path is set to a
non-null value in the map .cfg.
*/}}
{{- define "aisix.configPathSet" -}}
{{- $cur := .cfg }}
{{- $found := true }}
{{- range (splitList "." .path) }}
{{- if and $found (kindIs "map" $cur) (hasKey $cur .) }}
{{- $cur = get $cur . }}
{{- else }}
{{- $found = false }}
{{- end }}
{{- end }}
{{- if and $found (not (kindIs "invalid" $cur)) }}true{{ end }}
{{- end }}

{{/*
"aisix.configDottedKey" prints the first key under .cfg (recursively, prefixed
by .at) that contains a `.`. `config` is nested maps; a literal
`cache.redis.password` key would slip past the path checks below.
*/}}
{{- define "aisix.configDottedKey" -}}
{{- $at := .at }}
{{- range $k, $v := .cfg }}
{{- if contains "." $k }}{{ printf "%s%s" $at $k }}{{ end }}
{{- if kindIs "map" $v }}{{ include "aisix.configDottedKey" (dict "cfg" $v "at" (printf "%s%s." $at $k)) }}{{ end }}
{{- end }}
{{- end }}

{{/*
"aisix.dropNulls" deletes every null-valued key from a map, recursively, so a
null in `config` means "leave it to the gateway's default".
*/}}
{{- define "aisix.dropNulls" -}}
{{- $m := . }}
{{- range $k, $v := $m }}
{{- if kindIs "invalid" $v }}
{{- $_ := unset $m $k }}
{{- else if kindIs "map" $v }}
{{- include "aisix.dropNulls" $v }}
{{- end }}
{{- end }}
{{- end }}

{{/*
"aisix.ensureMap" makes .parent[.key] a map when it
is absent or null, so a chart-owned key can be set beneath it.
*/}}
{{- define "aisix.ensureMap" -}}
{{- if not (kindIs "map" (get .parent .key)) }}
{{- $_ := set .parent .key dict }}
{{- end }}
{{- end }}

{{/*
The gateway startup config file: the user's `config` block with the chart-owned
keys filled in for the mode. Keys the chart owns or that hold a credential are
rejected by "aisix.validateValues" before this runs.
*/}}
{{- define "aisix.configFile" -}}
{{- $cfg := deepCopy (.Values.config | default dict) }}
{{- range $section := list "proxy" "observability" "ratelimit" }}
{{- include "aisix.ensureMap" (dict "parent" $cfg "key" $section) }}
{{- end }}
{{- $_ := set $cfg.proxy "addr" (printf "0.0.0.0:%d" (int .Values.containerPorts.proxy)) }}
{{- if .Values.listeners }}
{{- $_ := set $cfg.proxy "listeners" (include "aisix.proxyListenersJson" . | fromJsonArray) }}
{{- end }}
{{- include "aisix.ensureMap" (dict "parent" $cfg.observability "key" "metrics") }}
{{- include "aisix.ensureMap" (dict "parent" $cfg.observability.metrics "key" "prometheus") }}
{{- $_ := set $cfg.observability.metrics.prometheus "addr" (printf "0.0.0.0:%d" (int .Values.containerPorts.metrics)) }}
{{- $_ := set $cfg.ratelimit "backend" .Values.rateLimit.backend }}
{{- if .Values.controlPlane.enabled }}
{{- include "aisix.ensureMap" (dict "parent" $cfg "key" "etcd") }}
{{- include "aisix.ensureMap" (dict "parent" $cfg "key" "managed") }}
{{- /* Overwritten at boot from the control-plane connection, but required. */}}
{{- $_ := set $cfg.etcd "endpoints" (list "https://placeholder-overridden-at-register:2379") }}
{{- $_ := set $cfg.etcd "prefix" "/aisix" }}
{{- /* Never bound in control-plane mode; validation requires the slot. */}}
{{- $_ := set $cfg "admin" (dict "addr" "127.0.0.1:0" "admin_keys" (list "managed-mode-admin-disabled")) }}
{{- $_ := set $cfg.managed "enabled" true }}
{{- $_ := set $cfg.managed "cp_base_url" .Values.controlPlane.baseURL }}
{{- with .Values.controlPlane.etcdEndpoint }}
{{- $_ := set $cfg.managed "cp_etcd_endpoint" . }}
{{- end }}
{{- $_ := set $cfg.managed "heartbeat_interval_secs" (int .Values.controlPlane.heartbeatIntervalSeconds) }}
{{- if not (include "aisix.cpPemFromEnv" .) }}
{{- $dir := include "aisix.cpCertDir" . }}
{{- $_ := set $cfg.managed "cp_cert_file" (printf "%s/cert.pem" $dir) }}
{{- $_ := set $cfg.managed "cp_key_file" (printf "%s/key.pem" $dir) }}
{{- $_ := set $cfg.managed "cp_ca_file" (printf "%s/ca.pem" $dir) }}
{{- end }}
{{- else }}
{{- $_ := unset $cfg "etcd" }}
{{- $_ := unset $cfg "managed" }}
{{- $_ := set $cfg "resources_file" (include "aisix.standaloneResourcesPath" .) }}
{{- if include "aisix.adminEnabled" . }}
{{- /* The keys arrive as AISIX_ADMIN__ADMIN_KEYS from a Secret, never in this file. */}}
{{- $_ := set $cfg "admin" (dict "enabled" true "addr" (printf "0.0.0.0:%d" (int .Values.containerPorts.admin))) }}
{{- else }}
{{- $_ := set $cfg "admin" (dict "enabled" false) }}
{{- end }}
{{- end }}
{{- include "aisix.dropNulls" $cfg }}
{{- toYaml $cfg }}
{{- end }}

{{/*
"aisix.cpPemFromEnv" is non-empty when `extraEnvVars` sets one of the
AISIX_MANAGED__CP_*_PEM variables — a setup from before the chart mounted the
bundle as files. The gateway rejects a PEM and a file for the same slot, so
such a release keeps the 1.5.0 wiring: all three PEMs as environment variables
from the bundle Secret (which extraEnvVars then overrides), and no file keys.
*/}}
{{- define "aisix.cpPemFromEnv" -}}
{{- range .Values.extraEnvVars }}
{{- if has .name (list "AISIX_MANAGED__CP_CERT_PEM" "AISIX_MANAGED__CP_KEY_PEM" "AISIX_MANAGED__CP_CA_PEM") }}true{{ end }}
{{- end }}
{{- end }}

{{/*
The gateway container's env: the chart's own variables, then `extraEnvVars`,
whose entries win on a repeated name. The chart leaves out its own entry for a
name `extraEnvVars` also sets — a repeated name breaks `helm upgrade` after a
rollback ("order in patch list") and is refused by server-side apply — except
for the names chart 1.5.0 rendered ("aisix.env150"). A 1.5.0 release that
overrides one of those carries the name twice, and an upgrade whose manifest
carries it once deletes both entries, the override included. For those names
the chart keeps rendering its entry ahead of the override, with the value 1.5.0
gave it where the chart no longer sets it.
*/}}
{{- define "aisix.env" -}}
{{- $chart := list (dict "name" "AISIX_CONFIG_PATH" "value" (include "aisix.configPath" .)) }}
{{- if and .Values.controlPlane.enabled (include "aisix.cpPemFromEnv" .) }}
{{- range $slot, $key := dict "CERT" .Values.controlPlane.certificate.certKey "KEY" .Values.controlPlane.certificate.keyKey "CA" .Values.controlPlane.certificate.caKey }}
{{- $chart = append $chart (dict "name" (printf "AISIX_MANAGED__CP_%s_PEM" $slot) "valueFrom" (dict "secretKeyRef" (dict "name" (include "aisix.certSecretName" $) "key" $key))) }}
{{- end }}
{{- end }}
{{- if and (eq .Values.rateLimit.backend "redis") (or .Values.rateLimit.redis.url .Values.rateLimit.redis.existingSecret) }}
{{- $chart = append $chart (dict "name" "AISIX_RATELIMIT__REDIS__URL" "valueFrom" (dict "secretKeyRef" (dict "name" (include "aisix.redisSecretName" .) "key" (include "aisix.redisSecretKey" .)))) }}
{{- end }}
{{- if include "aisix.adminEnabled" . }}
{{- $chart = append $chart (dict "name" "AISIX_ADMIN__ADMIN_KEYS" "valueFrom" (dict "secretKeyRef" (dict "name" (include "aisix.adminSecretName" .) "key" (include "aisix.adminSecretKey" .)))) }}
{{- end }}
{{- range $path, $ref := (.Values.configSecrets | default dict) }}
{{- $chart = append $chart (dict "name" (include "aisix.configSecretEnvName" $path) "valueFrom" (dict "secretKeyRef" (dict "name" $ref.secretName "key" $ref.key))) }}
{{- end }}
{{- $extra := .Values.extraEnvVars | default list }}
{{- $overridden := list }}
{{- range $extra }}
{{- $overridden = append $overridden .name }}
{{- end }}
{{- $legacy := include "aisix.env150" . | fromYamlArray }}
{{- $legacyNames := list }}
{{- range $legacy }}
{{- $legacyNames = append $legacyNames .name }}
{{- end }}
{{- $env := list }}
{{- $chartNames := list }}
{{- range $chart }}
{{- $chartNames = append $chartNames .name }}
{{- if or (not (has .name $overridden)) (has .name $legacyNames) }}
{{- $env = append $env . }}
{{- end }}
{{- end }}
{{- range $legacy }}
{{- if and (has .name $overridden) (not (has .name $chartNames)) }}
{{- $env = append $env . }}
{{- end }}
{{- end }}
{{- toYaml (concat $env $extra) }}
{{- end }}

{{/*
"aisix.env150" is the env list chart 1.5.0 rendered for these values — the
names "aisix.env" must not drop while an older release may still carry them
twice. Only the entries the chart no longer renders use these values.
*/}}
{{- define "aisix.env150" -}}
{{- $env := list (dict "name" "AISIX_CONFIG_PATH" "value" (ternary "/etc/aisix/config.managed.yaml" "/etc/aisix/standalone/config.yaml" .Values.controlPlane.enabled)) }}
{{- $env = append $env (dict "name" "AISIX_PROXY__ADDR" "value" (printf "0.0.0.0:%d" (int .Values.containerPorts.proxy))) }}
{{- if .Values.listeners }}
{{- $env = append $env (dict "name" "AISIX_PROXY__LISTENERS" "value" (include "aisix.proxyListenersJson" .)) }}
{{- end }}
{{- $env = append $env (dict "name" "AISIX_OBSERVABILITY__METRICS__PROMETHEUS__ADDR" "value" (printf "0.0.0.0:%d" (int .Values.containerPorts.metrics))) }}
{{- if .Values.controlPlane.enabled }}
{{- $env = append $env (dict "name" "AISIX_MANAGED__CP_BASE_URL" "value" .Values.controlPlane.baseURL) }}
{{- with .Values.controlPlane.etcdEndpoint }}
{{- $env = append $env (dict "name" "AISIX_MANAGED__CP_ETCD_ENDPOINT" "value" .) }}
{{- end }}
{{- $env = append $env (dict "name" "AISIX_MANAGED__HEARTBEAT_INTERVAL_SECS" "value" (toString .Values.controlPlane.heartbeatIntervalSeconds)) }}
{{- range $slot, $key := dict "CERT" .Values.controlPlane.certificate.certKey "KEY" .Values.controlPlane.certificate.keyKey "CA" .Values.controlPlane.certificate.caKey }}
{{- $env = append $env (dict "name" (printf "AISIX_MANAGED__CP_%s_PEM" $slot) "valueFrom" (dict "secretKeyRef" (dict "name" (include "aisix.certSecretName" $) "key" $key))) }}
{{- end }}
{{- end }}
{{- /* 1.5.0 refused a Redis backend without one of these. */}}
{{- if and (eq .Values.rateLimit.backend "redis") (or .Values.rateLimit.redis.url .Values.rateLimit.redis.existingSecret) }}
{{- $env = append $env (dict "name" "AISIX_RATELIMIT__BACKEND" "value" "redis") }}
{{- $env = append $env (dict "name" "AISIX_RATELIMIT__REDIS__URL" "valueFrom" (dict "secretKeyRef" (dict "name" (include "aisix.redisSecretName" .) "key" (include "aisix.redisSecretKey" .)))) }}
{{- end }}
{{- toYaml $env }}
{{- end }}

{{/*
The environment variable the gateway reads a `configSecrets` path from:
AISIX_ plus the path upper-cased with `.` as `__`.
*/}}
{{- define "aisix.configSecretEnvName" -}}
AISIX_{{ . | upper | replace "." "__" }}
{{- end }}

{{/*
"aisix.adminEnabled" is non-empty when the chart deploys the Admin API.
`admin` may be absent under `helm upgrade --reuse-values` from an older chart.
*/}}
{{- define "aisix.adminEnabled" -}}
{{- if (.Values.admin | default dict).enabled }}true{{ end }}
{{- end }}

{{- define "aisix.adminSecretName" -}}
{{- .Values.admin.existingSecret | default (printf "%s-admin" (include "aisix.fullname" .)) }}
{{- end }}

{{- define "aisix.adminSecretKey" -}}
{{- if .Values.admin.existingSecret }}{{ .Values.admin.existingSecretKey | default "admin-keys" }}{{ else }}admin-keys{{ end }}
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
{{- if include "aisix.adminEnabled" . }}
{{- if .Values.controlPlane.enabled }}
{{- fail "admin.enabled requires controlPlane.enabled=false: a gateway connected to a control plane has no Admin API" }}
{{- end }}
{{- if not (or .Values.admin.existingSecret .Values.admin.keys) }}
{{- fail "admin.enabled requires admin keys: set admin.keys, or admin.existingSecret holding them" }}
{{- end }}
{{- range .Values.admin.keys }}
{{- if or (not .) (contains "," (toString .)) }}
{{- fail "admin.keys entries must be non-empty and cannot contain a comma: the gateway reads the list comma-separated" }}
{{- end }}
{{- end }}
{{- end }}
{{- if and .Values.autoscaling.enabled .Values.keda.enabled }}
{{- fail "autoscaling.enabled and keda.enabled are mutually exclusive: two controllers writing spec.replicas fight over the replica count" }}
{{- end }}
{{- if and .Values.keda.enabled (not .Values.keda.triggers) }}
{{- fail "keda.enabled requires at least one entry in keda.triggers" }}
{{- end }}
{{- $config := .Values.config | default dict }}
{{- if eq .Values.rateLimit.backend "redis" }}
{{- $mode := "single" }}
{{- if kindIs "map" $config.ratelimit }}{{ if kindIs "map" $config.ratelimit.redis }}{{ $mode = $config.ratelimit.redis.mode | default "single" }}{{ end }}{{ end }}
{{- if and (eq $mode "single") (not (or .Values.rateLimit.redis.url .Values.rateLimit.redis.existingSecret)) }}
{{- fail "rateLimit.backend=redis requires rateLimit.redis.url or rateLimit.redis.existingSecret" }}
{{- end }}
{{- end }}
{{- with include "aisix.configDottedKey" (dict "cfg" $config "at" "") }}
{{- fail (printf "config key %q contains a dot: write config as nested maps, e.g. cache: {redis: {mode: single}}" .) }}
{{- end }}
{{- $policy := .Files.Get "config-policy.yaml" | fromYaml }}
{{- range $path, $use := $policy.owned }}
{{- if include "aisix.configPathSet" (dict "cfg" $config "path" $path) }}
{{- fail (printf "config.%s is set by the chart and cannot be written under config: %s" $path $use) }}
{{- end }}
{{- end }}
{{- range $path := $policy.secrets }}
{{- if include "aisix.configPathSet" (dict "cfg" $config "path" $path) }}
{{- fail (printf "config.%s holds a credential and is never written to the ConfigMap: set it through configSecrets.%s with a secretName and key" $path $path) }}
{{- end }}
{{- end }}
{{- range $path, $ref := (.Values.configSecrets | default dict) }}
{{- if not (has $path $policy.secrets) }}
{{- fail (printf "configSecrets.%s is not a credential-bearing setting; accepted keys: %s" $path (join ", " $policy.secrets)) }}
{{- end }}
{{- if not (and (kindIs "map" $ref) $ref.secretName $ref.key) }}
{{- fail (printf "configSecrets.%s requires secretName and key" $path) }}
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
