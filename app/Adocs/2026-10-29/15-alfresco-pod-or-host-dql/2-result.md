# Result

Alert query. Returns a row only when the distinct pod-or-host name count is not 4.

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

List query:

```
fetch logs
| filter contains(k8s.pod.name, "alfrescoacr-batch", caseSensitive:false)
    or contains(host.name, "alfrescoacr-batch", caseSensitive:false)
    or contains(log.source, "alfrescoacr-batch", caseSensitive:false)
| fieldsAdd from_pod = if(contains(k8s.pod.name, "alfrescoacr-batch", caseSensitive:false), k8s.pod.name, else: null)
| fieldsAdd from_host = if(contains(host.name, "alfrescoacr-batch", caseSensitive:false), host.name, else: null)
| fieldsAdd unit = coalesce(from_pod, from_host)
| filter isNotNull(unit)
| summarize log_count = count(), by: { unit, k8s.pod.name, host.name }
| sort unit asc
```

0 records on the alert query means `Message` is 4.
