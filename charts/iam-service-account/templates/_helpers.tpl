{{- define "iam-service-account.labels" -}}
app: {{ .Release.Name }}
chart-name: "iam-service-account"
chart-version: {{ .Chart.Version | replace "." "-" }}
{{- range $k, $v := .Values.global.labels }}
{{ printf "%s: %s" $k ($v | quote) }}
{{- end -}}
{{- range $k, $v := .Values.labels }}
{{ printf "%s: %s" $k ($v | quote) }}
{{- end -}}
{{- end -}}
