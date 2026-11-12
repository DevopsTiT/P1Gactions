# Manual Lambda Log Alert

```
Notebook shows Lambda logs
  the query is a table of lines
    a custom alert needs a timeseries
  819 lines in 2 hours include INFO
    alerting on every line stays open
  keep aws.log.group containing /aws/lambda/
    keep loglevel ERROR
    makeTimeseries count per 1 minute
  Settings → Analyze and alert → Alerts → Custom alerts
    static threshold
    alert if the count is above 0
    Create
```
