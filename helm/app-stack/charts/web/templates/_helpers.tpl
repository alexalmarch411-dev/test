{{- define "web.fullname" -}}
{{ .Release.Name }}-web
{{- end -}}

{{- define "web.labels" -}}
app: {{ include "web.fullname" . }}
{{- end -}}

{{- define "web.selectorLabels" -}}
app: {{ include "web.fullname" . }}
{{- end -}}

{{- define "web.mongo.fullname" -}}
{{ .Release.Name }}-mongodb
{{- end -}}

{{- define "mongodb.fullname" -}}
{{ .Release.Name }}-mongodb
{{- end -}}

{{- define "mongodb.labels" -}}
app: {{ include "mongodb.fullname" . }}
{{- end -}}