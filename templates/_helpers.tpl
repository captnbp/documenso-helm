{{/* vim: set filetype=mustache: */}}

{{/*
Return the proper documenso image name
*/}}
{{- define "documenso.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "documenso.imagePullSecrets" -}}
{{- include "common.images.pullSecrets" (dict "images" .Values.image "global" .Values.global) -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "documenso.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return true if cert-manager required annotations for TLS signed certificates are set in the Ingress annotations
Ref: https://cert-manager.io/docs/usage/ingress/#supported-annotations
*/}}
{{- define "documenso.ingress.certManagerRequest" -}}
{{ if or (hasKey . "cert-manager.io/cluster-issuer") (hasKey . "cert-manager.io/issuer") }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a TLS credentials secret object should be created
*/}}
{{- define "documenso.createTlsSecret" -}}
{{- if and (not .Values.tls.existingSecret) .Values.tls.enabled }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the TLS secret name
*/}}
{{- define "documenso.issuerName" -}}
{{- $issuerName := .Values.tls.issuerRef.existingIssuerName -}}
{{- if $issuerName -}}
    {{- printf "%s" (tpl $issuerName $) -}}
{{- else -}}
    {{- printf "%s-http" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}


{{/*
Return the CNP cluster fullname
*/}}
{{- define "documenso.postgresql.fullname" -}}
{{- if .Values.postgresql.name -}}
{{- .Values.postgresql.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-postgresql" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Return the CNP cluster service name (read-write)
*/}}
{{- define "documenso.postgresql.serviceName" -}}
{{- printf "%s-rw" (include "documenso.postgresql.fullname" .) -}}
{{- end -}}

{{/*
Return the CNP secret name
*/}}
{{- define "documenso.postgresql.secretName" -}}
{{- if .Values.postgresql.database.existingSecret -}}
{{- .Values.postgresql.database.existingSecret -}}
{{- else -}}
{{- printf "%s-app" (include "documenso.postgresql.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the CNP database password
*/}}
{{- define "documenso.postgresql.password" -}}
{{- if .Values.postgresql.database.password -}}
{{- .Values.postgresql.database.password -}}
{{- else }}
{{- randAlphaNum 32 }}
{{- end }}
{{- end -}}

{{/*
Get the database host
*/}}
{{- define "documenso.database.host" -}}
{{- if .Values.postgresql.enabled -}}
{{- $releaseNamespace := .Release.Namespace }}
{{- $clusterDomain := .Values.clusterDomain }}
{{- $serviceName := include "documenso.postgresql.serviceName" . }}
{{- printf "%s.%s.svc.%s" $serviceName $releaseNamespace $clusterDomain -}}
{{- else -}}
{{- .Values.externalDatabase.host -}}
{{- end -}}
{{- end -}}

{{/*
Get the database port
*/}}
{{- define "documenso.database.port" -}}
{{- if .Values.postgresql.enabled -}}
5432
{{- else -}}
{{- .Values.externalDatabase.port -}}
{{- end -}}
{{- end -}}

{{/*
Get the database name
*/}}
{{- define "documenso.database.name" -}}
{{- if .Values.postgresql.enabled -}}
{{- .Values.postgresql.database.name -}}
{{- else -}}
{{- .Values.externalDatabase.database -}}
{{- end -}}
{{- end -}}

{{/*
Get the database username
*/}}
{{- define "documenso.database.username" -}}
{{- if .Values.postgresql.enabled -}}
{{- .Values.postgresql.database.username -}}
{{- else -}}
{{- .Values.externalDatabase.username -}}
{{- end -}}
{{- end -}}

{{/*
Get the Postgresql credentials secret.
*/}}
{{- define "documenso.databaseSecretName" -}}
{{- if .Values.postgresql.enabled -}}
{{- include "documenso.postgresql.secretName" . -}}
{{- else -}}
{{- default (printf "%s-externaldb" .Release.Name) (tpl .Values.externalDatabase.existingSecret $) -}}
{{- end -}}
{{- end -}}

{{/*
Add environment variables to configure database values
*/}}
{{- define "documenso.databaseSecretKey" -}}
{{- if .Values.postgresql.enabled -}}
    {{- print "password" -}}
{{- else -}}
    {{- if .Values.externalDatabase.existingSecret -}}
        {{- if .Values.externalDatabase.existingSecretPasswordKey -}}
            {{- printf "%s" .Values.externalDatabase.existingSecretPasswordKey -}}
        {{- else -}}
            {{- print "password" -}}
        {{- end -}}
    {{- else -}}
        {{- print "password" -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Generate NextAuth secret
*/}}
{{- define "documenso.nextAuthSecret" -}}
{{- if .Values.documenso.nextAuthSecret -}}
{{- .Values.documenso.nextAuthSecret -}}
{{- else -}}
{{- $secretData := (lookup "v1" "Secret" $.Release.Namespace (include "common.names.fullname" .)).data }}
{{- if and $secretData (hasKey $secretData "nextauth-secret") }}
{{- index $secretData "nextauth-secret" | b64dec }}
{{- else }}
{{- randAlphaNum 32 }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Generate signing certificate password
*/}}
{{- define "documenso.signingPassword" -}}
{{- if .Values.documenso.signing.password -}}
{{- .Values.documenso.signing.password -}}
{{- else -}}
{{- $secretData := (lookup "v1" "Secret" $.Release.Namespace (printf "%s-signing" (include "common.names.fullname" .))).data }}
{{- if and $secretData (hasKey $secretData "password") }}
{{- index $secretData "password" | b64dec }}
{{- else }}
{{- randAlphaNum 32 }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Generate primary encryption key
*/}}
{{- define "documenso.encryptionKey" -}}
{{- if .Values.documenso.encryptionKey -}}
{{- .Values.documenso.encryptionKey -}}
{{- else -}}
{{- $secretData := (lookup "v1" "Secret" $.Release.Namespace (include "common.names.fullname" .)).data }}
{{- if and $secretData (hasKey $secretData "encryption-key") }}
{{- index $secretData "encryption-key" | b64dec }}
{{- else }}
{{- randAlphaNum 64 }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Generate secondary encryption key
*/}}
{{- define "documenso.encryptionSecondaryKey" -}}
{{- if .Values.documenso.encryptionSecondaryKey -}}
{{- .Values.documenso.encryptionSecondaryKey -}}
{{- else -}}
{{- $secretData := (lookup "v1" "Secret" $.Release.Namespace (include "common.names.fullname" .)).data }}
{{- if and $secretData (hasKey $secretData "encryption-secondary-key") }}
{{- index $secretData "encryption-secondary-key" | b64dec }}
{{- else }}
{{- randAlphaNum 64 }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Get application URL
*/}}
{{- define "documenso.url" -}}
{{- if .Values.documenso.url -}}
{{- .Values.documenso.url -}}
{{- else if .Values.ingress.enabled -}}
{{- if .Values.ingress.tls -}}
{{- printf "https://%s" .Values.ingress.hostname -}}
{{- else -}}
{{- printf "https://%s" .Values.ingress.hostname -}}
{{- end -}}
{{- else -}}
{{- printf "http://localhost:3000" -}}
{{- end -}}
{{- end -}}
