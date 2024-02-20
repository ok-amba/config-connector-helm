{{- define "pubsub.labels" -}}
app: "{{ .Release.Name }}"
chart-name: "pub-sub"
chart-version: "{{ .Chart.Version | replace "." "-" }}"
{{- range $k, $v := .Values.global.labels }}
{{ printf "%s: %s" $k ($v | quote) }}
{{- end -}}
{{- end -}}
