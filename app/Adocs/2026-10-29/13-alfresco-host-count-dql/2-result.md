# Result

Returns a row only when the distinct host count is not 4. Set the time picker to 10/28/2026 1:00 PM through 10/29/2026 1:43 PM.

```
fetch logs
| filter contains(log.source, "alfrescoacr-batch", caseSensitive:false)
| summarize by: { host.name }
| summarize Message = count()
| fieldsAdd host = "Total"
| filter Message != 4
| fields host, Message
```

Always show the count:

```
fetch logs
| filter contains(log.source, "alfrescoacr-batch", caseSensitive:false)
| summarize Message = countDistinct(host.name)
| fieldsAdd host = "Total"
| fields host, Message
```

0 records on the first query means `Message` is 4.
