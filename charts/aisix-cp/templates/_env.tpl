{{/*
A container's env list. Arguments:
  chart   the entries the chart renders now (a rendered YAML list)
  legacy  the entries chart 1.5.0 rendered ("aisix-cp.legacyEnv.<component>")
  extra   the component's extraEnvVars, emitted last, verbatim and in order

When extraEnvVars sets a name the chart also renders, what happens to the
chart's entry depends on whether 1.5.0 rendered that name:

- It did: the chart still emits an entry before the user's — its current one,
  or, for a name that moved into the config file, the 1.5.0 entry. A 1.5.0
  install carries that name twice, and an upgrade that renders it fewer times
  loses the user's override (see _legacy-env.tpl).
- It did not: the chart's entry is omitted. A duplicate env name breaks
  `helm rollback` followed by an env-changing upgrade and is rejected by
  Helm 4's server-side apply. Unless something between the two, or the
  override itself, expands `$(NAME)`: the kubelet resolves a reference only against entries defined
  earlier, so it has always resolved to the chart's value, and the entry
  stays so that it still does.

Either way the user's later entry is the one that takes effect, exactly as
before.
*/}}
{{- define "aisix-cp.env" -}}
{{- $chart := .chart | fromYamlArray }}
{{- $extra := .extra | default list }}
{{- $legacy := .legacy | fromYamlArray }}
{{- $legacyNames := dict }}
{{- range $legacy }}
{{- $_ := set $legacyNames .name true }}
{{- end }}
{{- $chartNames := dict }}
{{- range $chart }}
{{- $_ := set $chartNames .name true }}
{{- end }}
{{- $userNames := dict }}
{{- range $extra }}
{{- $_ := set $userNames .name true }}
{{- end }}
{{- $moved := list }}
{{- range $legacy }}
{{- if and (hasKey $userNames .name) (not (hasKey $chartNames .name)) }}
{{- $moved = append $moved . }}
{{- end }}
{{- end }}
{{- $all := concat $chart $moved $extra }}
{{- $out := list }}
{{- range $i, $entry := $chart }}
{{- $keep := true }}
{{- if and (hasKey $userNames $entry.name) (not (hasKey $legacyNames $entry.name)) }}
{{- $override := 0 }}
{{- range $j, $e := $all }}
{{- if and (eq $override 0) (gt $j $i) (eq $e.name $entry.name) }}
{{- $override = $j }}
{{- end }}
{{- end }}
{{- $keep = false }}
{{- $ref := printf "$(%s)" $entry.name }}
{{- range slice $all (add1 $i) (add1 $override) }}
{{- if contains $ref (toString (.value | default "")) }}
{{- $keep = true }}
{{- end }}
{{- end }}
{{- end }}
{{- if $keep }}
{{- $out = append $out $entry }}
{{- end }}
{{- end }}
{{- with concat $out $moved $extra }}
{{- toYaml . }}
{{- end }}
{{- end }}
