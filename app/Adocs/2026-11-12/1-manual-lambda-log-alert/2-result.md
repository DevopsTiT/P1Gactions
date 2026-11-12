# Result

```
fetch logs
| filter contains(aws.log.group, "/aws/lambda/", caseSensitive:false)
| filter loglevel == "ERROR"
| makeTimeseries error_count = count(), interval:1m
```

Settings → Analyze and alert → Alerts → All alerts → Custom alerts → New alert → Create your own custom alert.

Static threshold. Alert if metric is above 0. Title and event name: Lambda log ERROR.
