# Investigation

| What was checked | Finding |
|---|---|
| Edit Alert screenshot | Search `index=network* sourcetype=asa_networksyslog *Windows_LDAP as FAILED*` |
| Schedule and trigger | Every minute, last 1 minute, more than 3 results, once, Critical, PagerDuty and email |
| Terraform provider docs | Resource `dynatrace_davis_anomaly_detectors`, SaaS only, platform token or OAuth client |
| Required blocks | `analyzer`, `event_template`, `execution_settings` plus title, description, enabled, source |
| Unknowns | Real bucket name and whether `sourcetype` exists in Grail; handled with variables |
