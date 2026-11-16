# Splunk Style Status Table

```
576 rows already found
  content is MG_Result.MG_Status EIP_UP
  job name has WPALJA21BC or WPALJA21B9
        |
        v
read host from restapi.url
read status from the JSON
        |
        v
two columns
  host
  MG_Result.MG_Status
```

| Splunk column | Where it comes from |
|---|---|
| `host` | The name in `restapi.url`, before the port. |
| `MG_Result.MG_Status` | The value in `content`. These rows show `EIP_UP`. |

## Summary

Keep the filter that returned 576 rows. Parse the host from the URL and the status from the JSON, then show only those two columns. That is the Splunk `table host MG_Result.MG_Status` shape.

## Investigation

The notebook query returned 576 records for Last 24 hours. `log.source` is `restapi-monitoring`. Job names on the rows are `EIP MG UP check WPALJA21B9` and `EIP MG UP check WPALJA21BC`.

`content` is:

```
{"MG_Result":{"MG_Status":"EIP_UP"}}
```

`checkStatus` is already `EIP_UP`. The URL starts with `http://WPALJA21B9.prprivmgmt.intraxa:` or the BC host. The Splunk panel shows `host` and `MG_Result.MG_Status` only.

## Result

Last 24 hours, two columns:

```
fetch logs, from: now()-24h
| filter log.source == "restapi-monitoring"
    and (
      contains(restapi.job_name, "WPALJA21BC", caseSensitive:false)
      or contains(restapi.job_name, "WPALJA21B9", caseSensitive:false)
    )
| parse restapi.url, "LD '://' LD:host ':'"
| parse content, "LD 'MG_Status\":\"' LD:checkStatus '\"'"
| fieldsAdd `MG_Result.MG_Status` = checkStatus
| fields host, `MG_Result.MG_Status`
```

The panel window is the last 3 minutes. Use the same query with `from: now()-3m`.

One current row per host:

```
fetch logs, from: now()-24h
| filter log.source == "restapi-monitoring"
    and (
      contains(restapi.job_name, "WPALJA21BC", caseSensitive:false)
      or contains(restapi.job_name, "WPALJA21B9", caseSensitive:false)
    )
| parse restapi.url, "LD '://' LD:host ':'"
| parse content, "LD 'MG_Status\":\"' LD:checkStatus '\"'"
| sort timestamp desc
| summarize { `MG_Result.MG_Status` = takeFirst(checkStatus) }, by: { host }
```

## Data flow map

```
restapi.url
  host before the port
content
  MG_Status EIP_UP
        |
        v
host | MG_Result.MG_Status
```

## Related files

| File | Purpose |
|---|---|
| `15-splunk-style-status-table.dql` | The two-column table and the one-row-per-host table. |
| `0-pic.md` | From the JSON to the two columns. |
| `1-investigation.md` | The 576-row result. |
| `2-result.md` | The queries to paste. |
| `3-glossary.md` | The words. |
| `15-splunk-style-status-table-follow.txt` | The same steps for a phone. |
| `15.sh` | Copy commands. |

Commands: [15.sh](15.sh)
