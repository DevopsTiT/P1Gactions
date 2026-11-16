# Parse Stopped At 4096

```
Last 24 hours
  only 4 lines kept
  each count is 1
        |
        v
the pattern uses LD
  LD stops after 4,096 characters
  LD also stops at a line break
        |
        v
API Version is farther down the line
  the snippet already showed it
        |
        v
use DATA with a higher limit
  keep the last 60 minutes
```

| What the notebook showed | What it means |
|---|---|
| Picker says Last 24 hours | The query had no `from:`, so the picker chose the window. |
| Scanned bytes 97.78 GiB | That is a full day of this file, not the panel hour. |
| 4 rows, each count 1 | The pattern matched 4 lines and dropped the rest. |
| Snippet already showed `API Version` | The words are in the line. The pattern did not reach them. |

## Summary

`LD` reads at most 4,096 characters and stops at a line break. On these gateway lines the words `API Version` are farther along, so almost every line was dropped. Read the whole line with `DATA`, and use the last 60 minutes.

## Investigation

The count query was run with the notebook picker on Last 24 hours. The window is 15 Nov 14:52:01 through 16 Nov 14:52:01.

| API | Host | Count of API |
|---|---|---|
| `customer-info-V2` | `WPALJA21B9.prprivmgmt.intraxa` | 1 |
| `customer-info-V2` | `WPALJA21BC.prprivmgmt.intraxa` | 1 |
| `jp-CoreBusiness-ServiceManagement-ClaimService-v1-vs` | `WPALJA21C0.prprivmgmt.intraxa` | 1 |
| `policy-management-V1` | `WPALJA21BF.prprivmgmt.intraxa` | 1 |

The `ALL` query header says 5 records. The visible rows are `customer-info-V2` with 2, `jp-CoreBusiness-ServiceManagement-ClaimService-v1-vs` with 1, and `policy-management-V1` with 1. Two more API names are below the edge of the photo.

Five minutes earlier, the snippet query showed names such as `policy-management-V1` and `technical-utility-V1` followed by `API Version: 1.0`. Those lines are inside this 24-hour window. They did not appear in the count.

Dynatrace Pattern Language sets `LD` to a maximum of 4,096 characters. `LD` also stops at a newline. `DATA` can cross a newline, and it has the same 4,096 default until you raise it. The documented ceiling is 16,000,000 characters.

## Result

Set the picker to Last 60 minutes. This query also sets `from: now()-60m`, so the picker cannot stretch it to 24 hours.

A five-row check, so you can see the name before the full count:

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
    and contains(content, "API Version", caseSensitive:false)
| parse content, "DATA{0,16000000} 'API: ' DATA{1,2000}:API ' API Version'"
| fields timestamp, host.name, API
| limit 5
```

Count of API by API and host:

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
| parse content, "DATA{0,16000000} 'API: ' DATA{1,2000}:API ' API Version'"
| filter isNotNull(API)
| summarize `Count of API` = count(), by: { API, host.name }
| sort `Count of API` desc
```

The `ALL` column:

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
| parse content, "DATA{0,16000000} 'API: ' DATA{1,2000}:API ' API Version'"
| filter isNotNull(API)
| summarize ALL = count(), by: { API }
| sort ALL desc
```

`DATA{0,16000000}` means start anywhere in the line and keep reading up to the documented limit. `DATA{1,2000}` is the API name, which on the snippet is much shorter than 2,000 characters.

## Data flow map

```
long gateway line
  API: <name> API Version: 1.0
  the name sits past 4,096 characters
        |
        v
LD stops
  4 lines kept in 24 hours
        |
        v
DATA reads the rest of the line
        |
        v
count by API and host
  last 60 minutes
```

## Related files

| File | Purpose |
|---|---|
| `20-parse-stopped-at-4096.dql` | The five-row check, the chart, and the ALL query. |
| `0-pic.md` | Why the count stayed at 1. |
| `1-investigation.md` | The 24-hour result. |
| `2-result.md` | The queries to paste. |
| `3-glossary.md` | The words. |
| `20-parse-stopped-at-4096-follow.txt` | The same steps for a phone. |
| `20.sh` | Copy commands. |

Commands: [20.sh](20.sh)
