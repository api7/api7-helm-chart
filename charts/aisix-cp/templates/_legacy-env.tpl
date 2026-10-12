{{/*
The env block each Deployment rendered in chart 1.5.0, under the same
conditions and with the same values — the last release that passed
application settings as env. Nothing renders these lists directly: the
"aisix-cp.env" helper reads their names, and emits one of these entries only
when the component's extraEnvVars sets that name and the current chart no
longer does.

That is what keeps a 1.5.0 install's override across the upgrade. Its
Deployment carries the name twice (the chart's entry, then the user's), and
when the upgraded manifest carries it fewer times, Helm 3's three-way patch
deletes both — the override is lost until a second upgrade puts it back.

Freeze these: they describe a released chart, not the current one.
AISIX_CLOUD_DP_IMAGE is rendered always, because 1.5.0 defaulted api.dpImage
to an image where this chart defaults it to empty; the default here is the
one 1.5.0 carried. At the release-time sync to the public chart it takes the
public 1.5.0 default, docker.io/api7/aisix:1.5.0.
*/}}
{{- define "aisix-cp.legacyEnv.api" -}}
- name: PGPASSWORD
{{- if .Values.twoDSN.enabled }}
- name: SERVING_PGPASSWORD
{{- end }}
- name: AISIX_CLOUD_LISTEN
  value: ":8080"
{{- if .Values.api.metrics.enabled }}
- name: AISIX_CLOUD_METRICS_LISTEN
  value: {{ printf ":%v" .Values.api.metrics.port | quote }}
{{- end }}
{{- if .Values.twoDSN.enabled }}
- name: AISIX_CLOUD_ADMIN_DATABASE_URL
  value: {{ include "aisix-cp.legacyDatabaseURL" . }}
- name: AISIX_CLOUD_DATABASE_URL
  value: postgres://cp_api_app:$(SERVING_PGPASSWORD)@{{ include "aisix-cp.pgHost" . }}:{{ include "aisix-cp.pgPort" . }}/{{ include "aisix-cp.pgDatabase" . }}?sslmode={{ include "aisix-cp.pgSSLMode" . }}
{{- else }}
- name: AISIX_CLOUD_DATABASE_URL
  value: {{ include "aisix-cp.legacyDatabaseURL" . }}
{{- end }}
- name: AISIX_CLOUD_PUBLIC_BASE_URL
  value: {{ .Values.api.publicBaseURL | quote }}
{{- with .Values.api.corsAllowedOrigins }}
- name: AISIX_CLOUD_CORS_ALLOWED_ORIGINS
  value: {{ join "," . | quote }}
{{- end }}
- name: AISIX_CLOUD_MASTER_KEY
- name: AISIX_CLOUD_MASTER_KEY_ID
  value: {{ .Values.secrets.masterKeyID | quote }}
- name: AISIX_CLOUD_DASHBOARD_URL
  value: "http://{{ include "aisix-cp.fullname" . }}-ui:{{ .Values.ui.service.port }}"
{{- if .Values.api.dpmgrBaseURL }}
- name: AISIX_CLOUD_DPMGR_BASE_URL
  value: {{ .Values.api.dpmgrBaseURL | quote }}
{{- end }}
- name: AISIX_CLOUD_OAUTH_ENABLED
  value: {{ .Values.api.oauthEnabled | quote }}
{{- if .Values.api.playgroundAllowPrivateIPs }}
- name: AISIX_PLAYGROUND_ALLOW_PRIVATE_IPS
  value: "1"
{{- end }}
{{- if .Values.api.notifyAllowPrivateURLs }}
- name: AISIX_CLOUD_NOTIFY_ALLOW_PRIVATE_URLS
  value: "true"
{{- end }}
- name: AISIX_CLOUD_DP_IMAGE
  value: {{ .Values.api.dpImage | default "docker.io/api7/aisix:1.5.0" | quote }}
{{- end }}

{{- define "aisix-cp.legacyEnv.dpm" -}}
- name: PGPASSWORD
- name: AISIX_DPMGR_LISTEN
  value: ":7944"
- name: AISIX_DPMGR_HEALTH_LISTEN
  value: {{ .Values.dpm.service.healthListen | quote }}
{{- if .Values.api.dpmgrBaseURL }}
- name: AISIX_DPMGR_BASE_URL
  value: {{ .Values.api.dpmgrBaseURL | quote }}
{{- end }}
- name: AISIX_DPMGR_DATABASE_URL
  value: {{ include "aisix-cp.legacyDatabaseURL" . }}
- name: AISIX_DPMGR_MASTER_KEY
- name: AISIX_DPMGR_MASTER_KEY_ID
  value: {{ .Values.secrets.masterKeyID | quote }}
{{- end }}

{{- define "aisix-cp.legacyEnv.ui" -}}
- name: PGPASSWORD
- name: BETTER_AUTH_URL
  value: {{ .Values.api.publicBaseURL | quote }}
- name: BETTER_AUTH_SECRET
- name: AISIX_CLOUD_DATABASE_URL
  value: {{ include "aisix-cp.legacyDatabaseURL" . }}
- name: AISIX_DASHBOARD_LOCALE
  value: {{ .Values.ui.defaultLocale | quote }}
{{- end }}

{{- define "aisix-cp.legacyDatabaseURL" -}}
postgres://{{ include "aisix-cp.pgUser" . }}:$(PGPASSWORD)@{{ include "aisix-cp.pgHost" . }}:{{ include "aisix-cp.pgPort" . }}/{{ include "aisix-cp.pgDatabase" . }}?sslmode={{ include "aisix-cp.pgSSLMode" . }}
{{- end }}
