# Glossary

| Term | What it means | Why you care |
|---|---|---|
| AWS Glue | Managed ETL service that runs data jobs. | The source of these logs. |
| Records detector | Runs a DQL query every minute; rows open a problem. | Replaces the scheduled alert. |
| `alertIdentityFields` | Fields that group rows into one problem. | One problem per log group. |
| `pagerduty.enabled` | Tells the workflow whether to page. | `"0"` here. |
| `$name$` | Splunk token for the alert name. | Does nothing in Dynatrace. |
