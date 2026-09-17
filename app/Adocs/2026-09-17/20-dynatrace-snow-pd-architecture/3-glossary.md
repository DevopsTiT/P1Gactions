# Glossary

| Term | What it means |
| --- | --- |
| Problem | Dynatrace Davis object that groups related issues over time |
| Incident (INC) | ServiceNow ticket used to track work and handoffs |
| Workflow | Dynatrace automation that runs tasks when a trigger matches |
| ServiceNow Connector | App `dynatrace.servicenow` providing `snow-*` workflow actions |
| Connection | Stored SNOW URL and credentials mapped onto snow tasks |
| Problem notification | Classic Settings integration that pushes Problems to SNOW |
| ITSM | Path that creates ServiceNow Incidents |
| ITOM | Path that sends ServiceNow events (not the same as a full INC process) |
| correlation_id | SNOW field used to find the INC on Problem close |
| dedup_key | PagerDuty key that ties trigger and resolve to one alert |
| assignMap | JS table mapping app tag to group, biz service, L1/L2/L3, runbook |
| Allowlist | Dynatrace list of external hosts workflows may call |
| Parallel tasks | Tasks that start after the same predecessor without waiting on each other |
| Cross-link comment | Work note on INC that stores PD key and Problem URL |
