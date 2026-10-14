# Camunda Error Fatal DQL Result

| Item | Value |
|---|---|
| Prefixes | camunda8-prod-identity-, camunda8-prod-zeebe-, camunda8-prod-keycloak- |
| Keywords | ERROR, FATAL, case sensitive |
| Output | time, host.name, k8s.pod.name, matched_keywords, content |

## If empty

| Check 1 shows | Change |
|---|---|
| Other field | Use that field |
| Namespace only | Filter by k8s.namespace.name |
| Nothing | Logs not in Dynatrace |
