# Splunk Alerts To DQL

```
PODFrozen search
  one name per log
    pod name contains the index token → use k8s.pod.name
    else host name contains it → use host.name
  Message = how many different names
  Message equals the expected number → no row
  Message is any other number → one Total row
text search
  same name filter
  plus the exception text in content
  a row means the text was found
alfrescoacr
  drop names that contain alfrescoacr-batch
  expected number is 3
```

```
PODFrozen
  log line
    → unit = matching pod name, else matching host name
    → Message = countDistinct(unit)
    → Message is the expected number → no row
    → Message is any other number → host Total, Message

Text check
  log line for that index token
    → content contains the phrase
    → one row per matching line
```
