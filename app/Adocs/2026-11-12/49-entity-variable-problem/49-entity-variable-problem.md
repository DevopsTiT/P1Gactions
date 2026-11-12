# Entity Variable Problem

```
query groups by dt.entity.host
  the row carries the host id
  dt.source_entity = {dt.entity.host}
  cpu below 101
  problem opens on that host
  disable the alert
```

| Place | Value |
|---|---|
| Query `by` | `dt.entity.host` |
| Problem field | `{dt.entity.host}` |
| Condition | `cpu` below 101 |

## Summary

`{dt.entity.host}` copies the host id from the query row onto the problem. The `by` clause is what creates that variable. Below 101 is already true for this host, so the problem opens. Disable the alert after you see it.

## Investigation

The notebook returned 1 record for `HOST-00026D8D201D203A` from 13:37 to 15:38. The CPU line stayed under 20. The `by` field on that query was `dt.entity.host`.

The Lambda error query has no `dt.entity.host` column, and the last 2 hours had 0 records. Braces on that query have nothing to copy.

## Result

Paste this into the Timeseries box:

```
timeseries cpu = avg(dt.host.cpu.usage),
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host}
```

| Setting | Value |
|---|---|
| Line | `cpu` |
| Condition | Below 101 |
| Window | A few minutes |
| Title | `TESTDUMMY host entity` |
| Event name | `TESTDUMMY host entity` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `{dt.entity.host}` |

Keep the braces on `{dt.entity.host}`. That is the variable. Do not type the `HOST-` id into `dt.source_entity`. Do not add `isNotNull`. Do not add email.

Save. Wait about 3 minutes. Open Problems and search `TESTDUMMY`. Affected entities should list `HOST-00026D8D201D203A`. Then disable the alert.

The yellow note wants `dt.smartscape_source.id` in `by`. Add it only if the notebook still returns 1 record:

```
timeseries cpu = avg(dt.host.cpu.usage),
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host, dt.smartscape_source.id}
```

If that row disappears, remove `dt.smartscape_source.id` and keep the first query.

## Data flow map

```
by: {dt.entity.host}
        |
        v
row value HOST-00026D8D201D203A
        |
        v
problem field {dt.entity.host}
        |
        v
Affected entities lists that host
```

## Related files

| File | Purpose |
|---|---|
| `49-entity-variable-problem.dql` | The query that creates the variable. |
| `0-pic.md` | Where the braces get their value. |
| `1-investigation.md` | The row that already came back. |
| `2-result.md` | The problem field to set. |
| `3-glossary.md` | The words. |
| `49-entity-variable-problem-follow.txt` | The same notes for a phone. |
| `49.sh` | Copy commands. |

Commands: [49.sh](49.sh)
