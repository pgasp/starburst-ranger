{{/* -------------------------------------------------------------------------------------------------------------- */}}
{{/* Resources Config                                                                                               */}}
{{/* -------------------------------------------------------------------------------------------------------------- */}}

{{- define "app.resources" -}}
{{- $resources := . -}}
requests:
  {{- if ( $resources.requests | default dict ).memory }}
  memory: {{ $resources.requests.memory }}
  {{- else if $resources.memory }}
  memory: {{ $resources.memory }}
  {{- end }}
  {{- if ( $resources.requests | default dict ).cpu }}
  cpu: {{ $resources.requests.cpu }}
  {{- else if $resources.cpu }}
  cpu: {{ $resources.cpu }}
  {{- end }}
limits:
  {{- if ( $resources.limits | default dict ).memory }}
  memory: {{ $resources.limits.memory }}
  {{- else if $resources.memory }}
  memory: {{ $resources.memory }}
  {{- end }}
  {{- if ( $resources.limits | default dict ).cpu }}
  cpu: {{ $resources.limits.cpu }}
  {{- else if and (not ( $resources.requests | default dict ).cpu ) ( $resources.cpu ) }}
  cpu: {{ $resources.cpu }}
  {{- end }}
{{- end -}}
