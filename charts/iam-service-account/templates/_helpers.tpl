{{- define "iam-service-account.labels" -}}
app: {{ .Release.Name }}
{{ with .Values.global.labels }}
  {{- toYaml . }}
{{- end -}}
{{- end -}}