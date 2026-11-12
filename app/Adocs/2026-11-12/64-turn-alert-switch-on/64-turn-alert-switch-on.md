# Turn Alert Switch On

```
Preview chart
  CPU under the red line
  this screen has no alarm
        |
        v
close Preview
  read the saved query
  interval:1m is in line 1
  query offset is 2
  violating samples is 1
  smartscape row is gone
        |
        v
Save
  close Edit alert
        |
        v
All alerts list
  TESTDUMMY host entity
  switch is on
        |
        v
wait about 3 minutes
  Problems
  clear filters
  last 30 minutes
  search TESTDUMMY
        |
        +-- row found --> disable the alert
        |
        +-- no row --> run the events query
              0 records --> Davis did not raise an event
              a row --> the event exists and Problems is filtering it
```

| Place you look | What you should see |
|---|---|
| Preview chart | The CPU line under the red line. That check already passed. |
| All alerts list | The row `TESTDUMMY host entity` with the switch on. |
| Problems | A problem whose name contains `TESTDUMMY`. |
| Mailbox | Nothing. This alert has no email. |

## Summary

The red line on the chart is the threshold. Preview does not open a problem, and the Edit alert page does not show one either. Close that page, turn the list switch on, wait about 3 minutes, then search Problems for `TESTDUMMY`. If that page is empty, the events query shows whether Davis raised the event.

## Investigation

The last screenshot is the Preview chart for host `HOST-00026D8D201D203A`. The CPU line stays under the red threshold, including the newest minutes. That means below 101 is true for the data.

Every screenshot so far is either Edit alert or that chart. The All alerts list switch has not been in a screenshot. A saved detector still has to be switched on before Davis runs it. The Edit alert dialog covers that switch.

The problem, once raised, is a row on the Problems page. The chart does not grow a banner when the problem opens. This configuration has no email action, so the mailbox stays empty.

## Result

Close Preview and close Edit alert.

On **All alerts**, find `TESTDUMMY host entity`. Turn its switch on. If the row is missing, the form was not saved. Open it again and check these before Save:

| Field | Saved value |
|---|---|
| Query line 1 | Contains `interval:1m` |
| Query offset | `2` |
| Violating samples | `1` |
| Sliding window | `5` |
| Condition | Below 101 |
| `dt.smartscape_source.id` | Row deleted |
| `dt.source_entity` | `{dt.entity.host}` |

Click Save, close the dialog, and turn the switch on.

Wait about 3 minutes. Open **Problems**. Clear the filters. Set the time to the last 30 minutes. Search `TESTDUMMY`.

When the problem is there, disable the alert. It is a real problem on that host.

When Problems has no row, run this in a notebook and send the result:

```
fetch events, from: now()-30m
| filter contains(event.name, "TESTDUMMY", caseSensitive:false)
| fields timestamp, event.name, event.type
| sort timestamp desc
```

| Result | What it means |
|---|---|
| One or more rows | Davis raised the event. Clear the Problems filters and search again. |
| 0 records | Davis did not raise the event. Send the alerts-list screenshot with the switch visible. |

## Data flow map

```
Preview
  line under 101
        |
        v
Save
        |
        v
list switch on
        |
        v
Davis run
        |
        +-- event raised --> Problems TESTDUMMY --> disable
        |
        +-- no event --> events query returns 0 records
```

## Related files

| File | Purpose |
|---|---|
| `64-turn-alert-switch-on.dql` | The events query to run when Problems is empty. |
| `0-pic.md` | From the chart to the list switch. |
| `1-investigation.md` | Why the chart is not the alarm. |
| `2-result.md` | The list switch and the Problems search. |
| `3-glossary.md` | The words. |
| `64-turn-alert-switch-on-follow.txt` | The same steps for a phone. |
| `64.sh` | Copy commands. |

Commands: [64.sh](64.sh)
