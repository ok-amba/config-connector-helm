{{- define "storagebucket.labels" -}}
app: {{ .Release.Name }}
{{ with .Values.global.labels }}
  {{- toYaml . }}
{{- end -}}
{{- end -}}