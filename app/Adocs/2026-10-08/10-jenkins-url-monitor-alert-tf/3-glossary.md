# Glossary

| Term | What it means | Why you care |
|---|---|---|
| HTTP Monitor | Jenkins job step that calls a URL and logs the status | The data behind this alert |
| Response code 200 | HTTP success | Anything else counts as NG |
| `streamstats` | Splunk running count per group | Used to keep the last 2 runs; DQL has no direct equal |
| `configuration` lookup | Splunk table mapping Jenkins job to application and paging flag | Must be uploaded to Grail |
| Macro | Reusable Splunk search snippet in backticks | Definitions needed to migrate exactly |
| Maintenance window | Planned downtime when alerts should be quiet | `check_maintenance_window` handled this in Splunk |
| Alert identity fields | Fields that decide one problem vs many | application and name give one problem per check |
| `takeLast` | DQL aggregation returning the last value seen | Shows the latest response code on the problem |
