{{/* -------------------------------------------------------------------------------------------------------------- */}}
{{/* Docker Registry                                                                                                */}}
{{/* -------------------------------------------------------------------------------------------------------------- */}}

{{/*
Generate Docker registry secret name
*/}}
{{- define "app.registry-secret.name" -}}
{{- printf "registry-secret-%s" (include "app.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate image pull secret
*/}}
{{- define "app.imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.registryCredentials.registry (printf "%s:%s" .Values.registryCredentials.username .Values.registryCredentials.password | b64enc) | b64enc }}
{{- end }}

{{/*
Select image pull secret
*/}}
{{- define "app.imagePullSecretName" }}
    {{- if and ( .Values.registryCredentials.enabled) ( .Values.imagePullSecrets) }}
        {{- fail (printf "\nInvalid registryCredentials definition: do not pass both registryCredentials and imagePullSecret, select one or another.") }}
    {{- else if .Values.imagePullSecrets }}
        {{- print "imagePullSecrets:" }}
        {{- range .Values.imagePullSecrets }}
            {{- printf "\n  - name: %s" .name}}
        {{- end }}
    {{- else if and ( .Values.registryCredentials.enabled ) ((not .Values.imagePullSecrets)) }}
        {{- print "imagePullSecrets:" }}
        {{- printf "\n  - name: %s" (include "app.registry-secret.name" . ) }}
{{- end }}
{{- end }}


