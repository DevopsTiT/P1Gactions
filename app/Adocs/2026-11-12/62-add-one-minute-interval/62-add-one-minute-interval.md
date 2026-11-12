# Add One Minute Interval

```
Davis reads one-minute samples
  query has no interval:1m
  the check never lines up
  no event
add interval:1m
  query offset 2
  violating samples 1
  delete the smartscape row
  Preview
  Save
  Problems search TESTDUMMY
  disable the alert
```

| Setting | Value to save |
|---|---|
| Query interval | `interval:1m` |
| Query offset | 2 |
| Threshold | 101 |
| Condition | Below |
| Violating samples | 1 |
| Sliding window | 5 |
| `dt.source_entity` | `{dt.entity.host}` |
| Where the problem shows | Problems, search `TESTDUMMY` |

## Summary

The host query is the right metric, and the CPU line is already under 20. Davis still raises no event because the query does not set `interval:1m`. The detector compares one-minute samples. Add that interval, shift the window back by 2 minutes, set violating samples to 1, delete the smartscape row, then Save. The problem shows on the Problems page.

## Investigation

The Edit alert dialog is still open. The query is:

```
timeseries cpu = avg(dt.host.cpu.usage),
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host}
```

Query offset is empty. Actor is shuge kui. Source is Davis Anomaly Detection. Define alert condition and Add details are marked completed.

The event template still has `dt.smartscape_source.id` set to `{dt.smartscape_source.id}`. The query does not return that column. `dt.source_entity` is `{dt.entity.host}`. Title and event name are `TESTDUMMY host entity`. `event.type` is `CUSTOM_ALERT`.

The same host query returned one record in a notebook, and the line stayed under 20. A notebook picks its own bucket size for a long range. A Davis static-threshold alert does not. Dynatrace requires the alert query to set `interval:1m`. The sliding window then means one-minute samples. A query without that interval does not give Davis the five one-minute points it is counting.

Host CPU also arrives a minute or two after the minute closes. An empty query offset evaluates the newest minutes, which can still be empty. Query offset `2` moves the window onto minutes that already have a number.

The Edit alert page does not list opened problems. Those show on the Problems page.

## Result

Paste this over the query:

```
timeseries cpu = avg(dt.host.cpu.usage), interval:1m,
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host}
```

Then set the rest:

| Field | Value |
|---|---|
| Query offset | `2` |
| Delay | Leave empty |
| Threshold | `101` |
| Alert condition | Below |
| Violating samples | `1` |
| Sliding window | `5` |
| Dealerting samples | `5` |

In Add details, click the trash icon on `dt.smartscape_source.id`. Leave these rows:

| Key | Value |
|---|---|
| Title | `TESTDUMMY host entity` |
| Event name | `TESTDUMMY host entity` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `{dt.entity.host}` |

Click **Preview**. You want one-minute points sitting under 101. If Preview has no line, stop and send that picture.

Click **Save**. Close the dialog. On the alerts list, the row `TESTDUMMY host entity` must be switched on.

Wait about 3 minutes. Open **Problems**, set the time to the last 30 minutes, and search `TESTDUMMY`. Then disable the alert. It is a real problem on that host.

This alert sends no email. The mailbox stays empty.

Do not add `dt.smartscape_source.id` to the `by` line. Do not add `from:` or `to:` to this query.

## Data flow map

```
host CPU
  one-minute points
  each point under 20
        |
        v
query with interval:1m
  offset 2 minutes
        |
        v
1 point below 101
        |
        v
Save
  alert switched on
        |
        v
Problems TESTDUMMY
        |
        v
disable the alert
```

## Related files

| File | Purpose |
|---|---|
| `62-add-one-minute-interval.dql` | The query to paste, with `interval:1m`. |
| `0-pic.md` | Why the current save stays quiet. |
| `1-investigation.md` | What the two screenshots show. |
| `2-result.md` | The fields to change before Save. |
| `3-glossary.md` | The words. |
| `62-add-one-minute-interval-follow.txt` | The same steps for a phone. |
| `62.sh` | Copy commands. |

Commands: [62.sh](62.sh)
