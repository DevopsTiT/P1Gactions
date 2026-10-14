# BILoss Upload To CMX Investigation

| What was checked | Finding |
|---|---|
| Host in SPL | One host: `BILoss-upload-to-cmx-prod`. |
| Search phrases | Three phrases joined with OR. |
| Splunk `search` case | Ignores case. |
| Splunk `match()` case | Case-sensitive. |
| Pattern reuse | Same as seq 8, with one host and three phrases. |
| Risk | Host may appear as a pod name, or logs may only go to S3 and Splunk. |
