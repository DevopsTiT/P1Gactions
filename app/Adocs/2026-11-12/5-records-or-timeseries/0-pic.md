# Records Or Timeseries

```
Which data type on the Advanced tab?
  you want one number per minute, then a threshold
    choose Timeseries
    makeTimeseries interval 1m
    alert if the count is above 0
  the query itself returns only the bad rows
    choose Records
    filter loglevel == ERROR
    identity aws.log.group
  the query returns every line
    Records stays open during START and END
```
