# Investigation

| Source | Finding |
|---|---|
| Alert | `Prod_PnC_Alfrescoacr_BatchPODFrozen_High`. |
| Splunk | `Message` is the number of host rows. The row stays only when `Message` is not 4. |
| DQL `coalesce` | Pod name wins whenever `k8s.pod.name` is filled. |
| DQL `total = count()` | Log lines for each name. |
| DQL `filter total != 4` | Keeps names whose line count is not 4. |
| DQL fields | `host, total`. Splunk fields are `host="Total"` and `Message`. |
