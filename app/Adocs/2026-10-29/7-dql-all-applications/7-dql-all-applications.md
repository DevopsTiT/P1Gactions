# DQL For All Applications

```
Want every application
  same queue metric? → remove app == "pc"
  keep the apps apart? → add app to the by list
  only a known set? → or the app values together
  open problems instead? → fetch dt.davis.problems where status is ACTIVE
```

| Key point | Detail |
|---|---|
| Query to paste | The timeseries below, with no `app == "pc"` filter. |
| Why add `app` | One series per application and queue. PC and BC stay separate. |
| What you get | The latest average of `guidewire.messaging.status` for every app that sends it. |
| What it does not list | Applications that never report this metric. |

## Summary

Take the PC Queue Health query and remove the PolicyCenter-only filter. Put `app` in the `by` list so each application keeps its own queues. The latest point of each line is the status column.

## Investigation

| Source | Finding |
|---|---|
| PC Queue Health tile | `timeseries avg(guidewire.messaging.status)` with `filter: { app == "pc" }` and `by: { queue.id, queue.name }`. |
| Chart beside it | Title says BC Failed Messages. BC is a different Guidewire app from pc. |
| This change | Drop the filter. Group by `app`, `queue.id`, and `queue.name`. |

## Result

Paste this into the tile and Run.

```
timeseries status_series = avg(guidewire.messaging.status),
  by: { app, queue.id, queue.name }
| fieldsAdd status = arrayLast(status_series)
| fieldsRemove status_series, timeframe, interval
| sort app asc, queue.name asc
```

| Line | What it does |
|---|---|
| timeseries | Builds one metric line per group for the time range on the tile. |
| avg(guidewire.messaging.status) | Average of that messaging-status metric in each time bucket. |
| by: { app, queue.id, queue.name } | One line for each application and each queue. |
| arrayLast | Keeps the newest point and names it `status`. |
| fieldsRemove | Hides the full line so the table is app, queue, and status. |
| sort | Applications in order, then queue name. |

To watch only the apps you name, put the filter back with each value:

```
timeseries status_series = avg(guidewire.messaging.status),
  filter: { app == "pc" or app == "bc" },
  by: { app, queue.id, queue.name }
| fieldsAdd status = arrayLast(status_series)
| fieldsRemove status_series, timeframe, interval
| sort app asc, queue.name asc
```

Add another `or app == "..."` for each application id your metric uses. The id on the existing tile is `pc`, not the full word PolicyCenter.

This query returns only applications that send `guidewire.messaging.status`. A service with no such metric does not appear. The number in `status` still means whatever that metric defines. Look up `guidewire.messaging.status` under Metrics before you treat 0 as healthy.

### Open problems across services

Use this when the question is “what is still open?”, rather than queue status.

```
fetch dt.davis.problems, from: now() - 24h
| filter event.status == "ACTIVE"
| fields display_id, event.status, event.category
| sort display_id desc
| limit 100
```

## Data flow map

```
guidewire.messaging.status
    -> every app, not only pc
    -> one series per app + queue
    -> keep the last average
    -> table sorted by app
```

## Related files

| File | What it is |
|---|---|
| 7-dql-all-applications-follow.txt | The queries, easy to copy. |
| 0-pic.md | How the filter change works. |
| 1-investigation.md | What the original tile did. |
| 2-result.md | The query to paste. |
| 3-glossary.md | The words in the query. |
| 7.sh | Copy commands. Run them yourself. |
