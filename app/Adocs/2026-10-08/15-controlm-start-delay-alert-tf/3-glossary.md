# Control-M Start Delay Glossary

| Term | What it means | Why you care |
|---|---|---|
| Start Time Delay | Control-M message saying a job did not start on time | This is the event the alert catches |
| controlm_alert | Splunk sourcetype for Control-M alert messages | The detector filters on its log source |
| JOB_CODE | job_name plus current_time | Unique key, so each delay is one problem |
| RunInfo | Run count, plus Method for APL- jobs | Shown in the title so operators know how to respond |
| 未登録 | "Not registered" | Shown when the job has no Method in addresslist |
| Lookup | A CSV table uploaded to Grail | Adds Method, Main, Sub, CMD_STRING, TITLE, BODY |
| Records detector | Dynatrace detector where each returned row is a violation | Matches Splunk "For each result" |
| alertIdentityFields | Fields that decide which rows share one problem | `JOB_CODE` gives one problem per delay |
| Throttle | Splunk setting that stops repeat alerts | Dynatrace keeps one open problem per identity instead |
