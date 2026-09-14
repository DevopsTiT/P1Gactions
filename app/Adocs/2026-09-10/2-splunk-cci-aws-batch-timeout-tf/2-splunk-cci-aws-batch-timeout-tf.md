# Splunk CCI AWS Batch Timeout TF

```
Splunk UI alert
  → map fields to splunk_saved_searches
  → fix broken index quote in SPL
  → PagerDuty key via variable (not plain in .tf)
```

| Key point | Detail |
| --- | --- |
| Alert name | `CCI_AWS_Batch Time Out` |
| Index | `cci-fa-comm-calc` (sheet: Migration Yes, retention 100) |
| Schedule | Cron `*/5 * * * *`, window `-5m` → `now` |
| Trigger | Number of results greater than 0, once |
| Action | PagerDuty + custom details `{"job_label":"$job.label$"}` |

## Summary

Terraform for the Splunk scheduled alert shown in the Edit Alert UI. Search was corrected so the index name is properly quoted. PagerDuty integration key is a sensitive variable.

## Files

| File | Purpose |
| --- | --- |
| `alerting_cci_aws_batch_time_out.tf` | Alert resource |
| `variables.tf` | PD key + ACL |
| `provider.tf` | splunk/splunk provider stub |
| `terraform.tfvars.example` | Example values (no real secret) |

## Commands

See `2.sh`.
