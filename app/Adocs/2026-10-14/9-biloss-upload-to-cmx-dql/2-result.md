# BILoss Upload To CMX Result

```
fetch logs, from:now()-24h
| filter lower(host.name) == "biloss-upload-to-cmx-prod"
| filter contains(content, "CMX Error", caseSensitive:false)
    or contains(content, "RuntimeException", caseSensitive:false)
    or contains(content, "Failed to initialize clients", caseSensitive:false)
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(contains(content, "CMX Error"), "CMX Error"),
    if(contains(content, "RuntimeException"), "RuntimeException"),
    if(contains(content, "Failed to initialize clients"), "Failed to initialize clients")
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, matched_keywords, content
```

If 0 rows, run the check query in `9-biloss-upload-to-cmx-dql.dql`.
