# Timeseries With Entity

```
log.lambda_errors for the dev log group
  by aws.log_group only
  fieldsAdd dt.entity.host = HOST-00026D8D201D203A
  dt.source_entity = {dt.entity.host}
  problem lists that host
```

| Piece | Value |
|---|---|
| Query grouping | `aws.log_group` |
| Entity field added after the metric | `dt.entity.host` |
| Event property | `dt.source_entity` = `{dt.entity.host}` |

## Summary

The timeseries stays on the log group. The host id is added as `dt.entity.host` on that result. The event copies it into `dt.source_entity`. The host is the anchor. The Lambda logs did not come from that machine.

## Investigation

`dt.entity.custom_device` is empty on `log.lambda_errors`. Putting it in `by` and keeping `isNotNull` removes the line.

`dt.entity.host` is also not a dimension of this metric. Putting it in `by` removes the line in the same way.

The host id `HOST-00026D8D201D203A` came from the CPU notebook. `fieldsAdd` can attach that id to the log-group series without changing the metric.

## Result

Paste this in the Timeseries box:

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
| fieldsAdd dt.entity.host = "HOST-00026D8D201D203A"
```

In Add details:

| Key | Value |
|---|---|
| `dt.source_entity` | `{dt.entity.host}` |
| `event.type` | `CUSTOM_ALERT` |

Keep the braces on `{dt.entity.host}`. The query now has that field, so Davis copies the id.

If the problem opens and Affected entities is empty, change the value to the bare id with no braces:

```
HOST-00026D8D201D203A
```

Condition stays **above 0**. The recent chart is flat, so it waits for a new error point.

Do not add `isNotNull`. Do not put `dt.entity.host` inside `by`.

## Data flow map

```
log group series
        |
        v
fieldsAdd dt.entity.host
        |
        v
dt.source_entity copies that id
        |
        v
problem shows the host under Affected entities
```

## Related files

| File | Purpose |
|---|---|
| `44-timeseries-with-entity.dql` | The query to paste. |
| `0-pic.md` | Where the host id is attached. |
| `1-investigation.md` | Why the host stays out of `by`. |
| `2-result.md` | The event value. |
| `3-glossary.md` | The words. |
| `44-timeseries-with-entity-follow.txt` | The same notes for a phone. |
| `44.sh` | Copy commands. |

Commands: [44.sh](44.sh)
