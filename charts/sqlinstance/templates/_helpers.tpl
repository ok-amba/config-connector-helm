{{- define "sqlinstance.labels" -}}
app: {{ .Release.Name }}
chart-name: {{ .Chart.Name }}
chart-version: {{ .Chart.Version | replace "." "-" }}
{{- range $k, $v := .Values.global.labels }}
{{ printf "%s: %s" $k ($v | quote) }}
{{- end -}}
{{- end -}}

##########################################################
#                   Calculate work_mem                   #
##########################################################
# This function calulates the "work_mem" db flag value.
# The default value for Micro and Small instances
# is 4096.
{{- define "sqlinstance.work-mem" -}}
{{ $work_mem := "4096" }}
{{- if and (ne .Values.tier "db-f1-micro") (ne .Values.tier "db-g1-small") }}
  {{- $instance_mem := regexFind "\\d{4,}" .Values.tier | int }}
  {{- $connections := 0 -}}

  {{- if lt $instance_mem 6144}}
  {{- $connections = 100 }}
  {{- else if lt $instance_mem 7680 }}
  {{- $connections = 200 }}
  {{- else if lt $instance_mem 15360 }}
  {{- $connections = 400 }}
  {{- else if lt $instance_mem 30720 }}
  {{- $connections = 500 }}
  {{- else if lt $instance_mem 61440 }}
  {{- $connections = 600 }}
  {{- else if lt $instance_mem 122880 }}
  {{- $connections = 800 }}
  {{- else if gt $instance_mem 122880 }}
  {{- $connections = 1000 }}
  {{- else }}
  {{- fail (printf "could not calculate instance memory for instance flag work_mem. memory: [%s] " $instance_mem) -}}
  {{- end -}}

  {{/* Total RAM * 0.25 / max_connections. Eg 3750*0.25/100 = 9,375 */}}
  {{- $work_mem = mulf (divf (mulf $instance_mem 0.25) $connections) 1000 }}
{{- end -}}
{{ $work_mem | quote }}
{{- end -}}
