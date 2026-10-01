# Glossary

| Term | What it means |
|---|---|
| Davis problem | A Dynatrace problem opened by its AI engine (Davis). |
| Problems API v2 | Dynatrace API that returns problem details such as entity tags. |
| run-javascript | Dynatrace workflow action that runs a JavaScript task. |
| ex.result | Reads the returned object of an earlier task in the same run. |
| Table API | ServiceNow REST API to read or write any table: `/api/now/v2/table/<table>`. |
| sys_user_group | SILVA table of teams. |
| cmdb_ci | SILVA table of all configuration items (hosts, databases, services). |
| cmdb_ci_service | SILVA table of business services. Offerings are a child class of it. |
| service_offering | SILVA table of offerings. `parent` points to the business service. |
| svc_ci_assoc | SILVA table linking CIs to services. |
| cmdb_rel_ci | SILVA table of CI relationships (parent and child). |
| PagerDuty Events API v2 | `events.pagerduty.com/v2/enqueue`, used to trigger, acknowledge or resolve alerts. |
| routing_key | The PagerDuty integration key that picks the service to page. |
| dedup_key | Key that groups repeated events into one PagerDuty incident. |
| DRY_RUN | OPEN setting: build and log only, never send. |
| ALLOW_SAMPLE_POST | OPEN setting: allow sending for the sample event. Keep false. |
