# PC2 Batch AfterBind Exception DQL Result

| Item | Value |
|---|---|
| Host filter | startsWith host.name or k8s.pod.name "pc2-batch-inssuite-prod-" |
| Phrases | "Exception occured for job" and "during afterBind_Adj process", case ignored |
| Output | timestamp, host.name, k8s.pod.name, content |

## If empty

| Check | Result | Meaning |
|---|---|---|
| Check 1 | 0 | Logs not in Dynatrace. Request forwarding. |
| Check 1 | Rows | Use the field that holds the pod name. |
| Check 2 | Rows | Phrase exists. Copy host or pod value. |
