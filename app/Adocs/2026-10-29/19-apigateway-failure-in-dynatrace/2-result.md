# Result

The dialog counts failure events in the mediator log for the dashboard time, every minute.

Dynatrace check:

```
fetch logs
| filter contains(log.source, "apigw5500/server.log", caseSensitive:false)
| limit 5
```

Failure tile:

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

Dashboard time Last 15 minutes. Refresh 1 minute. Single value on `failure_count`. Color 1 and above red.
