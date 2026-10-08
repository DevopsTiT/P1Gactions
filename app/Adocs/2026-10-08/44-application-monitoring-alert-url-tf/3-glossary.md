# Application Monitoring URL Glossary

| Term | What it means | Why you care |
|---|---|---|
| HTTP Monitor | Jenkins job that calls an app URL and logs the status | This alert reads its console lines |
| jenkins_console | Index of Jenkins build console output | Text, not JSON, so the code is parsed with a pattern |
| replacePattern | DQL replace using a DPL pattern | Removes `/<build>/console` from the path |
| streamstats index<=2 | Splunk keeps the newest 2 runs per job | Approximated as 2 failures and no success in the window |
| PagerDuty Disable | The Splunk action does not page | So pagerduty.enabled is "0" |
