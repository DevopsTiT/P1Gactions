# CloudWatch Log Dummy

```
CloudWatch logs in the last 2 hours?
  yes -> one row
         dt.source_entity = HOST-00026D8D201D203A
         problem opens on that host
         disable the alert
  no -> widen to 24 hours
        still no -> this environment has no recent CloudWatch logs
```

| Question | Answer |
|---|---|
| What opens the problem? | Any CloudWatch log line in the last 2 hours. |
| Which entity is attached? | `HOST-00026D8D201D203A` |
| Why not the error metric? | That chart is flat, so a short window cannot fire. |

## Summary

This dummy counts CloudWatch log lines. One matching line returns one row, and the event is pinned to a host id you already listed. The host is only the anchor. The logs did not come from that machine. Disable the alert after the problem appears.

## Investigation

The notebook returned five host ids. The first is `HOST-00026D8D201D203A`.

`log.lambda_errors` for `/aws/lambda/gov-inquiry-system-dev-logFailure` has old spikes and a flat recent window. A timeseries alert on that metric stays quiet.

`dt.entity.custom_device` is empty on that metric. A host id pasted into `dt.source_entity` does not depend on the log record carrying an entity.

The title `TESTDUMMY cloudwatch logs` does not start with `ALJ_`, so the existing mail profiles do not match it.

## Result

**1. Notebook proof. Last 2 hours.**

```
fetch logs, from: now()-2h
| filter contains(aws.log_group, "/aws/", caseSensitive:false)
| summarize log_count = count(), by: {aws.log_group}
| filter log_count > 0
| sort log_count desc
| limit 5
```

| Proof result | Next step |
|---|---|
| One or more rows | Paste the alert below. |
| The field name errors | Change `aws.log_group` to `aws.log.group` in every line. |
| 0 records | Change `now()-2h` to `now()-24h` and run it again. |

**2. Alert query.** Same field name that returned rows.

```
fetch logs, from: now()-2h
| filter contains(aws.log_group, "/aws/", caseSensitive:false)
| summarize log_count = count()
| filter log_count > 0
| fieldsAdd alert_key = "testdummy-cloudwatch"
```

**3. Event fields.**

| Key | Value |
|---|---|
| Title | `TESTDUMMY cloudwatch logs` |
| Event name | `TESTDUMMY cloudwatch logs` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `HOST-00026D8D201D203A` |
| `alert.severity` | `medium` |

No braces around the host id. Delete `{dt.entity.custom_device}`. Do not add an email action.

**4. Wait about 3 minutes.** Open **Problems** and search `TESTDUMMY`. The host is under Affected entities.

**5. Disable the alert.**

The Terraform shape is in [41-cloudwatch-log-dummy.tf](41-cloudwatch-log-dummy.tf). Swap the host id if you want one of the other four.

## Data flow map

```
CloudWatch log line in the last 2 hours
        |
        v
one row, alert_key testdummy-cloudwatch
        |
        v
event
  CUSTOM_ALERT
  title TESTDUMMY cloudwatch logs
  dt.source_entity HOST-00026D8D201D203A
        |
        +--> Problems shows TESTDUMMY
        |
        +--> Affected entities shows that host
        |
        v
disable the alert
```

## Related files

| File | Purpose |
|---|---|
| `41-cloudwatch-log-dummy.tf` | The detector to paste. |
| `41-cloudwatch-log-dummy.dql` | The proof query and the alert query. |
| `0-pic.md` | How the log row becomes a problem. |
| `1-investigation.md` | Why this uses a host id from the notebook. |
| `2-result.md` | The values to enter. |
| `3-glossary.md` | The words. |
| `41-cloudwatch-log-dummy-follow.txt` | The same notes for a phone. |
| `41.sh` | Copy commands. |

Commands: [41.sh](41.sh)
