# Result

Check the log first, with the notebook time set to Last 15 minutes:

```
fetch logs
| filter contains(log.source, "apigw5500/server.log", caseSensitive:false)
| limit 5
```

Failure tile. Leave the time picker on the dashboard so this follows Last 15 minutes:

```
data record(failure_count = 0)
| append [
    fetch logs
    | filter contains(log.source, "apigw5500/server.log", caseSensitive:false)
    | filter contains(content, "Status: FAILURE", caseSensitive:false)
    | summarize failure_count = count()
  ]
| summarize failure_count = sum(failure_count)
```

Success tile: same query with `Status: SUCCESS` and `success_count`.

Host table:

```
fetch logs
| filter contains(log.source, "apigw5500/server.log", caseSensitive:false)
| filter contains(content, "Status: FAILURE", caseSensitive:false)
| summarize failure_count = count(), by: { host.name }
| sort failure_count desc
```

Visualization for the counts is Single value. The host query is a Table. Color 1 and above red on the failure tile. Refresh the dashboard every 1 minute.
