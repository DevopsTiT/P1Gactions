# DC2 Panel Query

```
WPALJA21C0
WPALJA21BF
  Status FAILURE
        |
        v
ErrorCount
  dashboard shows 2
```

| Field | Value |
|---|---|
| Hosts | `WPALJA21C0` and `WPALJA21BF` |
| Line text | `status: failure` |
| Result | One row. `ErrorCount` is the red number. |

## Summary

Paste the query. Set the notebook time picker to the dashboard range. `ErrorCount` matches the red 2 when the window matches.

## Investigation

Panel title: `APIGW WPALJA21C0 & WPALJA21BF Failed Count`. The search stacks both hosts with `Status=FAILURE` and counts them as `ErrorCount`. The panel shows 2.

## Result

```
fetch logs
| filter (
      contains(host.name, "WPALJA21C0", caseSensitive:false)
      or contains(host.name, "WPALJA21BF", caseSensitive:false)
      or contains(content, "WPALJA21C0.prprivmgmt.intraxa", caseSensitive:false)
      or contains(content, "WPALJA21BF.prprivmgmt.intraxa", caseSensitive:false)
    )
    and contains(content, "status: failure", caseSensitive:false)
| fieldsAdd Status = "FAILURE"
| summarize ErrorCount = count(), by: { Status }
```

## Data flow map

```
two DC2 hosts
  FAILURE lines
        |
        v
ErrorCount 2
```

## Related files

| File | Purpose |
|---|---|
| `8-dc2-panel-query.dql` | The query to paste. |
| `0-pic.md` | Both hosts into ErrorCount. |
| `1-investigation.md` | The panel. |
| `2-result.md` | The query. |
| `3-glossary.md` | The words. |
| `8-dc2-panel-query-follow.txt` | The same query for a phone. |
| `8.sh` | Copy commands. |

Commands: [8.sh](8.sh)
