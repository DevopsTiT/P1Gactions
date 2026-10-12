# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute; rows open a problem. | Replaces the hourly alert. |
| `alertIdentityFields` | Fields that group rows into one problem. | Replaces the throttle. |
| `pagerduty.enabled` | Tells the workflow whether to page. | `"0"` here. |
| SurveyMonkey | Online survey service. | Source of the files. |
| S3 | AWS object storage. | Destination of the files. |
