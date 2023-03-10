{{/* -------------------------------------------------------------------------------------------------------------- */}}
{{/* Ingress Config                                                                                                */}}
{{/* -------------------------------------------------------------------------------------------------------------- */}}

{{- define "app.ingress" }}

{{- if eq .Values.expose.type "ingress" }}
{{- $ingress := .Values.expose.ingress }}
{{- include "app.ingress.apiversion" . }}
kind: Ingress
metadata:
  name: {{ $ingress.ingressName }}
  labels:
    {{- include "app.labels" . | nindent 4 }}
  {{- if $ingress.annotations }}
  {{- with $ingress.annotations }}
  annotations: {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- end }}
spec:
  {{- if $ingress.ingressClassName }}
  ingressClassName: {{ $ingress.ingressClassName }}
  {{- end }}
  {{- if $ingress.tls.enabled }}
  tls:
    - secretName: {{ $ingress.tls.secretName }}
      hosts:
        - {{ $ingress.host }}
  {{- end }}
  rules:
    - http:
        paths:
          - path: {{ $ingress.path }}
            backend:
            {{- if (include "isKubeVersionPost119" .) }}
              service:
                name: {{ $ingress.serviceName }}
                port:
                  number: {{ $ingress.servicePort }}
            pathType: {{ default "ImplementationSpecific" $ingress.pathType }}
            {{- else }}
              serviceName: {{ $ingress.serviceName }}
              servicePort: {{ $ingress.servicePort }}
            {{- end }}
      {{- if $ingress.host }}
      host: {{ $ingress.host }}
      {{- end }}
{{- end }}

{{- end }}


{{- define "app.ingress.service" }}

{{- if eq .Values.expose.type "ingress" }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.expose.ingress.serviceName }}
  labels:
    {{- include "app.labels" . | nindent 4 }}
    {{- if (eq "starburst-enterprise" .Chart.Name) }}
    role: coordinator
    {{- end }}
spec:
  type: ClusterIP
  ports:
    - name: http
      protocol: TCP
      port: {{ .Values.expose.ingress.servicePort }}
  selector:
    {{- include "app.labels" . | nindent 4 }}
    {{- if (eq "starburst-enterprise" .Chart.Name) }}
    role: coordinator
    {{- end }}
{{- end }}

{{- end }}

{{- define "app.ingress.apiversion" }}

{{- if (include "isKubeVersionPost119" .) }}
apiVersion: networking.k8s.io/v1
{{- else }}
apiVersion: networking.k8s.io/v1beta1
{{- end }}

{{- end }}