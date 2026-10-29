# PC Queue Health Query

```
Open the tile
  which app? → filter says app == "pc"
  one line or many? → by queue.id and queue.name, so one series per queue
  what number is kept? → the last average in the time window
  why 16 records? → 16 queues had that metric in this window
  chart title says BC? → the query itself filters pc
```

| Key point | Detail |
|---|---|
| Metric | `guidewire.messaging.status`, averaged. |
| Scope | Only the app whose value is `pc`. |
| Split | One result per queue id and queue name. |
| Number you keep | The last point of that average, stored in `status`. |
| This run | 16 records, from 09:28 to 11:29. |

## Summary

This query builds a time series of Guidewire messaging status for PolicyCenter queues, then keeps only the latest value for each queue. The 16 records are 16 queues, not 16 raw messages.

## Investigation

| Source | Finding |
|---|---|
| Tile title | PC Queue Health. |
| Query | `timeseries` on `guidewire.messaging.status`, filtered to `app == "pc"`, split by `queue.id` and `queue.name`. |
| Result line | 16 records. Executed 10/29/2026 11:28:30. Timeframe 09:28:00–11:29:00. |
| Chart beside it | The visible chart title says BC Failed Messages, and the line sits at 0. The query text filters `pc`. |

## Result

Read the query from top to bottom.

```
timeseries status_series = avg(guidewire.messaging.status),
  filter: { app == "pc" },
  by: { queue.id, queue.name }
| fieldsAdd status = arrayLast(status_series)
| fieldsRemove status_series, timeframe, interval
```

| Line | What it does |
|---|---|
| timeseries | Builds a metric line over the selected time window. This is different from `fetch logs`. |
| avg(guidewire.messaging.status) | For each time bucket, take the average of that Guidewire messaging-status metric. The name `status_series` is the column that holds the whole line. |
| filter: { app == "pc" } | Keep only the series whose `app` field equals `pc`. In Guidewire naming, PC is PolicyCenter. This filter is part of `timeseries`, not a later `filter` command. |
| by: { queue.id, queue.name } | Draw a separate line for each queue. The id and the name travel together. |
| fieldsAdd status = arrayLast(status_series) | A series is a list of points. `arrayLast` picks the newest point and stores it in a column named `status`. |
| fieldsRemove | Drop the full line, the timeframe, and the interval, so the table shows the queue and that latest status. |

The run returned 16 records because 16 queue id and name pairs had this metric in that window.

The chart on the left is titled BC Failed Messages and is flat at 0 from about 10:00 to 11:00. BC is the usual Guidewire name for BillingCenter. The query in the editor filters `app == "pc"`. Check the Visual tab if that chart title is meant to describe this same query.

What this query does not tell you from the text alone is the meaning of the status number. A last value of 0 is the last average in the window. The metric definition in Dynatrace Metrics is the place that says what 0 means for `guidewire.messaging.status`.

## Data flow map

```
guidewire.messaging.status
    -> keep app == "pc"
    -> one series per queue.id + queue.name
    -> average inside each time bucket
    -> keep the last point as status
    -> hide the series
    -> 16 queue rows
```

## Related files

| File | What it is |
|---|---|
| 5-pc-queue-health-dql-follow.txt | The same explanation, easy to copy. |
| 0-pic.md | The path from metric to 16 rows. |
| 1-investigation.md | What was on the screen. |
| 2-result.md | Line-by-line meaning. |
| 3-glossary.md | The words in the query. |
| 5.sh | Copy commands. Run them yourself. |
