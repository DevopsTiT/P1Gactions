# Alfresco Pod Or Host DQL

```
Splunk Message
  one name per event, from the host field
  Message = how many different names
  Message is 4 → no output row
Dynatrace name for the same check
  pod name contains alfrescoacr-batch → use k8s.pod.name
  else host name contains it → use host.name
  log.source can find the line
  Message = how many different units
  Message is 4 → no output row
```

```
log line
        |
        +--> k8s.pod.name contains alfrescoacr-batch → from_pod
        +--> host.name contains alfrescoacr-batch → from_host
        +--> log.source contains alfrescoacr-batch → line is eligible
        |
        v
unit = pod name if it matched, else host name
        |
        v
Message = countDistinct(unit)
        |
        +-- Message is 4 → no row
        +-- Message is not 4 → host Total, Message = that count
```
