# Investigation

| Checked | Evidence |
|---|---|
| AGPO search | sourcetype agportalapi-prod-axa-li-jp, host agpo-cloud-authorization-process-api-*, two IamCChangePassword response names |
| AGPO trigger | Every 5 minutes over 5 minutes, results > 1, throttle 5 seconds, PagerDuty |
| EIP MQ search | index mq, host wpalja21b*.prprivmgmt.intraxa, "Connection timed out" |
| EIP MQ trigger | Every minute over 1 minute, results > 0, email infra MWSS, Normal |
| Claims search | index claimsda*, host claims-auto-assessment-api*, "] ERROR " excluding the stacktrace notice |
| Claims trigger | Every 10 minutes over 10 minutes, results > 0, for each result, High, 2 claims lists |
| Earlier seqs | No overlap |
| Secrets | AGPO PagerDuty key not copied |
