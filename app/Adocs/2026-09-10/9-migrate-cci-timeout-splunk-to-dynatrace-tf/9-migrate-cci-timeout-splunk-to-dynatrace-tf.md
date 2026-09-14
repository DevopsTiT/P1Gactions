# Migrate CCI Timeout Splunk To Dynatrace

```
Splunk alert (seq 8)
  → Dynatrace log metric
  → dynatrace_metric_events Critical (+ Warning)
  → Problem notification → PagerDuty / ServiceNow
```

| Key point | Detail |
| --- | --- |
| Source | Splunk `CCI_AWS_Batch Time Out` |
| Target | Dynatrace Grail logs + metric events |
| File | `alerting_cci_aws_batch_timeout_dynatrace.tf` (no variables) |

## Summary

One Terraform file migrates the Splunk timeout alert into Dynatrace using the same style as `alerting_contactmanager_mq.tf`: log metric first, then Critical/Warning metric events.

## Mapping

| Splunk | Dynatrace |
| --- | --- |
| index + Task timed out | `dynatrace_log_metrics` query |
| message!=DEBUG | `not matchesPhrase(...,"DEBUG")` |
| results > 0 | threshold `0` ABOVE |
| cron every 5m | samples `5`, violating `1` |
| PagerDuty action | Problem notification (separate) |

## Verify DQL (after apply)

```dql
fetch logs
| filter contains(content, "Task timed out")
| filter not contains(content, "DEBUG")
| summarize hits = count(), by: { host.name }
| sort hits desc
```

## Files

| File | Purpose |
| --- | --- |
| `alerting_cci_aws_batch_timeout_dynatrace.tf` | Full Dynatrace config |
| `9.sh` | Plan reminders |
