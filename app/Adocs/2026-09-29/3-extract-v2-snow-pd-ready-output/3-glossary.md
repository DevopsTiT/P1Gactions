# Glossary

| Term | What it means | Why you care |
|---|---|---|
| OAuth scope | A permission the workflow token must have | Missing `environment-api:problems:read` broke the Problems API call |
| STARTSWITH / LIKE | SILVA query operators for "starts with" and "contains" | Find CIs stored as `deaa310b.domain` or `DEA10B01@host` |
| cmdb_rel_ci | The general CI relationship table | Second way to link a CI to a service |
| service_candidates | Services whose name contains the trigram | Lets you choose the right one for SERVICE_MAP |
| match_method | How the business service was found | Tells you how much to trust the result |
| decision | The workflow's recommendation (create or skip, group, environment) | What OPEN would do |
| snow_incident_payload | The incident body OPEN would POST | Check it before going live |
| pagerduty_payload | The PagerDuty event OPEN would send | Same, for PagerDuty |
| --data-urlencode | A curl option that encodes a parameter safely | Avoids "Malformed input to a URL function" |
