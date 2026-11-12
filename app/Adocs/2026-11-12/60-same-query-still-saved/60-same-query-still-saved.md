# Same Query Still Saved

```
this Edit alert screen
  line 1 is still log.lambda_errors
  last 2 hours has 0 records
  Save keeps a quiet alert
Discard
  create a new alert
  paste the host CPU query
  line 1 must say timeseries cpu
  cpu below 101
  Save that new alert
  Problems search TESTDUMMY
  disable it
```

| What you do | What you get |
|---|---|
| Save the form in the screenshot | No problem. The query has no points in the short window. |
| A new alert whose line 1 is `timeseries cpu` | A problem can open. That CPU line already stayed under 20. |

## Summary

The open form is still the CloudWatch error query. That query returned 0 records in the last 2 hours, so the condition never becomes true. Click Discard. Create a new alert and paste the host CPU query before you save it.

## Investigation

The screenshot is Edit alert, Simple tab, Data type Timeseries. The query box is:

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
| fieldsAdd dt.entity.host = "HOST-00026D8D201D203A"
```

Actor is shuge kui. Source is Alert management. Define alert condition is marked completed. The query text is the same as the previous save.

That metric returned 0 records on Last 2 hours. `fieldsAdd` does not create points. The alert uses a short window, so it stays quiet.

The host CPU query returned 1 record. The line stayed under 20. Below 101 is already true.

This form also has no email action. A problem, when one exists, shows under Problems.

## Result

Click **Discard**. Do not click Save on this window.

On the alerts list, create a new alert. Set it like this before the first save.

**Query.** Data type Timeseries. Paste:

```
timeseries cpu = avg(dt.host.cpu.usage),
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host}
```

Read line 1. It must start with `timeseries cpu`.

**Condition.**

| Setting | Value |
|---|---|
| Line | `cpu` |
| Condition | Below 101 |
| Window | A few minutes |

**Event details.**

| Key | Value |
|---|---|
| Title | `TESTDUMMY host entity` |
| Event name | `TESTDUMMY host entity` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `{dt.entity.host}` |

Leave the braces in `{dt.entity.host}`. Leave offset empty. Leave delay empty. Do not add an email on this test.

Save the new alert. Wait about 3 minutes. Open **Problems** and search `TESTDUMMY`. Then disable the new alert. It is a real problem on a real host.

The CloudWatch query on the old form can alarm after a new error point is stored and the condition is above 0.

## Data flow map

```
open form
  log.lambda_errors
  0 records
        |
        v
Discard

new alert
  timeseries cpu
  line under 20
  below 101
  {dt.entity.host}
        |
        v
Save
        |
        v
Problems TESTDUMMY
        |
        v
disable the new alert
```

## Related files

| File | Purpose |
|---|---|
| `60-same-query-still-saved.dql` | The query for the new alert. |
| `0-pic.md` | Discard, then create. |
| `1-investigation.md` | The screenshot still has the old query. |
| `2-result.md` | The values for the new alert. |
| `3-glossary.md` | The words. |
| `60-same-query-still-saved-follow.txt` | The same steps for a phone. |
| `60.sh` | Copy commands. |

Commands: [60.sh](60.sh)
