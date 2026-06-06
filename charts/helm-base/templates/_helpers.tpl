{{/*
App name
*/}}
{{- define "app-template.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Full name
*/}}
{{- define "app-template.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" (include "app-template.name" .) .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Standard labels
*/}}
{{- define "app-template.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "app-template.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | default "latest" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels (IMPORTANT for deployments/services)
*/}}
{{- define "app-template.selectorLabels" -}}
app.kubernetes.io/name: {{ include "app-template.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* compatibility layer */}}

{{- define "helm-base.name" -}}
{{ include "app-template.name" . }}
{{- end }}

{{- define "helm-base.fullname" -}}
{{ include "app-template.fullname" . }}
{{- end }}

{{- define "helm-base.labels" -}}
{{ include "app-template.labels" . }}
{{- end }}

{{- define "helm-base.selectorLabels" -}}
{{ include "app-template.selectorLabels" . }}
{{- end }}

