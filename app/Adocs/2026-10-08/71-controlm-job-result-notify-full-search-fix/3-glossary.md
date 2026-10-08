# Control-M Job Result Notify Glossary

| Term | What it means | Why you care |
|---|---|---|
| Control-M | The batch job scheduler. | This alert watches its job results. |
| Abend | Abnormal end: the job crashed or failed. | The alert only covers jobs that abended in the last 24 hours. |
| order_id + isn | The run's order ID plus its run sequence number. | Together they identify one run, which is the problem identity. |
| 対応方法 | How to respond to the job's failure (the playbook). | Shown in the 異常終了 title, or "N/A" if not set. |
| CMD_STRING | The command or member the job runs. | Helps the on-call person see what failed. |
| SpecificContact Email | The contact for a specific job. | Splunk CCs it; in Dynatrace it is a field a workflow can use. |
| Lookup | A table loaded into Grail and joined to log rows. | The three Control-M CSVs must be uploaded before apply. |
| Throttle | Splunk setting that stops repeat mails for the same JOB_CODE. | In Dynatrace, one problem per run does the same job. |
