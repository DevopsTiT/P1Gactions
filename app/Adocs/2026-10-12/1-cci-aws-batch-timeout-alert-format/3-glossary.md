# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Terraform provider | Plugin that defines which resource types exist. | Unknown resource types fail at plan. |
| `dynatrace_davis_anomaly_detectors` | Terraform resource for Dynatrace anomaly detectors, including Records detectors. | The correct type for this alert. |
| Records detector | Runs a DQL query every minute and opens a problem when rows are returned. | Replaces a Splunk "results > 0" alert. |
| `alertIdentityFields` | Fields that decide whether rows belong to the same problem. | Prevents duplicate problems each minute. |
| `event_template` | Properties copied onto the problem (name, severity, flags). | `pagerduty.enabled` here tells the workflow to page. |
| Workflow | Dynatrace automation that reacts to problems and sends PagerDuty and email. | Where notifications belong. |
| Integration key | PagerDuty secret for creating incidents on a service. | Never store it in Git. |
| `aws.log_group` | Log field holding the CloudWatch log group name. | Used to find the Lambda's logs. |
| "Task timed out" | Message Lambda writes when it hits its timeout. | The event being alerted on. |
| `$name$` | Splunk token for the alert name. | Does nothing in Dynatrace. |
