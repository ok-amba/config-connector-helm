{{- define "iam-partial-policy.labels" -}}
app: {{ .Release.Name }}
chart-name: {{ .Chart.Name }}
chart-version: {{ .Chart.Version | replace "." "-" }}
{{- with .Values.global.labels }}
{{- toYaml . | nindent 0}}
{{- end -}}
{{- end -}}