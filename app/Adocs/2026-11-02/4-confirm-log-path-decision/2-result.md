# Result

| Check | Do this | Confirmed when |
|---|---|---|
| Purpose | Compare host pages CEAA20F7 and CEAA9026 | CEAA20F7 shows the ICM app path. |
| File in Dynatrace | Notebook DQL grouped by `host.name` | The three known hosts return rows. |
| File on disk | `ls -l` on CEAA20F7 | The path exists and the date is recent. |
| Host group | Properties, then Hosts filtered by the group | The id matches and every member should send the file. |
| Mask | Settings, Log Monitoring, Sensitive data masking | An enabled rule covers this path and this group. |
