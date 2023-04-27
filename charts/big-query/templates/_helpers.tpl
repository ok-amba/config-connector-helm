{{- define "big-query.labels" -}}
app: {{ .Release.Name }}
chart-name: {{ .Chart.Name }}
chart-version: {{ .Chart.Version | replace "." "-" }}
{{- with .Values.global.labels }}
{{- toYaml . | nindent 0}}
{{- end -}}
{{- end -}}

{{- define "big-query.dataset-name" -}}
{{- if not (regexMatch "^[a-z]{1}[a-z0-9-]*[a-z0-9]+$" .name) -}}
  {{- fail (printf "big query dataset [%s] can only be lowercase alphanumeric characters and hyphens." .name) -}}
{{- end -}}
{{ .name | required "A resource name is required." }}
{{- end -}}

{{- define "big-query.table-name" -}}
{{- if not (regexMatch "^[a-z0-9-]+[a-z0-9]+$" .name) -}}
  {{- fail (printf "big query dataset [%s] can only be lowercase alphanumeric characters and hyphens." .name) -}}
{{- end -}}
{{ .name | required "A resource name is required." }}
{{- end -}}

{{- define "big-query.external-writer" -}}
{{- range . }}
{{- if regexMatch "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.iam\\.gserviceaccount\\.com$" . }}
- role: WRITER
  userByEmail: {{ . }}
{{- end }}
{{- end }}
{{- end }}

{{- define "big-query.external-reader" -}}
{{- range . }}
{{- if regexMatch "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.iam\\.gserviceaccount\\.com$" . }}
- role: READER
  userByEmail: {{ . }}
{{- end }}
{{- end }}
{{- end }}

{{- define "big-query.writer" -}}
{{- range .users }}
{{- if regexMatch "^[A-Za-z0-9._%+-]+$" . }}
- role: WRITER
  userByEmail: {{ printf "%s@%s.iam.gserviceaccount.com" . $.projectID }}
{{- end }}
{{- end }}
{{- end }}

{{- define "big-query.reader" -}}
{{- range .users }}
{{- if regexMatch "^[A-Za-z0-9._%+-]+$" . }}
- role: READER
  userByEmail: {{ printf "%s@%s.iam.gserviceaccount.com" . $.projectID }}
{{- end }}
{{- end }}
{{- end }}
