{{/* Helper template to add nodePool information to nodeSelector based on the cloud provider.*/}}
{{- define "nodeSelector.nodePool" }}
{{- if or  .Values.nodeSelector .Values.gcpExtraNodePool  }}
nodeSelector:
{{- if .Values.nodeSelector }}
{{- toYaml .Values.nodeSelector | nindent 2 }}
{{- end }}
{{- if .Values.gcpExtraNodePool }}
  "cloud.google.com/gke-nodepool": {{ .Values.gcpExtraNodePool | quote }}
{{- end }}
{{- end }}
{{- end }}
