# Investigation

| Source | Finding |
|---|---|
| Splunk | `Message` is the number of distinct `host` values. The row is kept only when that number is not 4. |
| Screen DQL | `total = count()` by the coalesced name, then `filter total != 4`. |
| `count()` in that DQL | Log lines for one name. |
| `coalesce(k8s.pod.name, host.name)` | Keeps the pod name whenever the pod field is filled. |
| Host page | The visible name is `alfrescoacr-batch-innsuite-prod-0`. |
