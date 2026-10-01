# Glossary

| Term | What it means |
|---|---|
| OPEN workflow | The workflow that really creates the SILVA incident and the PagerDuty page. |
| DRY_RUN | Build and log only, never send. |
| ALLOW_SAMPLE_POST | Allow sending for the sample event from the Run button. Keep false. |
| correlation_id | Problem ID stored on the incident, used to block a second open ticket. |
| dedup_key | PagerDuty key that groups repeats into one PagerDuty incident. |
| Outbound allowlist | Dynatrace setting listing hosts that workflows may call. |
