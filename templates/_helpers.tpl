{{/* -------------------------------------------------------------------------------------------------------------- */}}
{{/* Init Files                                                                                                     */}}
{{/* -------------------------------------------------------------------------------------------------------------- */}}

{{/* Interpolate and generate autoconfig scripts */}}
{{- define "scripts" -}}
{{ range $path, $bytes := $.Files.Glob "files/scripts/**" }}
{{ (tpl ($.Files.Glob $path ).AsConfig $ ) }}
{{ end }}
{{- end -}}

{{/* -------------------------------------------------------------------------------------------------------------- */}}
{{/* Ranger                                                                                                         */}}
{{/* -------------------------------------------------------------------------------------------------------------- */}}

{{- define "ranger.config-checksums" -}}
checksum/datasources: {{ ( include ( print $.Template.BasePath "/config/datasources-secret.yaml" ) . | sha256sum ) }}
checksum/extra-secret: {{ include (print $.Template.BasePath "/extra-secret/extra-secret.yaml") . | sha256sum }}
checksum/init-file: {{ include (print $.Template.BasePath "/initfile/init-file-secret.yaml") . | sha256sum }}
checksum/init-file-scripts: {{ include (print $.Template.BasePath "/initfile/scripts-configmap.yaml") . | sha256sum }}
checksum/registry-secret: {{ include (print $.Template.BasePath "/registry-secret.yaml") . | sha256sum }}
{{- end -}}

{{- define "ranger.datasources-secret.name" -}}
{{- printf "datasources-secret-%s" (include "app.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ranger.datasources" -}}
datasources:
{{- range .Values.datasources }}
  - name: {{ .name }}
    host: {{ .host }}
    port: {{ .port }}
    username: {{ .username }}
    password: {{ .password }}
{{- end }}
{{- end -}}
