# Wide API Table Again

```
one API per row
        |
        v
columns
  B9
  BC
  BF
  C0
  ALL
        |
        v
names from A to Z
```

| Column | What it counts |
|---|---|
| `API` | The name between `API:` and `API Version`. |
| `WPALJA21B9.prprivmgmt.intraxa` | Call lines on B9. |
| `WPALJA21BC.prprivmgmt.intraxa` | Call lines on BC. |
| `WPALJA21BF.prprivmgmt.intraxa` | Call lines on BF. |
| `WPALJA21C0.prprivmgmt.intraxa` | Call lines on C0. |
| `ALL` | The four hosts added together. |

## Summary

This is the wide table from the Splunk screen `EIP1015 - APIGW - Host vs API`. One row is one API. The last 60 minutes are the window.

## Investigation

The screen columns are B9, BC, BF, C0, then ALL. The rows run from names such as `V1-CoreBusiness-...` through `customer-info-V1` and `customer-info-V2`, then the `jp-` names.

`customer-info-V2` on that screen is 6,548, 6,902, 6,810, and 6,650. Those four add to 26,910.

`customer-info-V1` is 2,776, 3,824, 3,805, and 3,267. Those four add to 13,672.

The query counts a line when it contains `API:` and then `API Version`. It leaves out `Matching application found for the API:`.

## Result

```
fetch logs, from: now()-60m
| filter contains(log.source, "/opt/softwareag/log/1015/apigw5590/server.log", caseSensitive:false)
    and not(contains(content, "Matching application found for the API:", caseSensitive:false))
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

A cell is 0 when that host had no call line for that API.

## Data flow map

```
apigw5590/server.log
  API: <name> API Version
        |
        v
one row
  B9 | BC | BF | C0 | ALL
        |
        v
sorted by API name
```

## Related files

| File | Purpose |
|---|---|
| `30-wide-api-table-again.dql` | The wide table. |
| `0-pic.md` | The column order. |
| `1-investigation.md` | The screen this matches. |
| `2-result.md` | The query to paste. |
| `3-glossary.md` | The words. |
| `30-wide-api-table-again-follow.txt` | The same steps for a phone. |
| `30.sh` | Copy commands. |

Commands: [30.sh](30.sh)
