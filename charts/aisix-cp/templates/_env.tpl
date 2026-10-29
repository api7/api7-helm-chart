{{/*
A container's env list. Arguments:
  chart   the entries the chart renders now (a rendered YAML list)
  extra   the component's extraEnvVars, emitted last, verbatim and in order

When extraEnvVars sets a name the chart also renders, the chart's entry is
omitted: a duplicate env name breaks `helm rollback` followed by an
env-changing upgrade and is rejected by Helm 4's server-side apply. Unless
something between the two, or the override itself, expands `$(NAME)`: the
kubelet resolves a reference only against entries defined earlier, so it
has always resolved to the chart's value, and the entry stays so that it
still does.

Either way the user's later entry is the one that takes effect.
*/}}
{{- define "aisix-cp.env" -}}
{{- $chart := .chart | fromYamlArray }}
{{- $extra := .extra | default list }}
{{- $userNames := dict }}
{{- range $extra }}
{{- $_ := set $userNames .name true }}
{{- end }}
{{- $all := concat $chart $extra }}
{{- $out := list }}
{{- range $i, $entry := $chart }}
{{- $keep := true }}
{{- if hasKey $userNames $entry.name }}
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
{{- with concat $out $extra }}
{{- toYaml . }}
{{- end }}
{{- end }}
