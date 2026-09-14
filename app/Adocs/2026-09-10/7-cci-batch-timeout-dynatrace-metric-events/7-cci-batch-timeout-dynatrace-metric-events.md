# CCI Batch Timeout Dynatrace TF

```
Splunk CCI_AWS_Batch Time Out (pic 4)
  → log metric (Task timed out, not DEBUG)
  → dynatrace_metric_events Critical + Warning
  → same shape as ContactManager MQ (pics 1–3)
```

| Key point | Detail |
| --- | --- |
| Template | `alerting_contactmanager_mq.tf` (`dynatrace_metric_events`) |
| Splunk meaning | Any `Task timed out` in `cci-fa-comm-calc` every 5m |
| Dynatrace map | Log metric count ABOVE 0 → ERROR event |
| File | `alerting_cci_aws_batch_timeout.tf` |

## Summary

Pics 1–3 are Dynatrace metric events. Pic 4 is a Splunk log alert. This pack bridges them: create a log metric for the Splunk search, then Critical/Warning metric events in the ContactManager style.

## Mapping

| Splunk (pic 4) | Dynatrace Terraform |
| --- | --- |
| index + Task timed out | Log metric matcher + optional aws.log_group |
| message!=DEBUG | not matchesPhrase(content, "DEBUG") |
| Results > 0 | threshold = 0, ABOVE |
| Cron every 5m | Critical samples = 5, violating = 1 |
| PagerDuty | Use Problem notification separately (not in metric_events) |

## Thresholds vs ContactManager MQ

| Setting | CM MQ Critical | CCI Timeout Critical |
| --- | --- | --- |
| Metric | guidewire.messaging.* | log.cci.aws.batch.task_timed_out |
| Threshold | 100 | 0 (any timeout) |
| Samples | 10 / violate 3 | 5 / violate 1 |

## Files

| File | Purpose |
| --- | --- |
| `alerting_cci_aws_batch_timeout.tf` | Log metric + error + warning |
| `7.sh` | Apply reminders |

## Note

If aws.log_group is missing on log records, use the looser query commented in the .tf file.
