# Dynatrace Service Account Investigation

| Source | Finding |
|---|---|
| Dynatrace platform tokens docs | Tokens can be assigned to a service user; max 100 per service user |
| Dynatrace upgrade classic→platform guide | Service user = account-level identity for automated integrations |
| OAuth clients docs | Client credentials for machine-to-machine; SSO token endpoint |
| Token concepts docs | Service tokens for workflow automations; workload identity can map to service user |

UI labels may say "service user" while people say "service account". Same idea.
