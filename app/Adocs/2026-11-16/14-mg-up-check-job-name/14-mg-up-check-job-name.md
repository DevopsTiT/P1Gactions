# MG Up Check From Job Name

```
Splunk panel
  last 3 minutes
  hosts WPALJA21BC and WPALJA21B9
  table host and MG_Result.MG_Status
        |
        v
Dynatrace rows that already returned
  log.source restapi-monitoring
  restapi.job_name holds the check name
  content holds the status JSON
        |
        v
filter both hosts with contains
  parse the status
  one row per check
```

| Splunk piece | Dynatrace field |
|---|---|
| The check name | `restapi.job_name` |
| The host in the URL | `restapi.url` |
| The status object | `content`, for example `{"IS_Result":{"IS_Status":"EIP_UP"}}` |
| Where the row is stored | `log.source` = `restapi-monitoring` |
| Panel window | Last 3 minutes |

## Summary

Filter `restapi-monitoring` logs whose job name contains `WPALJA21BC` or `WPALJA21B9`. Read the status from the JSON in `content`. Each side of `or` must be a full comparison.

## Investigation

The working notebook query is:

```
fetch logs
| filter restapi.job_name == "EIP IS UP check WPALJA21B8"
```

It returned 288 records over 24 hours. On those rows:

| Column | Value |
|---|---|
| `log.source` | `restapi-monitoring` |
| `restapi.job_name` | `EIP IS UP check WPALJA21B8` |
| `restapi.url` | `http://WPALJA21B8.prprivmgmt.intraxa:8880/rest/JP_MonitoringService...` |
| `content` | `{"IS_Result":{"IS_Status":"EIP_UP"}}` |
| `restapi.method` | `GET` |
| HTTP result | `200` |

The second query returned 0 records and the message that a parameter was a string where a boolean was required. The `or` was followed by a bare string. DQL needs `or restapi.job_name == "..."`.

The Splunk panel is a different pair of hosts, last 3 minutes:

```
index=eip1015 sourcetype=eip_mg_up_check host="WPALJA21BC.prprivmgmt.intraxa" OR host="WPALJA21B9.prprivmgmt.intraxa"
| table host MG_Result.MG_Status
```

`contains` on the host token covers both the Splunk name `EIP UP Check` and the Dynatrace name `EIP IS UP check`.

## Result

Last 3 minutes, both hosts:

```
fetch logs, from: now()-3m
| filter log.source == "restapi-monitoring"
    and (
      contains(restapi.job_name, "WPALJA21BC", caseSensitive:false)
      or contains(restapi.job_name, "WPALJA21B9", caseSensitive:false)
    )
| parse content, "LD 'Status\":\"' LD:checkStatus '\"'"
| fields timestamp, restapi.job_name, checkStatus, content
| sort timestamp desc
```

`checkStatus` is the value after `Status":"`. On the B8 rows that value is `EIP_UP`.

If the 3-minute query is empty, use the window that already returned rows:

```
fetch logs, from: now()-24h
| filter log.source == "restapi-monitoring"
    and (
      contains(restapi.job_name, "WPALJA21BC", caseSensitive:false)
      or contains(restapi.job_name, "WPALJA21B9", caseSensitive:false)
    )
| parse content, "LD 'Status\":\"' LD:checkStatus '\"'"
| fields timestamp, restapi.job_name, checkStatus, content
| sort timestamp desc
| limit 20
```

A single known job name stays an equality, repeated on both sides of `or`:

```
fetch logs, from: now()-24h
| filter restapi.job_name == "EIP IS UP check WPALJA21B8"
    or restapi.job_name == "EIP IS UP check WPALJA21B9"
| fields timestamp, restapi.job_name, content
| sort timestamp desc
| limit 20
```

## Data flow map

```
restapi-monitoring
  job name contains WPALJA21BC or WPALJA21B9
        |
        v
content JSON
  Status value
        |
        v
checkStatus
  timestamp
  restapi.job_name
```

## Related files

| File | Purpose |
|---|---|
| `14-mg-up-check-job-name.dql` | The 3-minute query, the 24-hour query, and the equality form. |
| `0-pic.md` | From the job name to the status. |
| `1-investigation.md` | The 288-row result and the boolean error. |
| `2-result.md` | The queries to paste. |
| `3-glossary.md` | The words. |
| `14-mg-up-check-job-name-follow.txt` | The same steps for a phone. |
| `14.sh` | Copy commands. |

Commands: [14.sh](14.sh)
