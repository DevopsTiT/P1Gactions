# Host Query Proved

```
notebook last 2 hours
  1 record for HOST-00026D8D201D203A
  line stays under 20
    paste the same query into the alert
    cpu below 101
    dt.source_entity = {dt.entity.host}
    Problems search TESTDUMMY
    disable the alert
```

| Check | Result |
|---|---|
| Records | 1 |
| Host | `HOST-00026D8D201D203A` |
| Window | 13:37 to 15:38 |
| Line versus 101 | The line stays under 20, so below 101 is already true |

## Summary

The query works and the entity column is filled. Paste it into the Timeseries alert, set the condition to below 101, and set `dt.source_entity` to `{dt.entity.host}`. A problem should show within a few minutes. Disable the alert after you see it.

## Investigation

The notebook ran:

```
timeseries cpu = avg(dt.host.cpu.usage),
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host}
```

| Item | Value |
|---|---|
| Result | 1 record |
| Ran at | 11/12/2026 15:37:02 |
| Timeframe | 13:37:00 to 15:38:00 |
| Chart | A line around a few percent, with peaks still under 20 |

`by: {dt.entity.host}` put the host id on that row. `{dt.entity.host}` can copy it.

## Result

Paste the same query into the Timeseries box.

| Setting | Value |
|---|---|
| Line | `cpu` |
| Condition | Below 101 |
| Window | A few minutes |
| Title | `TESTDUMMY host entity` |
| Event name | `TESTDUMMY host entity` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `{dt.entity.host}` |

Keep the braces. Do not add email.

Save. Wait about 3 minutes. Open Problems and search `TESTDUMMY`. Affected entities should list this host. Then disable the alert.

## Data flow map

```
1 record
  host HOST-00026D8D201D203A
  cpu under 20
        |
        v
alert condition below 101
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
| `47-host-query-proved.dql` | The query that returned one row. |
| `0-pic.md` | What the chart proved. |
| `1-investigation.md` | The notebook result. |
| `2-result.md` | The alert settings to save. |
| `3-glossary.md` | The words. |
| `47-host-query-proved-follow.txt` | The same notes for a phone. |
| `47.sh` | Copy commands. |

Commands: [47.sh](47.sh)
