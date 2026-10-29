# Result

The screen DQL does not match the Splunk alert. Replace it with:

```
fetch logs
| filter contains(k8s.pod.name, "alfrescoacr-batch", caseSensitive:false)
    or contains(host.name, "alfrescoacr-batch", caseSensitive:false)
    or contains(log.source, "alfrescoacr-batch", caseSensitive:false)
| fieldsAdd from_pod = if(contains(k8s.pod.name, "alfrescoacr-batch", caseSensitive:false), k8s.pod.name, else: null)
| fieldsAdd from_host = if(contains(host.name, "alfrescoacr-batch", caseSensitive:false), host.name, else: null)
| fieldsAdd unit = coalesce(from_pod, from_host)
| filter isNotNull(unit)
| summarize Message = countDistinct(unit)
| fieldsAdd host = "Total"
| filter Message != 4
| fields host, Message
```

0 records means the name count is 4.
