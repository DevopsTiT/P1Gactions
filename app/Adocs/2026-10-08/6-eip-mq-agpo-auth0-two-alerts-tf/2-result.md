# Result

| Item | Result |
|---|---|
| Terraform | `6-eip-mq-agpo-auth0-two-alerts-tf.tf` |
| Resource | `eip_agpo_alerts` with 2 keys |
| MQ detector | medium, pagerduty `"0"`, 2-minute window |
| AGPO detector | high, pagerduty `"1"`, count > 1 in 5 minutes |
| To confirm | MQ host and file ingested; AGPO pod name field |
