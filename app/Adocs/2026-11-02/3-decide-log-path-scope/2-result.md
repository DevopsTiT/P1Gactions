# Result

Stop at the first no.

| Step | No means |
|---|---|
| Need the FileNet host, not only claim-payment | Leave the group out. |
| File exists and is growing on CEAA20F7 | Do not add the matcher. |
| Every host in the group should send it | Do not use this host-group scope. |
| Mask already matches this path | Do not set `send_to_storage` yet. |

All four yes: add `dynatrace_log_custom_source` and `dynatrace_log_storage` in the same change.
