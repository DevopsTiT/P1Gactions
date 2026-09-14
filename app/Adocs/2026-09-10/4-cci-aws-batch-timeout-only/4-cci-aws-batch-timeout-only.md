# CCI AWS Batch Time Out Only

```
Need Splunk alert as code?
  → Use this pack only (one alert: CCI_AWS_Batch Time Out)
  → Ignore seq 3 multi-index files unless you want those later
```

| Key point | Detail |
| --- | --- |
| Scope | **Only** `CCI_AWS_Batch Time Out` |
| Index | `cci-fa-comm-calc` |
| Source | `/aws/lambda/cci-fa-comm-calc` |
| Provider | `splunk/splunk` → `splunk_saved_searches` |

## Summary

Single Terraform alert matching your Splunk Edit Alert UI. No other indexes.

## Settings (from UI)

| UI | Terraform |
| --- | --- |
| Title `CCI_AWS_Batch Time Out` | `name` |
| Search Task timed out | `search` (quote fixed) |
| Cron `*/5 * * * *` | `cron_schedule` |
| Last 5 minutes | `-5m` / `now` |
| Results > 0, once | `number of events` / `greater than` / `0` / `alert_digest_mode = true` |
| Expires 24h | `alert_expires = "24h"` |
| PagerDuty + custom details | `actions = "pagerduty"` + key var |

## Files

| File | Purpose |
| --- | --- |
| `alerting_cci_aws_batch_time_out.tf` | The alert |
| `variables.tf` | PagerDuty key + ACL |
| `provider.tf` | Splunk provider |
| `terraform.tfvars.example` | Secret placeholder |

## Commands

See `4.sh`.
