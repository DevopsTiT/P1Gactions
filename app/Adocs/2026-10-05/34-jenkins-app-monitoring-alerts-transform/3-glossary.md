# Jenkins App Monitoring Glossary

| Term | What it means | Why you care |
|---|---|---|
| HTTP Monitor | Jenkins job that calls an application URL and logs the response code | Source of the URL detector |
| Functional test job | Jenkins job that runs test cases against an application | Source of the functional detector |
| `streamstats ... index<=2` | Splunk trick to keep the last 2 results per check | Becomes the look-back window rule |
| Alert Status Manager | Splunk app that tracks alert state and sends email and PagerDuty | Replaced by Dynatrace problems and the standard flow |
| Macro | Saved Splunk search fragment called with backticks | Logic hidden from the alert; definitions needed |
| Iterative expression `x[]` | DQL syntax that applies an expression to every element of an array | Checks each minute of the timeseries |
| `expand` | DQL command that turns one record with an array into one record per element | One record per test case |
| `pagerduty.enabled` | Event property set from the configuration lookup | Lets the standard flow skip paging for email-only apps |
