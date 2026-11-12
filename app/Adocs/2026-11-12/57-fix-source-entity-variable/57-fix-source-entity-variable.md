# Fix Source Entity Variable

```
query adds dt.entity.host
  problem still says {dt.entity.custom_device}
    names do not match
    change dt.source_entity to {dt.entity.host}
  short alert window
    last 2 hours has 0 records
    this alert does not open a problem today
```

| Field on the screen | What it says now | What to put |
|---|---|---|
| `dt.source_entity` | `{dt.entity.custom_device}` | `{dt.entity.host}` |
| `dt.smartscape_source.id` | `{dt.smartscape_source.id}` | Delete this row |

## Summary

The query and the problem use different entity names. The query adds `dt.entity.host`. The problem still asks for `dt.entity.custom_device`. Change `dt.source_entity` to `{dt.entity.host}`. This alert still will not open a problem today, because the last 2 hours of this metric has no points.

## Investigation

Set Scope has this query:

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
| fieldsAdd dt.entity.host = "HOST-00026D8D201D203A"
```

Add details has:

| Key | Value |
|---|---|
| Title | Test on cloudwatch logs |
| Event name | Test on cloudwatch logs |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `{dt.entity.custom_device}` |
| `dt.smartscape_source.id` | `{dt.smartscape_source.id}` |

The braces copy a column from the query row. The row has `dt.entity.host`. It does not have `dt.entity.custom_device` or `dt.smartscape_source.id`.

The same query returned 0 records from 14:25 to 16:26. The alert uses its own short window. It does not use the notebook picker.

## Result

In **Add details**, change one value:

| Key | Value |
|---|---|
| `dt.source_entity` | `{dt.entity.host}` |

Keep the braces. Delete the `dt.smartscape_source.id` row. Leave `event.type` as `CUSTOM_ALERT`.

Do not expect a problem from this save today. The metric has no points in the last 2 hours, so the condition has no line to judge. The host CPU alert is the one that can open a problem now.

## Data flow map

```
query row
  dt.entity.host = HOST-00026D8D201D203A
        |
        v
problem asks for dt.entity.custom_device
  no such column
  entity stays empty
        |
change the problem field
        |
{dt.entity.host}
  copies the host
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Which value to change. |
| `1-investigation.md` | What the two screens show. |
| `2-result.md` | The value to type. |
| `3-glossary.md` | The words. |
| `57-fix-source-entity-variable-follow.txt` | The same notes for a phone. |
| `57.sh` | Copy commands. |

Commands: [57.sh](57.sh)
