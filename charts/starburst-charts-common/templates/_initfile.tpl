{{/* -------------------------------------------------------------------------------------------------------------- */}}
{{/* Init Files                                                                                                     */}}
{{/* -------------------------------------------------------------------------------------------------------------- */}}

{{/* Init file secret name */}}
{{- define "app.init-file-secret.name" -}}
{{- printf "init-secret-%s" (include "app.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Init file name used to start application */}}
{{- define "app.initFileName" }}
{{- $parts := ( splitList "/" .Values.initFile ) }}
{{- $partsNo := ( len $parts ) }}
{{- printf "%s" ( index $parts (add $partsNo -1)) }}
{{- end }}
