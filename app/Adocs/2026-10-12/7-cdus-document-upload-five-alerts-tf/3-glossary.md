# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Records detector | Runs a DQL query every minute; rows open a problem. | Replaces all five alerts. |
| `pagerduty.enabled` | Tells the workflow whether to page. | `"1"` for all five. |
| `Runtime.ExitError` | Lambda process crashed or exited early. | What Alerts 1 and 5 detect. |
| `ETIMEDOUT` | Node.js connection timeout error code. | The real target of "ETIM". |
| CMX | Document management system receiving uploads. | Alert 4 watches CMX failures. |
| Throttle | Silence period after an alert fires. | Alert 5 had 8 hours. |
| False positive | An alert that fires when nothing is wrong. | With PagerDuty, it wakes someone up. |
