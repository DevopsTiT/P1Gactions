# PC2 Batch AfterBind Exception DQL Investigation

| Item | Value |
|---|---|
| Base search | index="pc2-batch" host="pc*" |
| Events | 1,314,737 |
| Hosts | pc2-batch-inssuite-prod-1 (825,823), pc2-batch-inssuite-prod-0 (502,075) |
| Source | s3://axa-gi-jp-logforwarders-prod/2026/10/14/... |
| Line format | 2026-10-14 09:16:38,299 INFO [MW-Writer[66]-4] KPI.Messaging ... |
| Target search | "Exception occured for job" AND "during afterBind_Adj process", fields + _raw |
| Unknown | Whether pc2 batch logs reach Dynatrace |
