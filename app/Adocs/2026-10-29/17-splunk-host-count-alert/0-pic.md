# Splunk Host Count Alert

```
Prod_PnC_Alfrescoacr_BatchPODFrozen_High
  read index alfrescoacr-batch
  one row per host that sent logs
  Message = how many of those rows
  Message is 4 → drop the row → Statistics 0 → alert stays quiet
  Message is any other number → keep host Total → alert has a result
  index has no events → no rows → alert also stays quiet
```

```
index alfrescoacr-batch
  events in the time window
        |
        v
one row per host
        |
        v
Message = number of those rows
        |
        +-- Message is 4 → no statistics row → alert stays quiet
        +-- Message is not 4 → one row, host Total → alert has a result
        |
        +-- no events at all → no rows → alert stays quiet
```
