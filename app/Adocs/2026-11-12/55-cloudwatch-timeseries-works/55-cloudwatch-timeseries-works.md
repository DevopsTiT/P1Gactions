# CloudWatch Timeseries Works

```
picker Last 365 days
  log.lambda_errors
  one dev log group
  by aws.log_group
  fieldsAdd dt.entity.host
  a line means it works
```

| Setting | Value |
|---|---|
| Picker | Last 365 days |
| Metric | `log.lambda_errors` |
| Log group | `/aws/lambda/gov-inquiry-system-dev-logFailure` |
| Entity | Added after the metric |

## Summary

Run this timeseries on **Last 365 days**. That range includes the old spikes, so the query can return a line. `dt.entity.host` is added after the series. Last 2 hours stays empty because no new error was stored.

## Investigation

The same log group returned 0 records from 14:03 to 16:04. A long chart of that group showed spikes in the older part and a flat recent end. `default: 0` did not create a series in the empty window.

## Result

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
| fieldsAdd dt.entity.host = "HOST-00026D8D201D203A"
```

| Result | What it means |
|---|---|
| A line | The query works. The row should show `dt.entity.host`. |
| Still 0 records | This log group has no stored points in that year. |

Do not put `dt.entity.host` in `by`. Do not add `isNotNull`.

On a problem, `dt.source_entity` is `{dt.entity.host}`. A short alert window still sees the flat end and will not open a problem today.

## Data flow map

```
Last 365 days
  one CloudWatch log group
        |
        v
error spikes
        |
        v
fieldsAdd dt.entity.host
        |
        v
the row has the host variable
```

## Related files

| File | Purpose |
|---|---|
| `55-cloudwatch-timeseries-works.dql` | The query to run. |
| `0-pic.md` | The picker and the entity. |
| `1-investigation.md` | Why the short window failed. |
| `2-result.md` | The query. |
| `3-glossary.md` | The words. |
| `55-cloudwatch-timeseries-works-follow.txt` | The same notes for a phone. |
| `55.sh` | Copy commands. |

Commands: [55.sh](55.sh)
