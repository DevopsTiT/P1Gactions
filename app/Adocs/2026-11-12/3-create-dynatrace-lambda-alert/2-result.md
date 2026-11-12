# Result

Static threshold. Alert if the metric is above 0. Title and event name: Lambda log ERROR.

```
fetch logs
| filter contains(aws.log.group, "/aws/lambda/", caseSensitive:false)
| filter loglevel == "ERROR"
| makeTimeseries error_count = count(), interval:1m
```
