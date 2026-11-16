# Wide API Host Table

```
one API on each row
        |
        v
one column per host
  B9
  BC
  BF
  C0
        |
        v
ALL on the right
  the four host counts added together
        |
        v
rows in API name order
```

| Splunk column | What goes in it |
|---|---|
| `API` | The API name from the log line. |
| `WPALJA21B9.prprivmgmt.intraxa` | How many lines used that API on B9. |
| `WPALJA21BC.prprivmgmt.intraxa` | How many lines used that API on BC. |
| `WPALJA21BF.prprivmgmt.intraxa` | How many lines used that API on BF. |
| `WPALJA21C0.prprivmgmt.intraxa` | How many lines used that API on C0. |
| `ALL` | Those four counts added together. |

## Summary

The long list is one API on one host per row. This query turns that into the wide Splunk table: API down the side, the four gateways across the top, and `ALL` in the last column.

## Investigation

The Splunk panel is a chart. Each row is one API. The columns across the top are the four hosts, and the last column is `ALL`. The rows on the screen run in API name order. Names such as `customer-info-V2` sit in the middle of the list. Names such as `policy-management-V1` and `technical-utility-V1` sit near the bottom.

The same screen has a pie called `APIGW - Total Counts`. That pie is the four hosts. It is a separate panel from the wide table.

The last Dynatrace hour already had these `customer-info-V2` counts. A wide row for that API looks like this:

| Column | Count from the 14:55 host query |
|---|---|
| `WPALJA21B9.prprivmgmt.intraxa` | 6,734 |
| `WPALJA21BC.prprivmgmt.intraxa` | 6,974 |
| `WPALJA21BF.prprivmgmt.intraxa` | 6,716 |
| `WPALJA21C0.prprivmgmt.intraxa` | 6,637 |

That hour had 38 API names. Splunk’s `limit=101` keeps up to 101 names. All 38 fit, so this table does not need an `OTHER` row.

A cell is `0` when that host had no line for that API. The Splunk grid shows `0` in the same situation.

## Result

Paste this. The window is the last 60 minutes.

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
| parse content, "DATA{0,16000000} 'API: ' DATA{1,2000}:API ' API Version'"
| filter isNotNull(API)
| summarize {
    `WPALJA21B9.prprivmgmt.intraxa` = countIf(host.name == "WPALJA21B9.prprivmgmt.intraxa"),
    `WPALJA21BC.prprivmgmt.intraxa` = countIf(host.name == "WPALJA21BC.prprivmgmt.intraxa"),
    `WPALJA21BF.prprivmgmt.intraxa` = countIf(host.name == "WPALJA21BF.prprivmgmt.intraxa"),
    `WPALJA21C0.prprivmgmt.intraxa` = countIf(host.name == "WPALJA21C0.prprivmgmt.intraxa"),
    ALL = count()
  }, by: { API }
| fields API, `WPALJA21B9.prprivmgmt.intraxa`, `WPALJA21BC.prprivmgmt.intraxa`, `WPALJA21BF.prprivmgmt.intraxa`, `WPALJA21C0.prprivmgmt.intraxa`, ALL
| sort API asc
```

`countIf` counts a line only when the host matches that column. `ALL` counts the line once, on every host. `sort API asc` lists the names from A to Z, which is the order on the Splunk screen.

The pie under the table is the four hosts, without splitting by API:

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
| parse content, "DATA{0,16000000} 'API: ' DATA{1,2000}:API ' API Version'"
| filter isNotNull(API)
| summarize eventCount = count(), by: { host.name }
| sort eventCount desc
```

In the notebook, set that result’s visualization to a pie.

## Data flow map

```
one log line
  API name
  one host
        |
        v
wide row
  B9 | BC | BF | C0 | ALL
        |
        v
38 rows
  one row per API name
```

## Related files

| File | Purpose |
|---|---|
| `22-wide-api-host-table.dql` | The wide table and the pie query. |
| `0-pic.md` | From one line to the wide row. |
| `1-investigation.md` | How the Splunk grid is laid out. |
| `2-result.md` | The query to paste. |
| `3-glossary.md` | The words. |
| `22-wide-api-host-table-follow.txt` | The same steps for a phone. |
| `22.sh` | Copy commands. |

Commands: [22.sh](22.sh)
