# Dynatrace Service Account Pic

```
Need a robot identity in Dynatrace?
 → service user (service account)
    → platform token (long-lived Bearer)
    OR OAuth client_credentials → short access_token
Not: classic env API token alone
Not: Kubernetes service account / IRSA
Token works only if service user still has IAM permissions + token scopes
```
