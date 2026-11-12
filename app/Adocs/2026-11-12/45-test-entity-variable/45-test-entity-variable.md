# Test Entity Variable

```
lambda errors, last 2 hours
  0 records
  no row to attach
test host CPU instead
  by dt.entity.host
  one HOST id
  dt.source_entity = {dt.entity.host}
  problem shows that host
  disable the alert
```

| Question | Answer |
|---|---|
| Why is the lambda query empty? | No error points from 13:31 to 15:32. |
| Which query fills the entity variable? | Host CPU, grouped by `dt.entity.host`. |
| What goes in the event? | `{dt.entity.host}` |

## Summary

`{dt.entity.host}` only works when the query result has that column. The Lambda error metric does not. Host CPU does. Alert one host, and set `dt.source_entity` to `{dt.entity.host}`.

## Investigation

The notebook ran:

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
```

| Item | Value |
|---|---|
| Result | 0 records |
| Timeframe | 13:31 to 15:32 |
| Picker | Last 2 hours |

An empty result has no `dt.entity.host` value for the braces to copy.

The earlier CPU query returned host ids, including `HOST-00026D8D201D203A`. That metric’s `by` field is the entity variable.

## Result

Paste this. Picker **Last 2 hours**. You should get one row, and the row should contain `dt.entity.host`.

```
timeseries cpu = avg(dt.host.cpu.usage),
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host}
```

| Setting | Value |
|---|---|
| Line | `cpu` |
| Condition | Below 101 |
| Title | `TESTDUMMY host entity` |
| Event name | `TESTDUMMY host entity` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `{dt.entity.host}` |

Keep the braces. Davis copies the host id from the query row.

Do not add `isNotNull`. Do not point this test at `log.lambda_errors`.

Wait about 3 minutes. Open Problems and search `TESTDUMMY`. The host is under Affected entities. Then disable the alert.

## Data flow map

```
HOST-00026D8D201D203A
  cpu line
        |
        v
row field dt.entity.host
        |
        v
{dt.entity.host} copies it into dt.source_entity
        |
        v
problem lists that host
```

## Related files

| File | Purpose |
|---|---|
| `45-test-entity-variable.dql` | The query that returns the entity column. |
| `0-pic.md` | Why the lambda box cannot fill the variable. |
| `1-investigation.md` | The 0-record window. |
| `2-result.md` | The event value to use. |
| `3-glossary.md` | The words. |
| `45-test-entity-variable-follow.txt` | The same notes for a phone. |
| `45.sh` | Copy commands. |

Commands: [45.sh](45.sh)
