# Timeseries Alert Shows Result

```
chart is blank
  last line is isNotNull(dt.entity.custom_device)?
    yes -> that field is empty on Lambda logs
           remove it
  simple timeseries still blank?
    wrong log group path -> dev is in this path
    wrong field name -> try aws.log.group
    metric name unknown -> the query errors
  a line appears?
    leave the entity filter off the query
    attach the device in the event template
```

| Question | Answer |
|---|---|
| Why is the result empty? | `dt.entity.custom_device` is null, and the last filter drops every point. |
| What shows a line? | Sum the metric for the log group only. |
| Where does the entity go? | In the event template, after the line is visible. |

## Summary

This screen is a metric chart. The alert can open a problem only when the query returns a line. The custom-device filter removes that line. Take the filter off, confirm the log group has points, then attach the entity in the event details.

## Investigation

The query on the screen is:

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group, dt.entity.custom_device}
| filter isNotNull(dt.entity.custom_device)
```

| Piece | What it does |
|---|---|
| `timeseries` | Builds a chart from a metric. |
| `log.lambda_errors` | The metric being summed. |
| `aws.log_group` | Keeps one Lambda log group. |
| `by: {dt.entity.custom_device}` | Splits the chart by a custom device. |
| `isNotNull(dt.entity.custom_device)` | Drops every point that has no custom device. |

Lambda log metrics do not come with a custom device. Every point fails that last filter, so the preview has no series. An empty series gives the alert condition nothing to judge, so no problem opens.

The path says `gov-inquiry-system-dev-logFailure`. The earlier gov-inquiry alerts used the prod log groups. A dev path returns nothing when this environment only has prod logs.

The earlier log queries used the field `aws.log.group`, with a dot. This screen uses `aws.log_group`, with an underscore. Those are different names. Use the one that returns rows.

The note under the box says to add `by:{dt.smartscape_source.id}`. That connects the event to an entity only when the metric already has that id. Filtering on it while it is null hides the line again.

Segments can stay empty. An empty segment is not the reason the chart is blank.

## Result

Paste this first:

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log.group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log.group}
```

A line means the metric and the log group match. No line means one of these is true:

| Check | What to do |
|---|---|
| The query says the metric does not exist | The name `log.lambda_errors` is not in this environment. |
| The path is dev | Switch the path to the prod log group if that is where the logs are. |
| The field name is wrong | Change `aws.log.group` to `aws.log_group` and run it again. |
| There are no errors in the time picker | The chart stays blank. A log error metric often writes a point only when an error log exists. |

To see which log groups this metric actually has:

```
timeseries errors = sum(log.lambda_errors), by: {aws.log.group}
| fields aws.log.group
```

If that fails, use `aws.log_group` in the `by` and in `fields`.

After a line shows, attach the entity without filtering the chart:

1. Leave `dt.entity.custom_device` out of the query.
2. In Add details, set `dt.source_entity` to the real `CUSTOM_DEVICE-...` id from the custom device you created. No braces.
3. Keep `event.type` as `CUSTOM_ALERT`.
4. Set the alert condition on the `errors` line. A condition cannot fire while the chart has no series.

Add `dt.smartscape_source.id` to the `by` list only after a query that includes it still returns a line. If adding it makes the chart blank, that id is not on this metric. Keep it out of the query and use the static custom device id instead.

## Data flow map

```
log.lambda_errors for one log group
        |
        +--> custom device filter
        |      field is empty
        |      chart stays blank
        |      no problem
        |
        +--> log group only
               a line shows
               alert condition can judge it
               event template attaches CUSTOM_DEVICE-...
               Problems shows the title
```

## Related files

| File | Purpose |
|---|---|
| `37-timeseries-alert-shows-result.dql` | The query to paste first. |
| `0-pic.md` | Why the chart is blank. |
| `1-investigation.md` | What each line of the query does. |
| `2-result.md` | The query that can return a line. |
| `3-glossary.md` | The words. |
| `37-timeseries-alert-shows-result-follow.txt` | The same notes for a phone. |
| `37.sh` | Copy commands. |

Commands: [37.sh](37.sh)
