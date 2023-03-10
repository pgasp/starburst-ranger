{{/*
Generate common deployments selectors
*/}}
{{- define "app.selectorLabels" -}}
app: {{ .Chart.Name }}
helm-release: {{ .Release.Name }}
{{- end -}}

{{/*
Generate common deployments header
*/}}
{{- define "app.labels" -}}
{{- include "app.selectorLabels" . }}
helm-chart: {{ include "app.chart" . }}
managed-by: {{ .Release.Service }}
{{- if .Values.commonLabels}}
{{ toYaml .Values.commonLabels }}
{{- end }}
{{- end -}}

