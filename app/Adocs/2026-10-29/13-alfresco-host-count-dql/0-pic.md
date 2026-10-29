# Alfresco Host Count DQL

```
Splunk search on alfrescoacr-batch
  one row per host
  count those rows → Message
  Message is 4 → Statistics stays empty
  Message is not 4 → one row, host Total
DQL
  same time window
  count distinct host.name
  filter Message != 4
  0 records → same quiet result as Statistics (0)
```

```
alfrescoacr-batch logs
 time window 10/28 1:00 PM → 10/29 1:43 PM
 176,642 events
        |
        v
one row per host.name
        |
        v
Message = how many hosts
        |
        +-- Message is 4 → no output row
        |
        +-- Message is not 4 → host Total, Message = that count
```
