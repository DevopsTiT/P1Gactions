# Glossary

| Term | What it means |
| --- | --- |
| §4.2 fields | ServiceNow INC fields: caller, biz service, assignment, impact/urgency, description, correlation_id |
| §4.4 maps | `assignMap`: app tag → group, biz, L1/L2/L3, runbook |
| prepare-payload | First JS task that builds the shared object |
| Parallel | SNOW and PD both wait only on prepare, not on each other |
| Cross-link | Work note on INC with PD dedup_key after both creates succeed |
| correlation_id | SNOW field storing Dynatrace Problem ID |
| dedup_key | PD key for trigger and resolve |
| routing_key | PagerDuty Events API v2 integration key |
| state 6 | ServiceNow Resolved |
