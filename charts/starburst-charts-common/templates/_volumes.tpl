{{/* -------------------------------------------------------------------------------------------------------------- */}}
{{/* AdditionalVolumes Config                                                                                       */}}
{{/* -------------------------------------------------------------------------------------------------------------- */}}

{{- define "app.volumes" -}}
{{- range $index, $volSpec := .Values.additionalVolumes }}
- name: additional-volume-{{ $index }}
  {{- toYaml $volSpec.volume | nindent 2 }}
{{- end }}
{{- end -}}

{{- define "app.volumeMounts" -}}
{{- range $index, $volSpec := .Values.additionalVolumes }}
- name: additional-volume-{{ $index }}
  mountPath: {{ $volSpec.path }}
  {{- if $volSpec.subPath }}
  subPath: {{ $volSpec.subPath }}
  {{- end }}
{{- end }}
{{- end -}}
