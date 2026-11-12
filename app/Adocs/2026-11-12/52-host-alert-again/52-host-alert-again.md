# Host Alert Again

```
notebook already returned 1 record
  paste that query
  cpu below 101
  dt.source_entity = {dt.entity.host}
  Problems shows TESTDUMMY
  disable the alert
```

| Setting | Value |
|---|---|
| Query | Host CPU for `HOST-00026D8D201D203A` |
| Condition | `cpu` below 101 |
| Entity variable | `{dt.entity.host}` |

## Summary

Paste the host query that already returned one record. The line was under 20, so below 101 opens a problem. `{dt.entity.host}` copies the host onto that problem. Disable the alert after you see it.

## Investigation

The host query returned 1 record from 13:37 to 15:38. The CPU line stayed under 20.

The CloudWatch query for the dev log group returned 0 records from 14:03 to 16:04, including with `default: 0`. That query is not on this alert.

## Result

```
timeseries cpu = avg(dt.host.cpu.usage),
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host}
```

| Setting | Value |
|---|---|
| Data type | Timeseries |
| Line | `cpu` |
| Condition | Below 101 |
| Window | A few minutes |
| Title | `TESTDUMMY host entity` |
| Event name | `TESTDUMMY host entity` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `{dt.entity.host}` |

Keep the braces. Do not add `isNotNull`. Do not add email.

Save. Wait about 3 minutes. Open Problems and search `TESTDUMMY`. Affected entities should list `HOST-00026D8D201D203A`. Then disable the alert.

## Data flow map

```
1 host CPU record
        |
        v
below 101
  {dt.entity.host}
        |
        v
Problems TESTDUMMY
        |
        v
disable the alert
```

## Related files

| File | Purpose |
|---|---|
| `52-host-alert-again.dql` | The query to paste. |
| `0-pic.md` | The alert path. |
| `1-investigation.md` | Which query returned a row. |
| `2-result.md` | The settings. |
| `3-glossary.md` | The words. |
| `52-host-alert-again-follow.txt` | The same notes for a phone. |
| `52.sh` | Copy commands. |

Commands: [52.sh](52.sh)
