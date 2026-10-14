# ESBv4 NetSuite HTTP Error Result

```
fetch logs, from:now()-24h
| filter contains(host.name, "esbv4", caseSensitive:false)
    or contains(k8s.namespace.name, "esbv4", caseSensitive:false)
    or contains(k8s.pod.name, "esbv4", caseSensitive:false)
    or contains(dt.system.bucket, "esbv4", caseSensitive:false)
| filter contains(content, "Error sending HTTP request to https://3903926.restlets.api.netsuite.com:443", caseSensitive:false)
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, log.source, content
```

If 0 rows, run the check query in the `.dql` file.
