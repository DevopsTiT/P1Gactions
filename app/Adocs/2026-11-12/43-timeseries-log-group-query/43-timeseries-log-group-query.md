# Timeseries Log Group Query

```
timeseries box is empty
  by includes dt.entity.custom_device
  and isNotNull drops the nulls
    remove both
    keep aws.log_group
    add dt.smartscape_source.id only if the line stays
```

| Piece | What to paste |
|---|---|
| Metric | `log.lambda_errors` |
| Log group | `/aws/lambda/gov-inquiry-system-dev-logFailure` |
| Group by | `aws.log_group` |
| Leave out | `dt.entity.custom_device` and `isNotNull` |

## Summary

Use the same timeseries. Stop grouping by `dt.entity.custom_device`. That field is empty on this Lambda metric, and `isNotNull` then deletes every point. Group by the log group. Add `dt.smartscape_source.id` only when the line is still there.

## Investigation

The query in the Timeseries box is:

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group, dt.entity.custom_device}
| filter isNotNull(dt.entity.custom_device)
```

The same metric and log group, grouped only by `aws.log_group`, already drew a chart. The spikes are old. The recent part is flat.

The note under the box asks for `by:{dt.smartscape_source.id}`. That is the field this screen uses to attach an entity. `dt.entity.custom_device` is not that field.

## Result

Paste this into the Timeseries query:

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group, dt.smartscape_source.id}
```

Do not add `| filter isNotNull(...)`.

| Preview | What to do |
|---|---|
| A line shows | Keep this query. The smartscape id can connect the event. |
| The preview is blank | Remove `dt.smartscape_source.id` and keep only `aws.log_group`. |

The known-good query is:

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
```

Set the condition to **above 0**. It stays quiet until a new error point is stored. The recent chart is flat, so it will not open a problem today.

If the line has no smartscape id, set `dt.source_entity` in Add details to `HOST-00026D8D201D203A` with no braces. Leave the query grouped by the log group only.

Data type stays **Timeseries**.

## Data flow map

```
log.lambda_errors
  one dev log group
        |
        +--> by custom device + isNotNull
        |      empty field
        |      no line
        |
        +--> by aws.log_group
               line shows
               above 0 waits for a new error
               smartscape id, when present, connects the entity
```

## Related files

| File | Purpose |
|---|---|
| `43-timeseries-log-group-query.dql` | The two timeseries queries. |
| `0-pic.md` | Which `by` clause to keep. |
| `1-investigation.md` | Why the current box is empty. |
| `2-result.md` | The query to paste. |
| `3-glossary.md` | The words. |
| `43-timeseries-log-group-query-follow.txt` | The same notes for a phone. |
| `43.sh` | Copy commands. |

Commands: [43.sh](43.sh)
