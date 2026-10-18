# Dynatrace Service Account Glossary

| Term | What it means |
|---|---|
| Service user / service account | Non-human Dynatrace identity for automation |
| Platform token | Long-lived Bearer for platform APIs |
| OAuth client | client_id + client_secret to get short-lived tokens |
| Client credentials | OAuth grant with no interactive user login |
| Classic access token | Older environment API token |
| Scope | Permission listed on a token |
| Account | IAM boundary that can hold many environments |
| `iam:service-users:use` | Permission to mint tokens for a service user |
| Workload identity federation | External IdP token mapped to a service user |
