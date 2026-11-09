# Result

This panel counts `APIGW1015_Success_count` for the shared dashboard time and refreshes every minute. The result is one number.

Open the data model to read its constraint. The failure twin uses `Status=FAILURE`. A sample mediator line contains `Status: SUCCESS`.

```
data record(success_count = 0)
| append [
    fetch logs
    | filter contains(log.source, "apigw5500/server.log", caseSensitive:false)
    | filter contains(content, "Status: SUCCESS", caseSensitive:false)
    | summarize success_count = count()
  ]
| summarize success_count = sum(success_count)
```
