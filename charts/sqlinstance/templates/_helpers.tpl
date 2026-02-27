##########################################################
#              Service account normalization             #
##########################################################

{{/*
Normalize a service account "email" value into a fully-qualified SA email.

Accepted inputs:
  - local@project
  - local@project.iam
  - local@project.iam.gserviceaccount.com

Rejected:
  - local            (no '@')
  - local@           (missing project)
  - @project         (missing local)

Returns:
  - local@project.iam.gserviceaccount.com
*/}}
{{- define "sqlinstance.normalizeServiceAccountEmail" -}}
{{- $raw := required "serviceAccounts[].email is required" . -}}

{{- if not (contains "@" $raw) -}}
  {{- fail (printf "serviceAccounts[].email must contain '@' (got %q)" $raw) -}}
{{- end -}}

{{- $parts := splitList "@" $raw -}}
{{- if ne (len $parts) 2 -}}
  {{- fail (printf "serviceAccounts[].email must contain exactly one '@' (got %q)" $raw) -}}
{{- end -}}

{{- $local := index $parts 0 -}}
{{- $dom := index $parts 1 -}}

{{- if or (eq $local "") (eq $dom "") -}}
  {{- fail (printf "serviceAccounts[].email must be of form local@project[.iam[.gserviceaccount.com]] (got %q)" $raw) -}}
{{- end -}}

{{- /* Strip known suffixes to get the project id */ -}}
{{- $project := $dom -}}
{{- $project = regexReplaceAll "\\.iam\\.gserviceaccount\\.com$" $project "" -}}
{{- $project = regexReplaceAll "\\.iam$" $project "" -}}

{{- if eq $project "" -}}
  {{- fail (printf "serviceAccounts[].email missing project (got %q)" $raw) -}}
{{- end -}}

{{- printf "%s@%s.iam.gserviceaccount.com" $local $project -}}
{{- end -}}


##########################################################
#                   Ensure no dublicate SA's             #
##########################################################

{{/*
Validate that legacy serviceAccountName + serviceAccounts do not contain duplicates.

Rules for duplicate detection:
- legacy serviceAccountName:
    => <serviceAccountName>@<global.projectID>.iam              (DO NOT normalize legacy input)
- serviceAccounts[].name:
    => <name>@<global.projectID>.iam                            (old behavior, for duplicate detection)
- serviceAccounts[].email:
    => normalized to <local>@<project>.iam.gserviceaccount.com  (rejects values without '@')

Fails with a list of duplicate strings as tracked above.

Usage:
  {{- include "sqlinstance.validateNoDuplicateServiceAccounts" . -}}
*/}}
{{- define "sqlinstance.validateNoDuplicateServiceAccounts" -}}
{{- $projectID := .Values.global.projectID | required "A project ID is required" -}}
{{- $serviceAccounts := default (list) .Values.serviceAccounts -}}

{{- $seen := dict -}}
{{- $dups := list -}}

{{- /* legacy: keep behavior; no normalization */ -}}
{{- if .Values.serviceAccountName -}}
  {{- $legacyID := printf "%s@%s.iam" .Values.serviceAccountName $projectID -}}
  {{- if hasKey $seen $legacyID -}}
    {{- $dups = append $dups $legacyID -}}
  {{- else -}}
    {{- $_ := set $seen $legacyID true -}}
  {{- end -}}
{{- end -}}

{{- /* list */ -}}
{{- range $sa := $serviceAccounts -}}
  {{- $id := "" -}}

  {{- if and (hasKey $sa "email") $sa.email -}}
    {{- /* Normalize/validate email-shaped input */ -}}
    {{- $id = include "sqlinstance.normalizeServiceAccountEmail" $sa.email -}}
  {{- else if and (hasKey $sa "name") $sa.name -}}
    {{- /* Old behavior: name expands to @project.iam */ -}}
    {{- $id = printf "%s@%s.iam" $sa.name $projectID -}}
  {{- else -}}
    {{- fail "Each item in serviceAccounts must have either non-empty 'email' or non-empty 'name'" -}}
  {{- end -}}

  {{- if hasKey $seen $id -}}
    {{- $dups = append $dups $id -}}
  {{- else -}}
    {{- $_ := set $seen $id true -}}
  {{- end -}}
{{- end -}}

{{- if gt (len $dups) 0 -}}
  {{- fail (printf "Duplicate service account(s) detected across serviceAccountName/serviceAccounts: %s" (join ", " $dups)) -}}
{{- end -}}
{{- end -}}

##########################################################
#                   Define sqlinstance labels:           #
##########################################################

{{- define "sqlinstance.labels" -}}
app: {{ .Release.Name }}
chart-name: "sqlinstance"
chart-version: {{ .Chart.Version | replace "." "-" }}
sqlinstance: {{ .Values.name }}
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

##########################################################
#                      Validate Tier                     #
##########################################################
# This function validates that the MiB of the custom tier
# selected is multiple of 256. Micro and Small tier will
# not be evaluated.
{{- define "sqlinstance.validate-tier" -}}
{{- if and (ne .Values.tier "db-f1-micro") (ne .Values.tier "db-g1-small") }}
  {{- $instance_mem := regexFind "\\d{4,}" .Values.tier | int }}
  {{- if mod $instance_mem 256 }}
  {{- fail (printf "the total memory [%dMiB] must be a multiple of 256 MiB. " $instance_mem) -}}
  {{- end -}}
{{- end -}}
{{ .Values.tier }}
{{- end -}}

##########################################################
#              Validate Availability Setting             #
##########################################################
# Validates that .availabilityType is either REGIONAL or
# ZONAL. Also validates that .backupConfiguration.enabled
# and .backupConfiguration.pointInTimeRecoveryEnabled
# is true if .availabilityType is REGIONAL.
{{- define "sqlinstance.validate-availability-type" -}}
{{- if and (ne .Values.availabilityType "REGIONAL") (ne .Values.availabilityType "ZONAL")}}
  {{- fail (printf "'.availabilityType' must be either REGIONAL or ZONAL") -}}
{{- end -}}

{{- if eq .Values.availabilityType "REGIONAL" }}
  {{- if or (not .Values.backupConfiguration.enabled) (not .Values.backupConfiguration.pointInTimeRecoveryEnabled) }}
    {{- fail (printf "if '.availabilityType' is REGIONAL, then '.backupConfiguration.enabled' and '.backupConfiguration.pointInTimeRecoveryEnabled' must be true.") -}}
  {{- end -}}
{{- end -}}
{{- end -}}
