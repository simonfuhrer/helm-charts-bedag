/*

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

*/
{{- define "bedag-lib.presets" -}}
  {{- if and .preset .context -}}
    {{- $params := . -}}
    {{- $base := "bedag-lib.presets." }}
    {{- $basePath := (cat $base .preset | nospace) -}}
    {{- $baseValues := (cat $base "values" "." .preset | nospace) }}
    {{- $_ := set $params "values" (mergeOverwrite (fromYaml (include $baseValues .)) (default dict .values)) -}}
    {{- $_ := set $params "values" (mergeOverwrite $params.values (fromYaml (include (cat $basePath "." "overwrites" | nospace) $params))) -}}
    {{- $output := include $basePath $params -}}
    {{- if $output }}
      {{- if .returnAsArray }}
- {{- $output | nindent 2 }}
      {{- else }}
{{- $output }}
      {{- end }}
    {{- end }}
    {{- $_ := unset $params "values" }}
  {{- end }}
{{- end -}}
