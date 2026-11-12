# Preview Line Under Threshold

```
Preview chart
  red line is the threshold 101
  CPU line stays under that line
  the right edge is under it too
        |
        v
close Preview
  Save
  switch the alert on
        |
        v
wait about 3 minutes
  Problems search TESTDUMMY
  disable the alert
```

| What the chart shows | What it means |
|---|---|
| Red line across the top | The threshold at 101. |
| Blue line under the red line | CPU is below 101, so the condition is true. |
| Right edge of the chart | The newest minutes are also below 101. |

## Summary

Preview succeeded. The CPU line stays under the red threshold for the whole two hours, including the newest minutes. Close Preview, click Save, switch the alert on, then look on the Problems page for `TESTDUMMY`.

## Investigation

The screenshot is the alert Preview for the host CPU query. The time range on the chart is Last 2 hours. A red line sits at the top of the chart. The CPU line for `HOST-00026D8D201D203A` stays near the bottom, with a few spikes. The tallest spike still stays under the red line. After that spike, the line drops again, so the right edge is under the threshold too.

The red line is the threshold drawn by Preview. It is not a problem. The Edit alert page and this chart do not open a problem by themselves. Davis opens the problem after Save, on the next check.

## Result

1. Close Preview.
2. Confirm the query still contains `interval:1m`.
3. Confirm Query offset is `2`.
4. Confirm violating samples is `1`, sliding window is `5`, and the condition is below `101`.
5. Confirm the `dt.smartscape_source.id` row is deleted.
6. Click **Save**.
7. On the alerts list, switch `TESTDUMMY host entity` on.
8. Wait about 3 minutes.
9. Open **Problems**. Set the time to the last 30 minutes. Search `TESTDUMMY`.
10. Disable the alert after the problem shows.

This alert sends no email. The proof is the Problems page.

## Data flow map

```
Preview
  CPU under the red line
        |
        v
Save
  alert switched on
        |
        v
Davis check
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
| `63-preview-line-under-threshold.dql` | The query that belongs on the alert. |
| `0-pic.md` | From the chart to the Problems page. |
| `1-investigation.md` | What the Preview chart shows. |
| `2-result.md` | Save, then search Problems. |
| `3-glossary.md` | The words. |
| `63-preview-line-under-threshold-follow.txt` | The same steps for a phone. |
| `63.sh` | Copy commands. |

Commands: [63.sh](63.sh)
