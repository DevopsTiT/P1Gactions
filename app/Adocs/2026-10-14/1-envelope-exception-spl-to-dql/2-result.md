# Envelope Exception SPL To DQL Result

| Item | Value |
|---|---|
| Main query | In `1-envelope-exception-spl-to-dql.dql` |
| Time range | Last 24 hours (change as needed) |
| Time zone | Asia/Tokyo |
| Keyword checks | Case sensitive, same as Splunk match() |
| Search filter | Case insensitive, same as Splunk search |

## If empty

| Name found in | Change |
|---|---|
| host.name, other case | Use lower(host.name) |
| log.source | Use contains(log.source, ...) |
| Nowhere | Logs not in Dynatrace yet |
