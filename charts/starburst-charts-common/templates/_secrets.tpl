{{/* -------------------------------------------------------------------------------------------------------------- */}}
{{/* Secrets
{{/* -------------------------------------------------------------------------------------------------------------- */}}

{{/* Secret names are valid domain names. But we added extra charactes */}}
{{/* - '/' - to allow reference external secrets using slashes */}}
{{/*  */}}
{{/* This requires removing those slashes in Secret templates name field */}}
{{/* This operation is centralized in "normalizer.secretName" nested template */}}
{{- define "secretNameRegExp" -}}
^[a-z0-9]([-/a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-/a-z0-9]*[a-z0-9])?)*$
{{- end -}}

{{- define "fileNameRegExp" -}}
^[a-zA-Z0-9._-]+$
{{- end -}}

{{- define "envVarNameRegExp" -}}
^[a-zA-Z][a-zA-Z0-9_]*$
{{- end -}}

{{- define "validator.secretName" -}}
{{- if regexMatch (include "secretNameRegExp" .) . -}}
1
{{- end -}}
{{- end -}}

{{- define "validator.fileName" -}}
{{- if regexMatch (include "fileNameRegExp" .) . -}}
1
{{- end -}}
{{- end -}}

{{- define "validator.envVariable" -}}
{{- if regexMatch (include "envVarNameRegExp" .) . -}}
1
{{- end -}}
{{- end -}}

{{/* Secret added possiblity to use slashes in secret names to be compatible */}}
{{/* with popular naming strategy in KeyVaults. This requires cleancing them */}}
{{/* before storing them as K8s Secrets which names need to be valid domains. */}}
{{/* This operation is done in below nested template */}}
{{- define "normalizer.secretName" -}}
{{- regexReplaceAll "/" . "." -}}
{{- end -}}

{{/* Environment variables build from external secrets are build from */}}
{{/* concatenation of secret name and actual property name within secret. */}}
{{/* Thaks to that we avoid overriding same properties from diff. secrets */}}
{{/* This requires cleancing effectiv env. variable name from illegal characters */}}
{{/* it's done in below nested template */}}
{{- define "normalizer.envName" -}}
{{- regexReplaceAll "[-./]" ( upper . ) "_" -}}
{{- end -}}

{{/* -------------------------------------------------------------------------------------------------------------- */}}
{{/* Functions preparing secretRef                                                                                  */}}
{{/* -------------------------------------------------------------------------------------------------------------- */}}

{{- define "app.secretRef.configuration" -}}
{{- $arguments := dict -}}
{{- $_ := set $arguments "helperFunctionResolvePipeline" (dict "config" (get .Values .secretRefConfig)) -}}
{{- $_ := set $arguments "helperFunctionTemplate" "helperFunction.secretRef.generate.configuration" -}}
{{- $_ := set $arguments "helperFunctionName" "secretRef" -}}
{{- include "helperFunction.secretRef.renderer" (dict "Values" $arguments "Template" $.Template) -}}
{{- end -}}

{{- define "app.secretRef.volumes" -}}
{{- $arguments := dict -}}
{{- $_ := set $arguments "helperFunctionResolvePipeline" (dict "config" (get .Values .secretRefConfig)) -}}
{{- $_ := set $arguments "helperFunctionTemplate" "helperFunction.secretRef.generate.volumes" -}}
{{- $_ := set $arguments "helperFunctionName" "secretRef" -}}
{{- include "helperFunction.secretRef.renderer" (dict "Values" $arguments "Template" $.Template) -}}
{{- end -}}

{{- define "app.secretRef.volumesMounts" -}}
{{- $arguments := dict -}}
{{- $_ := set $arguments "helperFunctionResolvePipeline" (dict "config" (get .Values .secretRefConfig)) -}}
{{- $_ := set $arguments "helperFunctionTemplate" "helperFunction.secretRef.generate.volumesMounts" -}}
{{- $_ := set $arguments "helperFunctionName" "secretRef" -}}
{{- include "helperFunction.secretRef.renderer" (dict "Values" $arguments "Template" $.Template) -}}
{{- end -}}

{{/* -------------------------------------------------------------------------------------------------------------- */}}
{{/* Helper functions for secretRef                                                                                 */}}
{{/* -------------------------------------------------------------------------------------------------------------- */}}

{{- define "helperFunction.secretRef.renderer" -}}
{{- $helperFunctionsRemovedComments := regexReplaceAllLiteral "#.*\\n" (toYaml .Values.helperFunctionResolvePipeline) "" -}}
{{- $helperFunctionMatchingRegexp := (printf "%s(:[^ \n]+)*" .Values.helperFunctionName) -}}
{{- $helperFunctionsCalls := regexFindAll $helperFunctionMatchingRegexp $helperFunctionsRemovedComments -1 | uniq -}}
{{- $_ := set . "helperFunctions" list -}}
{{- range $index, $helperFunctionCall := $helperFunctionsCalls -}}
{{- if $helperFunctionCall -}}
{{- $helperFunctionArray := splitList ":" $helperFunctionCall -}}
{{- $valuesCopy := (deepCopy $.Values) -}}
{{- $_ := set $valuesCopy "helperId" $index -}}
{{- $_ := set $valuesCopy "helperType" ( index $helperFunctionArray 0 ) -}}
{{- $_ := set $valuesCopy "helperArguments" ( without $helperFunctionArray $valuesCopy.helperType  ) -}}
{{- $helperDefinition := dict -}}
{{- $_ := set $helperDefinition "Values" $valuesCopy -}}
{{- $_ := set $ "helperFunctions" (append $.helperFunctions $helperDefinition) -}}
{{- end -}}
{{- end -}}
{{- include .Values.helperFunctionTemplate (dict "Values" $.helperFunctions "Template" .Template "Configs" .Values.helperFunctionResolvePipeline) -}}
{{ end -}}

{{- define "helperFunction.secretRef.validation" -}}
{{- $helperArgumentsSize := len $.Values.helperArguments -}}
{{- if not (eq $helperArgumentsSize 2) -}}
{{- fail (printf "\n!!! Invalid HelperFunction definition: secretRef%s !!!\nCause: Not matching to secretRef:<<secret_name>>:<<secret_key>>" $.Values.helperArguments ) -}}
{{- end -}}
{{- $secretName := ( index $.Values.helperArguments 0 ) -}}
{{- if not (include "validator.secretName" $secretName) -}}
{{- fail (printf "\nInvalid HelperFunction definition: secretRef%s !!!\nCause: Secret name '%s' does not match RegExp: %s" $.Values.helperArguments $secretName (include "secretNameRegExp" .)) -}}
{{- end -}}
{{- $fileName := ( index $.Values.helperArguments (sub (len $.Values.helperArguments) 1) ) -}}
{{- if not (include "validator.fileName" $fileName) -}}
{{- fail (printf "\nInvalid HelperFunction definition: secretRef%s !!!\nCause: File name '%s' does not match RegExp: %s" $.Values.helperArguments $fileName (include "fileNameRegExp" .)) -}}
{{- end -}}
{{- end -}}

{{- define "helperFunction.secretRef.generate.configuration" -}}
{{- $configs := toYaml .Configs.config -}}
{{- range $index, $helperDefinition := .Values -}}
{{- include "helperFunction.secretRef.validation" $helperDefinition -}}
{{- $secretName := ( index $helperDefinition.Values.helperArguments 0 ) -}}
{{- $k8sSecretName := ( include "normalizer.secretName" $secretName ) -}}
{{- $secretKey := ( index $helperDefinition.Values.helperArguments (sub (len $helperDefinition.Values.helperArguments) 1) ) -}}
{{- $find := print "secretRef:" $secretName ":" $secretKey -}}
{{- $replaceTo := print "/mnt/secretRef/" $k8sSecretName "/" $secretKey -}}
{{- $configs = $configs | replace $find $replaceTo -}}
{{- end -}}
{{ print $configs }}
{{- end -}}

{{- define "helperFunction.secretRef.generate.volumes" -}}
{{- range $index, $helperDefinition := .Values -}}
{{- include "helperFunction.secretRef.validation" $helperDefinition -}}
{{- $secretName := ( index $helperDefinition.Values.helperArguments 0 ) -}}
{{- $k8sSecretName := ( include "normalizer.secretName" $secretName ) -}}
{{- $secretKey := ( index $helperDefinition.Values.helperArguments (sub (len $helperDefinition.Values.helperArguments) 1) ) -}}
- name: "secretref-{{ $helperDefinition.Values.helperId }}"
  secret:
    secretName: {{ $k8sSecretName }}
{{ end -}}
{{- end -}}

{{- define "helperFunction.secretRef.generate.volumesMounts" -}}
{{- range $index, $helperDefinition := .Values -}}
{{- include "helperFunction.secretRef.validation" $helperDefinition -}}
{{- $secretName := ( index $helperDefinition.Values.helperArguments 0 ) -}}
{{- $k8sSecretName := ( include "normalizer.secretName" $secretName ) -}}
{{- $secretKey := ( index $helperDefinition.Values.helperArguments (sub (len $helperDefinition.Values.helperArguments) 1) ) -}}
- name: "secretref-{{ $helperDefinition.Values.helperId }}"
  mountPath: "/mnt/secretRef/{{ $k8sSecretName }}"
{{ end -}}
{{- end -}}
