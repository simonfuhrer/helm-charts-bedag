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
{{- define "bedag-lib.manifest.service.values" -}}
  {{- include "lib.utils.template" (dict "value" (include "bedag-lib.mergedValues" (dict "type" "service" "root" .)) "context" .context) -}}
{{- end }}

{{- define "bedag-lib.manifest.service" -}}
  {{- if .context -}}
    {{- $context := .context -}}
    {{- $svc := (fromYaml (include "bedag-lib.manifest.service.values" .)) -}}
    {{- if $svc.enabled -}}
kind: Service
      {{- if $svc.apiVersion }}
apiVersion: {{ $svc.apiVersion }}
      {{- else }}
apiVersion: v1
      {{- end }}
metadata:
  name: {{ include "bedag-lib.fullname" . }}
  labels: {{- include "lib.utils.labels" (dict "labels" $svc.labels "context" $context)| nindent 4 }}
      {{- if $svc.annotations }}
  annotations:
        {{- range $anno, $val := $svc.annotations }}
          {{- $anno | nindent 4 }}: {{ $val | quote }}
        {{- end }}
      {{- end }}
spec:
      {{- $type := (default "ClusterIP" $svc.type) }}
  type: {{ $type }}
      {{- if eq $type "LoadBalancer" }}
        {{- if $svc.loadBalancerIP }}
  loadBalancerIP: {{ $svc.loadBalancerIP }}
        {{- end }}
        {{- if $svc.loadBalancerSourceRanges }}
  loadBalancerSourceRanges: {{- toYaml $svc.loadBalancerSourceRanges | nindent 4 }}
        {{- end }}
      {{- end }}
      {{- if and (eq $type "ClusterIP") $svc.clusterIP }}
  clusterIP: {{ $svc.clusterIP }}
      {{- end }}
  ports:
    - name: {{ include "lib.utils.toDns1123" (default "http" $svc.portName) }}
      port: {{ default 80 $svc.port }}
      protocol: {{ default "TCP" $svc.protocol }}
      targetPort: {{ include "lib.utils.toDns1123" (default "http" $svc.targetPort) }}
      {{- if and (or (eq $type "NodePort") (eq $type "LoadBalancer")) (not (empty $svc.nodePort)) }}
      nodePort: {{ $svc.nodePort }}
      {{- else if eq $type "ClusterIP" }}
      nodePort: null
      {{- end }}
      {{- if and $svc.extraPorts (kindIs "slice" $svc.extraPorts) }}
        {{- toYaml $svc.extraPorts | nindent 4 }}
      {{- end }}
  selector: {{- include "lib.utils.template" (dict "value" (default (include "lib.utils.selectorLabels" $context) $svc.selector) "context" $context) | nindent 4 }}
    {{- end }}
  {{- else }}
    {{- fail "Template requires '.context' as arguments" }}
  {{- end }}
{{- end -}}
