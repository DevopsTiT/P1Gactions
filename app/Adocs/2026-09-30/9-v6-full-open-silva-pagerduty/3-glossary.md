# Glossary

| Term | What it means | Why you care |
|---|---|---|
| OPEN workflow | The workflow that creates tickets when a problem starts | This file |
| CLOSE workflow | The workflow that resolves tickets when a problem ends | Must use the same keys |
| correlation_id | SNOW field holding the Dynatrace problem id | Duplicate check and CLOSE lookup |
| dedup_key | PagerDuty key that groups trigger and resolve events | Same problem never pages twice |
| Routing key | PagerDuty integration key for a service | Decides which PagerDuty service is paged |
| DRY_RUN | Setting that builds but does not send | Safe testing |
| ALLOW_SAMPLE_POST | Setting that lets a manual Run post the sample event | Keep false to avoid fake tickets |
| Allowlist | Dynatrace list of hosts workflows may call | Calls fail without it |
