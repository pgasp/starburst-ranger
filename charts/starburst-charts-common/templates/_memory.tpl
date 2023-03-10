{{/*
Helper template to convert memory limits to value in kilobytes, for setting Java heap size.
*/}}
{{- define "memory-to-kb" -}}
{{- $val := . -}}
{{- if (hasSuffix "Gi" $val) -}}
{{- printf "%d" (mul (trimAll "Gi" $val) 1048576) -}}
{{- else if (hasSuffix "Mi" $val) -}}
{{- printf "%d" (mul (trimAll "Mi" $val) 1024) -}}
{{- else -}}
{{- fail (printf "Cannot parse memory allocation value %s, expected Gi or Mi suffix" $val) -}}
{{- end -}}
{{- end }}
