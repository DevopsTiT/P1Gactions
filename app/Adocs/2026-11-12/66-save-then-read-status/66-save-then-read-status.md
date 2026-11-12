# Save Then Read Status

```
query has interval:1m
threshold is below 101
violating samples is 1
offset is 2
        |
        v
delete the smartscape row
        |
        v
Save
close Edit alert
        |
        v
All alerts
  row TESTDUMMY
  read Status
        |
        +-- Inactive --> switch on
        +-- Pending --> wait 2 minutes
        +-- Error --> send the status text
        +-- Success --> Problems, filters cleared, search TESTDUMMY
```

| What is saved | Value on the form |
|---|---|
| Query | Host CPU with `interval:1m` |
| Query offset | `2` |
| Threshold | Below `101` |
| Violating samples | `1` |
| Title and event name | `TESTDUMMY` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `{dt.entity.host}` |

## Summary

The metric, the one-minute interval, the offset, and the threshold are the values Davis needs. The Edit alert page still cannot show the problem. Delete the smartscape property, click Save, close the page, and read Status on the All alerts row.

## Investigation

The open form has this query:

```
timeseries cpu = avg(dt.host.cpu.usage), interval:1m,
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host}
```

Query offset is 2. The condition is static threshold, below 101, with 1 violating sample in a window of 5. Alert on missing data is on. Actor is shuge kui.

Title and event name are now `TESTDUMMY`. `event.type` is `CUSTOM_ALERT`. `dt.source_entity` is `{dt.entity.host}`.

The property `dt.smartscape_source.id` is still set to `{dt.smartscape_source.id}`. The query does not produce that column.

The dialog is still open. Problems and the All alerts Status column are behind it. An empty search happened while this editor was the page on screen. This editor does not list problems.

## Result

1. In **Add details**, click the trash can on the row `dt.smartscape_source.id`.
2. Leave `dt.source_entity` as `{dt.entity.host}`.
3. Click **Save**.
4. Click the **X** and leave Edit alert.
5. On **All alerts**, open the row `TESTDUMMY` and read **Status**.

| Status | Next step |
|---|---|
| Inactive | Turn the switch on. Wait 3 minutes. |
| Pending | Wait 2 minutes and read Status again. |
| Error | Do not Save again. Send a screenshot of the Status text. |
| Success | On Problems, clear every filter, set the last 2 hours, and search `TESTDUMMY`. |

Send a screenshot of the list row with the Status column visible.

The result is a row on Problems. This alert sends no email. Disable the alert after the problem shows.

## Data flow map

```
saved query
  interval:1m
  below 101
        |
        v
Save and close
        |
        v
Status on the list
        |
        +-- off or failing --> fix that status
        |
        +-- Success
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
| `66-save-then-read-status.dql` | The query already on the form. |
| `0-pic.md` | Save, close, then read Status. |
| `1-investigation.md` | What the three screenshots show. |
| `2-result.md` | The trash can, Save, and Status. |
| `3-glossary.md` | The words. |
| `66-save-then-read-status-follow.txt` | The same steps for a phone. |
| `66.sh` | Copy commands. |

Commands: [66.sh](66.sh)
