# Query Box Unchanged

```
query box still starts with log.lambda_errors
  0 records in the short window
  Save stays quiet
replace the four lines with the host CPU query
  first word of line 1 must be timeseries cpu
  condition cpu below 101
  save
  Problems search TESTDUMMY
  disable the alert
```

| What is on the screen | What happens when you click Save |
|---|---|
| Line 1 is `timeseries errors = sum(log.lambda_errors)` | No problem. That series has no points in the last 2 hours. |
| Line 1 is `timeseries cpu = avg(dt.host.cpu.usage)` | A problem can open. That line already stayed under 20. |

## Summary

The alert is quiet because the query box was not replaced. The four lines on the screen are still the CloudWatch error metric. That metric returned 0 records in every short window we ran. Click the query box, delete those four lines, paste the host CPU query, set the condition to `cpu` below 101, then Save.

## Investigation

The new screenshot is the same Edit alert form. Data type is Timeseries. Actor is shuge kui. Source is Alert management, so this copy was saved from the UI. Define alert condition is marked completed. The query box still shows:

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
| fieldsAdd dt.entity.host = "HOST-00026D8D201D203A"
```

That query returned 0 records on Last 2 hours (14:03–16:04 and 14:25–16:26). `fieldsAdd` runs only after a series exists. With 0 records it never runs, so the host id is not attached and the threshold is never true.

The host CPU query already returned 1 record. The line stayed under 20. Below 101 is already true on that host.

## Result

Do these steps on the open form. Check the query box before you click Save.

1. Click inside the Query box.
2. Select all four lines and delete them.
3. Paste this:

```
timeseries cpu = avg(dt.host.cpu.usage),
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host}
```

4. Look at line 1. It must start with `timeseries cpu`. If it still says `log.lambda_errors`, the paste did not land. Delete and paste again.
5. Open **Define alert condition**.

| Setting | Value |
|---|---|
| Line | `cpu` |
| Condition | Below 101 |
| Window | A few minutes |

6. Open the event details.

| Key | Value |
|---|---|
| Title | `TESTDUMMY host entity` |
| Event name | `TESTDUMMY host entity` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `{dt.entity.host}` |

Keep the braces on `{dt.entity.host}`. Leave Actor as shuge kui. Leave Query offset empty. Leave Delay empty. Leave Data type on Timeseries.

7. Click Save.
8. Wait about 3 minutes.
9. Open **Problems** and search `TESTDUMMY`.
10. Disable the alert after the problem shows. This is a real problem on a real host.

The CloudWatch lines can stay in a notebook. They belong on an alert only after a new error point is stored and the condition is above 0.

## Data flow map

```
query box
  still log.lambda_errors
        |
        v
0 records
        |
        v
Save
        |
        v
no problem

query box
  timeseries cpu
        |
        v
line under 20
  below 101
  {dt.entity.host}
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
| `59-query-box-unchanged.dql` | The three lines to paste into the Query box. |
| `0-pic.md` | What to check before Save. |
| `1-investigation.md` | The screenshot still has the CloudWatch query. |
| `2-result.md` | The click order. |
| `3-glossary.md` | The words. |
| `59-query-box-unchanged-follow.txt` | The same steps for a phone. |
| `59.sh` | Copy commands. |

Commands: [59.sh](59.sh)
