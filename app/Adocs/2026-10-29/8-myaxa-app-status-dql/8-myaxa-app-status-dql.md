# My Axa App Status Query

```
My Axa tile shows 0 records
  any CUSTOM_INFO in this window?
    no → blank tile. That is not OK. Widen the timeframe
    yes → which application values exist?
      agj-myaxa missing → the name on the event is different
      agj-myaxa present → newest event
        jobs text contains "NG :" → status NG
        jobs text has no "NG :" → status OK
  want every application?
    drop application == "agj-myaxa"
    keep the newest event per application
```

| Key point | Detail |
|---|---|
| Tile | My Axa. |
| Data | Dynatrace events of type `CUSTOM_INFO`. |
| This tile | Only the application value `agj-myaxa`. |
| Status rule | Newest event. `NG` when `jobs` contains `NG :`. Otherwise `OK`. |
| This run | 0 records, 09:28:29–11:28:29. The tile has no status. |
| All applications | Remove the one-name filter and keep one row per `application`. |

## Summary

This tile reads custom info events and turns the newest one for `agj-myaxa` into a single status, `OK` or `NG`. The run on screen found no matching event in the last two hours, so the tile is blank. Blank means no report, not a healthy application. The all-applications query uses the same status rule and returns one row for each application that sent an event.

## Investigation

| Source | Finding |
|---|---|
| Tile name | My Axa. |
| Line 1 | `fetch events`. |
| Line 2 | Keeps `event.type == "CUSTOM_INFO"`. |
| Line 3 | Drops events whose `application` field is empty. |
| Line 5 | Keeps only `application == "agj-myaxa"`. |
| Line 7 | Newest event first. |
| Lines 9–15 | Adds `application_status`. `NG` when `contains(jobs, "NG :")` is true. Otherwise `OK`. |
| Lines 17–19 | Output column is `status`. `limit 1` keeps one row. |
| Result line | 0 records. Executed 10/29/2026 11:28:30. Timeframe 09:28:29–11:28:29. Scanned 0.03 GiB. |

The `contains` on this tile has no `caseSensitive:false`. The all-applications query below adds that flag.

## Result

Read the tile from top to bottom.

`fetch events` loads events in the notebook timeframe. Here that window is about two hours, 09:28 to 11:28.

`event.type == "CUSTOM_INFO"` keeps custom info events. Other event types are ignored.

`isNotNull(application)` drops events that have no application name. The next line already requires the name `agj-myaxa`, so this line does not change the result for this tile.

`application == "agj-myaxa"` keeps one application. The match is exact. A different spelling does not appear.

`sort timestamp desc` puts the newest event first.

`fieldsAdd` does not delete the event. It adds `application_status`. The `if` checks whether the `jobs` text contains the characters `NG :`. A match sets `NG`. No match sets `OK`. This is the newest event only, because of the later `limit 1`. An older `NG` in the same window is ignored when a newer event does not contain `NG :`.

`fields status = application_status` leaves one column, named `status`.

`limit 1` returns that newest status and nothing else.

This run returned 0 records. The query did run. It scanned 0.03 GiB and found no `CUSTOM_INFO` event for `agj-myaxa` in that window. A single-value tile with no row shows no status. Do not read that as `OK`.

Common reasons for 0 records:

| Check | What it means |
|---|---|
| Timeframe is two hours | The job may report less often than that. Widen the picker, then run again. |
| Name must match exactly | The event may use a different `application` value. |
| No custom info at all | The first query below also returns 0. |

See which application names exist in the current window:

```
fetch events
| filter event.type == "CUSTOM_INFO"
| filter isNotNull(application)
| summarize event_count = count(), by: { application }
| sort application asc
```

One status row for every application that sent a `CUSTOM_INFO` event:

```
fetch events
| filter event.type == "CUSTOM_INFO"
| filter isNotNull(application)
| fieldsAdd application_status = if(contains(jobs, "NG :", caseSensitive:false), "NG", else: "OK")
| sort timestamp desc
| summarize status = takeFirst(application_status), last_seen = takeFirst(timestamp), by: { application }
| sort application asc
```

`sort timestamp desc` before `summarize` makes `takeFirst` the newest event in each application. `last_seen` is that event’s time. An application with no event in the window is absent. Absence is not `OK`.

Only `agj-myaxa` is visible on this tile. Do not add other names until the count query shows them.

## Data flow map

```
Notebook timeframe (this run: 09:28–11:28)
        |
        v
fetch events
        |
        v
keep CUSTOM_INFO
        |
        v
keep application is not empty
        |
        +-- this tile --> keep application == "agj-myaxa"
        |                         |
        |                         v
        |                 newest event only
        |                         |
        |                         v
        |                 jobs contains "NG :" ?
        |                    yes → status NG
        |                    no  → status OK
        |                         |
        |                         v
        |                 0 records this run → no status
        |
        +-- all applications --> newest event per application
                                      |
                                      v
                                 one row: application, status, last_seen
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What the screenshot shows. |
| `2-result.md` | How to read 0 records, plus both queries. |
| `3-glossary.md` | Terms. |
| `8-myaxa-app-status-dql-follow.txt` | Same paste for mobile. |
| `8.sh` | Copy commands. |

Commands: [8.sh](8.sh)
