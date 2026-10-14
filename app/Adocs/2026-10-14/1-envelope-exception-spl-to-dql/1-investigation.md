# Envelope Exception SPL To DQL Investigation

| Splunk stage | DQL step |
|---|---|
| `(host="biloss-envelope-list-prod" OR host="start-envelope-executions-prod")` | `filter in(host.name, array(...))` |
| `search ("Exception" OR "ERROR")` | `contains(..., caseSensitive:false)` |
| `eval matched_keywords=mvappend(if(match(...)), ...)` | `arrayRemoveNulls(array(if(contains(...), "name"), ...))` |
| `eval time=strftime(_time, "%Y-%m-%d %H:%M:%S %Z")` | `formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")` |
| `table time host matched_keywords _raw` | `fields time, host.name, matched_keywords, content` |
| Unknown | Whether the Splunk host value is host.name in Dynatrace |
