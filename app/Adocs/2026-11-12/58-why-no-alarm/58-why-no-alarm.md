# Why No Alarm

```
CloudWatch query on the alert
  last 2 hours is 0 records
    no line
    no threshold crossed
    no problem
host CPU query
  1 record
  line under 20
  below 101 opens a problem
```

| Query | Can it alarm today? |
|---|---|
| `log.lambda_errors` for the dev log group | No. The short window has no points. |
| Host CPU for `HOST-00026D8D201D203A` | Yes. The line is already under 20. |

## Summary

The alert on the screen cannot open a problem. Its metric stored nothing in the last 2 hours. Replace the query with the host CPU query that already returned a row, and set the condition to below 101.

## Investigation

The form uses:

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
| fieldsAdd dt.entity.host = "HOST-00026D8D201D203A"
```

That query returned 0 records from 14:25 to 16:26, and again from 14:03 to 16:04. `fieldsAdd` does not create metric points. The alert window is a few minutes. It does not use a 365-day notebook picker.

Define alert condition is marked completed. A completed form still needs a line. No line means the condition is never true.

The host query returned 1 record. The CPU line stayed under 20.

## Result

Replace the query with:

```
timeseries cpu = avg(dt.host.cpu.usage),
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host}
```

| Setting | Value |
|---|---|
| Line | `cpu` |
| Condition | Below 101 |
| Window | A few minutes |
| Title | `TESTDUMMY host entity` |
| Event name | `TESTDUMMY host entity` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `{dt.entity.host}` |

Keep the braces. Delete `{dt.entity.custom_device}` if it is still there. Do not add email.

Save. Wait about 3 minutes. Open Problems and search `TESTDUMMY`. Then disable the alert.

The CloudWatch query can alarm later, when a new error point is stored and the condition is above 0. It cannot alarm on today's empty window.

## Data flow map

```
log.lambda_errors
  0 records
  no alarm
        |
host CPU
  1 record under 20
  below 101
        |
        v
problem TESTDUMMY
```

## Related files

| File | Purpose |
|---|---|
| `58-why-no-alarm.dql` | The query that can open a problem. |
| `0-pic.md` | Why the current alert stays quiet. |
| `1-investigation.md` | The empty window. |
| `2-result.md` | The query to paste instead. |
| `3-glossary.md` | The words. |
| `58-why-no-alarm-follow.txt` | The same notes for a phone. |
| `58.sh` | Copy commands. |

Commands: [58.sh](58.sh)
