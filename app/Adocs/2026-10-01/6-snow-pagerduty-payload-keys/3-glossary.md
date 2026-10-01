# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Payload | The JSON body sent in an API call | What SILVA or PagerDuty receives |
| Reference field | Stores a sys_id pointing to another record | Needs sys_id, not a name |
| Choice field | Drop-down with stored values | Send the value, not the label |
| correlation_id | Incident field holding the Dynatrace display_id | CLOSE finds the ticket with it |
| Events API v2 | PagerDuty's `/v2/enqueue` endpoint | Trigger and resolve both go here |
| routing_key | PagerDuty integration key | Picks the PD service |
| dedup_key | PagerDuty grouping key | Trigger and resolve must match |
| custom_details | Free-form details object in PD | Shows extra context to on-call |
