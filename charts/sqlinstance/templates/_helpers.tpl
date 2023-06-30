{{- define "sqlinstance.labels" -}}
app: {{ .Release.Name | quote }}
chart-name: {{ .Chart.Name | quote }}
chart-version: {{ .Chart.Version | replace "." "-" | quote }}
{{- range $k, $v := .Values.global.labels }}
{{ printf "%s: %s" $k ($v | quote) }}
{{- end -}}
{{- end -}}
