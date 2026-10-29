# Result

Logs 0 means Dynatrace linked no log line to this host in the last 2 hours. The page does not say the process wrote nothing to disk.

```
fetch logs, from: now()-2h
| filter contains(host.name, "alfrescoacr-batch-innsuite-prod-0", caseSensitive:false)
| summarize log_count = count()
```

```
fetch logs, from: now()-24h
| filter contains(host.name, "alfrescoacr-batch-innsuite-prod-0", caseSensitive:false)
| summarize log_count = count()
```

```
fetch logs, from: now()-24h
| filter contains(content, "alfrescoacr-batch-innsuite-prod-0", caseSensitive:false)
| summarize log_count = count()
```

A zero on all three confirms the host page. The lines Splunk has for `alfrescoacr-batch` are not attached to this Dynatrace host.
