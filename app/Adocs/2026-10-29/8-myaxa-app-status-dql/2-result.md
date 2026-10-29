# Result

The My Axa tile returns one status for `agj-myaxa`: `NG` when the newest `jobs` text contains `NG :`, otherwise `OK`. This run returned 0 records in a two-hour window, so there is no status. Blank is not `OK`.

Which application names exist in the current window:

```
fetch events
| filter event.type == "CUSTOM_INFO"
| filter isNotNull(application)
| summarize event_count = count(), by: { application }
| sort application asc
```

One newest status per application:

```
fetch events
| filter event.type == "CUSTOM_INFO"
| filter isNotNull(application)
| fieldsAdd application_status = if(contains(jobs, "NG :", caseSensitive:false), "NG", else: "OK")
| sort timestamp desc
| summarize status = takeFirst(application_status), last_seen = takeFirst(timestamp), by: { application }
| sort application asc
```

An application with no event in the window does not appear. Only `agj-myaxa` is on the screenshot. Add other names only after the count query shows them.
