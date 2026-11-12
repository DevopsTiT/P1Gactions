# Log Query Keep Entity

```
Last 365 days
  by aws.log_group only
  fieldsAdd dt.entity.host
  a line means the query works
  {dt.entity.host} is the problem variable
  do not put the host in by
```

| Piece | Where it goes |
|---|---|
| `aws.log_group` | Inside `by` |
| `dt.entity.host` | After the metric, with `fieldsAdd` |
| `{dt.entity.host}` | `dt.source_entity` on the problem |

## Summary

The long window is what makes this log query return a line. The entity variable stays on the row through `fieldsAdd`. Grouping by `dt.entity.host` would drop the line.

## Investigation

Last 2 hours of this log group returned 0 records. A long chart of the same group showed old spikes.

`log.lambda_errors` has no `dt.entity.host` dimension. The host id `HOST-00026D8D201D203A` is added after the series exists.

## Result

Picker **Last 365 days**. Run this:

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
| fieldsAdd dt.entity.host = "HOST-00026D8D201D203A"
```

| Result | What it means |
|---|---|
| A line, and the row shows `dt.entity.host` | The query works and the variable is kept. |
| Still 0 records | The long window has no series. The variable has no row to sit on. |

On the problem, set `dt.source_entity` to `{dt.entity.host}`. Keep the braces.

Do not add `dt.entity.host` to `by`. Do not add `isNotNull`.

A short alert window still sees only the flat end. This test proves the query. It does not make a few-minute alert fire today.

## Data flow map

```
Last 365 days
  by aws.log_group
        |
        v
line of old spikes
        |
        v
fieldsAdd dt.entity.host
        |
        v
{dt.entity.host} on the problem
```

## Related files

| File | Purpose |
|---|---|
| `54-log-query-keep-entity.dql` | The query to run. |
| `0-pic.md` | Where the entity variable sits. |
| `1-investigation.md` | Why the host stays out of `by`. |
| `2-result.md` | The picker and the problem field. |
| `3-glossary.md` | The words. |
| `54-log-query-keep-entity-follow.txt` | The same notes for a phone. |
| `54.sh` | Copy commands. |

Commands: [54.sh](54.sh)
