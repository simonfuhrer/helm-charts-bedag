{{/*

Copyright © 2020 Oliver Baehler

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/}}
{{- define "bedag-lib.manifest.ingress.values" -}}
  {{- include "lib.utils.template" (dict "value" (include "bedag-lib.mergedValues" (dict "type" "ingress" "root" .)) "context" .context) -}}
{{- end }}

{{- define "bedag-lib.manifest.ingress" -}}
  {{- if .context -}}
    {{- $context := .context -}}
    {{- $ingress := (fromYaml (include "bedag-lib.manifest.ingress.values" .)) -}}
    {{- if and $ingress.enabled $ingress.hosts -}}
kind: Ingress
      {{- if $ingress.apiVersion -}}
apiVersion: {{ $ingress.apiVersion }}
      {{- else -}}
        {{- if semverCompare ">=1.19-0" (include "lib.utils.capabilities" $context) }}
apiVersion: networking.k8s.io/v1
        {{- else if semverCompare ">=1.14-0" (include "lib.utils.capabilities" $context) }}
apiVersion: networking.k8s.io/v1beta1
        {{- else }}
apiVersion: extensions/v1beta1
        {{- end }}
      {{- end }}
metadata:
  name:  {{ include "bedag-lib.fullname" . }}
  labels: {{- include "lib.utils.labels" (dict "labels" $ingress.labels "context" $context)| nindent 4 }}
      {{- if $ingress.annotations }}
  annotations:
        {{- range $anno, $val := $ingress.annotations }}
          {{- $anno | nindent 4 }}: {{ $val | quote }}
        {{- end }}
      {{- end }}
spec:
      {{- if and $ingress.backend (kindIs "map" $ingress.backend) }}
  backend: {{- toYaml $ingress.backend | nindent 4 }}
      {{- end }}
      {{- if semverCompare ">=1.18-0" (include "lib.utils.capabilities" $context) -}}
        {{- if and $ingress.ingressClass (kindIs "string" $ingress.ingressClass) }}
  ingressClassName: {{ $ingress.ingressClass }}
        {{- end }}
      {{- end }}
      {{- if $ingress.tls }}
  tls:
        {{- range $ingress.tls }}
    - hosts:
          {{- range .hosts }}
        - {{ . | quote }}
          {{- end }}
      secretName: {{ default "" .secretName }}
        {{- end }}
      {{- end }}
  rules:
        {{- range $ingress.hosts }}
    - host: {{ required "Field .host required for ingress manifest" .host | quote }}
      http:
        paths:
          {{- range .paths }}
            {{- $p := dict "path" "" "pathType" "" "service" dict "resource" dict }}
            {{- if kindIs "string" . }}
              {{- $_ := set $p "path" . }}
              {{- $_ := set $p "service" (dict "name" (include "bedag-lib.fullname" $context) "port" "http") }}
            {{- else }}
              {{- $_ := set $p "path" (default "/" .path) }}
              {{- $_ := set $p "pathType" (default "" .pathType) }}
              {{- if .resource }}
                {{- $_ := set $p "resource" .resource }}
              {{- else }}
                {{- $_ := set $p "service" (dict "name" (include "lib.utils.toDns1123" (default (include "bedag-lib.fullname" $context) .serviceName)) "port" (include "lib.utils.toDns1123" (default "http" .servicePort))) }}
              {{- end }}
            {{- end }}
          - path: {{ $p.path }}
            {{- if semverCompare ">=1.18-0" (include "lib.utils.capabilities" $context) }}
            pathType: {{ default "Prefix" $p.pathType }}
            {{- end }}
            backend:
            {{- if $p.resource }}
              resource: {{- toYaml $p.resource | nindent 16 }}
            {{- else }}
              {{- if semverCompare ">=1.19-0" (include "lib.utils.capabilities" $context) }}
              service:
                name: {{ $p.service.name }}
                port:
                {{- if or (kindIs "int" $p.service.port) (kindIs "float64" $p.service.port) }}
                  number: {{ $p.service.port }}
                {{- else }}
                  name: {{ lower $p.service.port }}
                {{- end }}
              {{- else }}
              serviceName: {{ $p.service.name }}
              servicePort: {{ $p.service.port }}
              {{- end }}
            {{- end }}
          {{- end }}
        {{- end }}
    {{- end }}
  {{- else }}
    {{- fail "Template requires '.context' as argument" }}
  {{- end }}
{{- end -}}
