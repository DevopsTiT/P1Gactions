# Result

Discovery:

```
fetch logs, from: now()-3m
| filter contains(log.source, "eip_mg_up_check", caseSensitive:false)
    or contains(content, "EIP UP Check", caseSensitive:false)
| limit 5
```

Table tile:

```
data record(unit = "WPALJA21BC"), record(unit = "WPALJA21B9")
| lookup [
    fetch logs, from: now()-3m
    | filter contains(log.source, "eip_mg_up_check", caseSensitive:false)
        or contains(content, "EIP UP Check", caseSensitive:false)
    | fieldsAdd unit = if(contains(host.name, "WPALJA21BC", caseSensitive:false) or contains(content, "WPALJA21BC", caseSensitive:false), "WPALJA21BC", else: if(contains(host.name, "WPALJA21B9", caseSensitive:false) or contains(content, "WPALJA21B9", caseSensitive:false), "WPALJA21B9", else: null))
    | filter isNotNull(unit)
    | sort timestamp desc
    | summarize last_seen = takeFirst(timestamp), line = takeFirst(content), by: { unit }
  ], sourceField: unit, lookupField: unit
| fields unit, last_seen, line
```

Add a DQL tile. Choose Table. Title it `EIP MG UP check`. Leave auto-refresh off. A blank `last_seen` means that host sent no event in 3 minutes.
