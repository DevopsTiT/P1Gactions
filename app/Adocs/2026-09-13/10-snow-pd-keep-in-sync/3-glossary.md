# Glossary

| Term | What it means |
| --- | --- |
| ServiceNow (SNOW) | ITSM system that stores Incidents (INC) for SLA and audit |
| PagerDuty (PD) | On-call paging system that alerts people |
| Dynatrace Problem | Davis-detected issue that opens and closes in Dynatrace |
| correlation_id | ServiceNow field used to store the Dynatrace Problem ID |
| dedup_key | PagerDuty Events API key that groups/triggers/resolves one alert |
| cross-link | Workflow step that writes the PD key into the INC work notes |
| Events API v2 | PagerDuty HTTP API used to trigger and resolve alerts |
| Orchestrator | Dynatrace Workflows driving both SNOW and PD in this design |
