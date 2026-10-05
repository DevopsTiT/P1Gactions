# Glossary

| Term | What it means |
|---|---|
| Lambda timeout | AWS stops a Lambda function that runs longer than its timeout and logs "Task timed out" |
| `/aws/lambda/<name>` | The CloudWatch log group AWS creates for each Lambda function |
| PagerDuty integration key | The routing key for one PagerDuty service; it acts like a password for sending pages |
| Rotate | Replace a key with a new one so the old one stops working |
| `sensitive = true` | Terraform setting that hides a variable's value in plan output |
| `dynatrace_davis_anomaly_detectors` | Terraform resource for a DQL threshold alert |
| `dynatrace_log_events` | Terraform resource that raises an event per matching log line |
| Sliding window | Number of recent minutes the alert checks |
