{{- define "iam-partial-policy.labels" -}}
app: {{ .Release.Name }}
{{ with .Values.global.labels }}
  {{- toYaml . }}
{{- end -}}
{{- end -}}