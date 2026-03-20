{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "apisix.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "apisix.fullname" -}}
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
{{- define "apisix.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "apisix.labels" -}}
helm.sh/chart: {{ include "apisix.chart" . }}
{{ include "apisix.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "apisix.selectorLabels" -}}
{{- if .Values.gateway.labelsOverride }}
{{- tpl (.Values.gateway.labelsOverride | toYaml) . }}
{{- else }}
app.kubernetes.io/name: {{ include "apisix.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "apisix.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "apisix.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Renders a value that contains template.
Usage:
{{ include "apisix.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "apisix.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{- define "apisix.basePluginAttrs" -}}
{{- if .Values.serviceMonitor.enabled }}
prometheus:
  export_addr:
    ip: 0.0.0.0
    port: {{ .Values.serviceMonitor.containerPort }}
  export_uri: {{ .Values.serviceMonitor.path }}
  metric_prefix: {{ .Values.serviceMonitor.metricPrefix }}
{{- end }}
{{- end -}}

{{- define "apisix.pluginAttrs" -}}
{{- merge .Values.pluginAttrs (include "apisix.basePluginAttrs" . | fromYaml) | toYaml -}}
{{- end -}}

{{/*
Scheme to use while connecting etcd
*/}}
{{- define "apisix.etcd.auth.scheme" -}}
{{- if .Values.etcd.auth.tls.enabled }}
{{- "https" }}
{{- else }}
{{- "http" }}
{{- end }}
{{- end }}

{{/*
Expand a port value (which may contain a port range) into a list of individual
port numbers for K8s resource definitions.
Input: a string like "2000-2100" or "127.0.0.1:2000-2100" or "9100"
Output: JSON {"ports": [2000, 2001, ..., 2100]}
*/}}
{{- define "gateway.expandPorts" -}}
{{- $result := list -}}
{{- $s := . | toString -}}
{{- $portPart := splitList ":" $s | last -}}
{{- if contains "-" $portPart -}}
  {{- $bounds := splitList "-" $portPart -}}
  {{- $start := index $bounds 0 | trim | int -}}
  {{- $end := index $bounds 1 | trim | int -}}
  {{- if gt $start $end -}}
    {{- $tmp := $start -}}
    {{- $start = $end -}}
    {{- $end = $tmp -}}
  {{- end -}}
  {{- $count := add1 (sub $end $start) | int -}}
  {{- range $i := until $count -}}
    {{- $result = append $result (add $start $i | int) -}}
  {{- end -}}
{{- else -}}
  {{- $result = append $result ($portPart | trim | int) -}}
{{- end -}}
{{- dict "ports" $result | toJson -}}
{{- end -}}

{{/*
Normalize a TCP port list into expanded individual port entries for K8s resources.
Handles integers, strings (with ranges), and map entries (with addr ranges).
Input: the .tcp array from values
Output: JSON {"entries": [{"port": 9100, "nodePort": ""}, ...]}
*/}}
{{- define "gateway.normalizedTcpPorts" -}}
{{- $result := list -}}
{{- range $item := . -}}
  {{- $addrStr := "" -}}
  {{- $nodePort := "" -}}
  {{- if kindIs "map" $item -}}
    {{- $addrStr = $item.addr | toString -}}
    {{- if hasKey $item "nodePort" -}}
      {{- $nodePort = $item.nodePort | toString -}}
    {{- end -}}
  {{- else -}}
    {{- $addrStr = $item | toString -}}
  {{- end -}}
  {{- $portPart := splitList ":" $addrStr | last -}}
  {{- if or (contains "," $addrStr) (contains "-" $portPart) -}}
    {{- $expanded := include "gateway.expandPorts" $addrStr | fromJson -}}
    {{- range $port := $expanded.ports -}}
      {{- $result = append $result (dict "port" $port "nodePort" "") -}}
    {{- end -}}
  {{- else -}}
    {{- $result = append $result (dict "port" ($portPart | int) "nodePort" $nodePort) -}}
  {{- end -}}
{{- end -}}
{{- dict "entries" $result | toJson -}}
{{- end -}}

{{/*
Normalize a UDP port list into expanded individual port entries for K8s resources.
Input: the .udp array from values
Output: JSON {"entries": [{"port": 9200, "nodePort": ""}, ...]}
*/}}
{{- define "gateway.normalizedUdpPorts" -}}
{{- $result := list -}}
{{- range $item := . -}}
  {{- $addrStr := "" -}}
  {{- $nodePort := "" -}}
  {{- if kindIs "map" $item -}}
    {{- $addrStr = $item.addr | toString -}}
    {{- if hasKey $item "nodePort" -}}
      {{- $nodePort = $item.nodePort | toString -}}
    {{- end -}}
  {{- else -}}
    {{- $addrStr = $item | toString -}}
  {{- end -}}
  {{- $portPart := splitList ":" $addrStr | last -}}
  {{- if or (contains "," $addrStr) (contains "-" $portPart) -}}
    {{- $expanded := include "gateway.expandPorts" $addrStr | fromJson -}}
    {{- range $port := $expanded.ports -}}
      {{- $result = append $result (dict "port" $port "nodePort" "") -}}
    {{- end -}}
  {{- else -}}
    {{- $result = append $result (dict "port" ($portPart | int) "nodePort" $nodePort) -}}
  {{- end -}}
{{- end -}}
{{- dict "entries" $result | toJson -}}
{{- end -}}
