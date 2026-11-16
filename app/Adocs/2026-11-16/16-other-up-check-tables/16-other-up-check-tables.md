# Other Up Check Tables

```
dashboard table
  two hosts, one status each
        |
        v
which panel?
  DC1 Integration  B8 and BB   IS_Result.IS_Status
  DC2 Mediator     BF and C0   MG_Result.MG_Status
  DC2 Integration  C1 and BD   IS_Result.IS_Status
        |
        v
same log source as the 576 rows
  restapi-monitoring
  host from the URL
  status from the JSON
        |
        v
one newest row per host
```

| Panel | Host on the screen | Status column | Value on the screen |
|---|---|---|---|
| DC1 Integration Servers | `WPALJA21B8.prprivmgmt.intraxa` | `IS_Result.IS_Status` | `EIP_UP` |
| DC1 Integration Servers | `WPALJA21BB.prprivmgmt.intraxa` | `IS_Result.IS_Status` | `EIP_UP` |
| DC2 Mediator Servers | `WPALJA21BF.prprivmgmt.intraxa` | `MG_Result.MG_Status` | `EIP_UP` |
| DC2 Mediator Servers | `WPALJA21C0.prprivmgmt.intraxa` | `MG_Result.MG_Status` | `EIP_UP` |
| DC2 Integration Servers | `WPALJA21C1.prprivmgmt.intraxa` | `IS_Result.IS_Status` | `EIP_UP` |
| DC2 Integration Servers | `WPALJA21BD.prprivmgmt.intraxa` | `IS_Result.IS_Status` | `EIP_UP` |

## Summary

Each remaining panel is the same shape as the BC and B9 table. Filter `restapi-monitoring` by the two short host codes, read the host from the URL, read the status from the JSON, and keep the newest row for each host.

## Investigation

The Splunk dashboard shows four up-check tables. DC1 Mediator is the pair already converted: `WPALJA21B9` and `WPALJA21BC`, column `MG_Result.MG_Status`.

The other three tables are on these screenshots.

DC1 Integration Servers uses `IS_Result.IS_Status`. The hosts are `WPALJA21B8.prprivmgmt.intraxa` and `WPALJA21BB.prprivmgmt.intraxa`. Both show `EIP_UP`.

DC2 Mediator Servers uses `MG_Result.MG_Status`. The hosts are `WPALJA21BF.prprivmgmt.intraxa` and `WPALJA21C0.prprivmgmt.intraxa`. Both show `EIP_UP`.

DC2 Integration Servers uses `IS_Result.IS_Status`. The hosts are `WPALJA21C1.prprivmgmt.intraxa` and `WPALJA21BD.prprivmgmt.intraxa`. Both show `EIP_UP`.

In Dynatrace, the working rows use `log.source == "restapi-monitoring"`. A proved integration job is `EIP IS UP check WPALJA21B8`, and the body is `{"IS_Result":{"IS_Status":"EIP_UP"}}`. A proved mediator job is `EIP MG UP check WPALJA21BC`, and the body is `{"MG_Result":{"MG_Status":"EIP_UP"}}`. The host name sits in `restapi.url` before the port.

`WPALJA21BB`, `WPALJA21BF`, `WPALJA21C0`, `WPALJA21C1`, and `WPALJA21BD` are copied from the Splunk panels. A notebook has not shown those five job names yet. The queries use the same job pattern.

## Result

Use Last 3 minutes, because that is the window used on the earlier up-check panel. Each query returns one current row per host.

DC1 Integration Servers:

```
fetch logs, from: now()-3m
| filter log.source == "restapi-monitoring"
    and (
      contains(restapi.job_name, "WPALJA21B8", caseSensitive:false)
      or contains(restapi.job_name, "WPALJA21BB", caseSensitive:false)
    )
    and contains(restapi.job_name, "IS UP", caseSensitive:false)
| parse restapi.url, "LD '://' LD:host ':'"
| parse content, "LD 'IS_Status\":\"' LD:checkStatus '\"'"
| sort timestamp desc
| summarize { `IS_Result.IS_Status` = takeFirst(checkStatus) }, by: { host }
```

DC2 Mediator Servers:

```
fetch logs, from: now()-3m
| filter log.source == "restapi-monitoring"
    and (
      contains(restapi.job_name, "WPALJA21BF", caseSensitive:false)
      or contains(restapi.job_name, "WPALJA21C0", caseSensitive:false)
    )
    and contains(restapi.job_name, "MG UP", caseSensitive:false)
| parse restapi.url, "LD '://' LD:host ':'"
| parse content, "LD 'MG_Status\":\"' LD:checkStatus '\"'"
| sort timestamp desc
| summarize { `MG_Result.MG_Status` = takeFirst(checkStatus) }, by: { host }
```

DC2 Integration Servers:

```
fetch logs, from: now()-3m
| filter log.source == "restapi-monitoring"
    and (
      contains(restapi.job_name, "WPALJA21C1", caseSensitive:false)
      or contains(restapi.job_name, "WPALJA21BD", caseSensitive:false)
    )
    and contains(restapi.job_name, "IS UP", caseSensitive:false)
| parse restapi.url, "LD '://' LD:host ':'"
| parse content, "LD 'IS_Status\":\"' LD:checkStatus '\"'"
| sort timestamp desc
| summarize { `IS_Result.IS_Status` = takeFirst(checkStatus) }, by: { host }
```

If a table is empty, change `from: now()-3m` to `from: now()-24h` and run it again. The proved B8, B9, and BC checks were found across 24 hours.

If it is still empty, delete the line that contains `IS UP` or `MG UP`. Keep the short host code. That shows whether the job name uses different words.

## Data flow map

```
Splunk panel
  two hosts
  one status column
        |
        v
restapi.job_name
  IS UP  or  MG UP
  plus the short host code
        |
        v
restapi.url  ->  host
content      ->  EIP_UP
        |
        v
one row per host
```

## Related files

| File | Purpose |
|---|---|
| `16-other-up-check-tables.dql` | The three panel queries. |
| `0-pic.md` | Which panel uses which status. |
| `1-investigation.md` | What the screenshots show. |
| `2-result.md` | The queries to paste. |
| `3-glossary.md` | The words. |
| `16-other-up-check-tables-follow.txt` | The same steps for a phone. |
| `16.sh` | Copy commands. |

Commands: [16.sh](16.sh)
