# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Placeholder | Text like `__PD_SERVICE_URL__` waiting for a real value | If left, it shows up in tickets. |
| Status transition | Why the event fired: CREATED, UPDATED, REOPENED | UPDATED can fire many times for one problem. |
| Duplicate check | Search for an open incident with the same correlation_id before creating one | Prevents several tickets for one problem. |
| correlation_id | The Dynatrace problem id stored on the SILVA incident | It links OPEN and CLOSE to the same ticket. |
| dedup_key | PagerDuty's key for one alert | The same key updates the same alert instead of creating a new one. |
| External requests allowlist | Dynatrace setting listing hosts workflows may call | Without it every HTTP call fails. |
| Run workflow | Manual test run with a sample event | Lets you test without waiting for a real problem. |
