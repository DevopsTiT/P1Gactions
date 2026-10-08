# Application Monitoring Function Glossary

| Term | What it means | Why you care |
|---|---|---|
| Functional job | `applications/...` Jenkins job that tests app features | This alert counts its results |
| Real Time job | `group-jobs/...` Jenkins job | Its results are ignored here |
| pager_duty "0" | App does not page in the configuration lookup | Defines which apps this alert covers |
| build_url | Jenkins path of one build | Joins build results to console lines |
| join type=left | Splunk keeps all rows even with no match | DQL `lookup` behaves the same way |
| mantenance | Splunk's typo of maintenance | The search text must match the console text exactly |
