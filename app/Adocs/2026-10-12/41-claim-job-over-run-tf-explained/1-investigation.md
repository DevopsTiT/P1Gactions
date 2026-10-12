# Claim Job Over Run TF Explained Investigation

| What was explained | Where |
|---|---|
| Terraform and provider blocks | Setup |
| Detector title, description, enabled | Header |
| Analyzer type | Runs the query every minute, rows mean problem |
| Query, line by line | Filter, parse, claims filter, summarize per run, open and 15+ minutes |
| Identity `job_name` | One problem per stuck job |
| Event template | Name, severity medium, PagerDuty 0 |
| Source file | Answer 40, `40-claim-job-over-run-tf.tf` |
