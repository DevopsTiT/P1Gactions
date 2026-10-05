# Glossary

| Term | What it means |
|---|---|
| CloudWatch log group | Where AWS stores logs for one service or job, such as a Glue job |
| `aws.log_group` | The Dynatrace log field that holds the CloudWatch log group name |
| AWS Glue | AWS service that runs data jobs (ETL) |
| "skipping table" | The message the Glue job writes when it skips a table |
| `dynatrace_davis_anomaly_detectors` | Terraform resource for a DQL-based threshold alert |
| `dynatrace_log_events` | Terraform resource that raises an event for each matching log line |
| Sliding window | Number of recent minutes checked |
| Violating samples | How many of those minutes must break the threshold |
| `makeTimeseries` | DQL command that turns log lines into a count per time interval |
| `$name$` | A Splunk alert token; it has no meaning in Dynatrace |
