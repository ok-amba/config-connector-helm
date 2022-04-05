{{- define "iam-service-account-key.labels" -}}
app: {{ .Release.Name }}
{{ with .Values.global.labels }}
  {{- toYaml . }}
{{- end -}}
{{- end -}}