# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Functional check | Jenkins job that runs a real user flow against an application | Fails when the app is broken, not just down |
| `json:jenkins:old` | Splunk sourcetype for Jenkins job statistics in JSON | Holds job_name, job_result, job_duration |
| `group-jobs` | Real Time check jobs that run several tests | May report per test instead of job_result |
| `pager_duty = 0` | Configuration flag: do not page this application | This generic alert only covers these apps |
| Alert Status Manager | Custom Splunk alert action handling email and PagerDuty | Here: email Production, PagerDuty off |
| `join type=left` | Splunk join that keeps rows without a match | Used to attach maintenance remarks |
| `parse content, "JSON:j"` | DQL parses the log line as JSON into `j` | Gives job_name and job_result |
