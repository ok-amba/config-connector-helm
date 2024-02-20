{{- define "iam-service-account.labels" -}}
app: {{ .Release.Name }}
chart-name: "iam-service-account"
chart-version: {{ .Chart.Version | replace "." "-" }}
{{- with .Values.global.labels }}
{{- toYaml . | nindent 0 }}
{{- end -}}
{{- with .Values.labels }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end -}}
