# CloudWatch Log Alert

```
Last 2 hours of log.lambda_errors
  still 0 records
    add default: 0
    a flat 0 line appears
      condition above -1
      dt.source_entity = HOST-00026D8D201D203A
      problem opens
      disable the alert
    still 0 records
      fetch any /aws/ log from the last 24 hours
```

| Question | Answer |
|---|---|
| Which log group? | `/aws/lambda/gov-inquiry-system-dev-logFailure` |
| Why above -1? | A filled 0 is above -1, so the quiet chart still opens a problem. |
| Which entity? | `HOST-00026D8D201D203A` |

## Summary

Paste the timeseries with `default: 0`. Set the condition to above -1. Pin `dt.source_entity` to the host id from the notebook, with no braces. This fires because the recent error value is empty, not because a new error arrived. Disable it after the problem shows.

## Investigation

Last 2 hours of `log.lambda_errors` for this log group returned 0 records. The long chart showed old spikes and a flat recent section. An above-0 condition has no recent point to cross.

`default: 0` on `timeseries` fills empty slots with 0. A flat 0 line is a series the alert can judge. 0 is above -1.

The host id came from the CPU notebook. It is only the anchor so the problem has an affected entity. The Lambda logs did not come from that host.

## Result

**1. Notebook, Last 2 hours.** Confirm a flat line before saving the alert.

```
timeseries errors = sum(log.lambda_errors),
  default: 0,
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
```

| Notebook result | Next step |
|---|---|
| A flat line at 0 | Save the alert with the settings below. |
| Still 0 records | Use the fetch query in [42-cloudwatch-log-alert.dql](42-cloudwatch-log-alert.dql). |

**2. Alert condition.**

| Setting | Value |
|---|---|
| Line | `errors` |
| Condition | Above -1 |
| Window | A few minutes |

**3. Add details.**

| Key | Value |
|---|---|
| Title | `TESTDUMMY cloudwatch logs` |
| Event name | `TESTDUMMY cloudwatch logs` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `HOST-00026D8D201D203A` |

No braces. Delete `{dt.entity.custom_device}`. Do not add email. The title does not start with `ALJ_`.

**4. Wait about 3 minutes.** Open Problems and search `TESTDUMMY`. Then disable the alert.

For a real error alert later, remove `default: 0` and set the condition to above 0. That one stays quiet until a new error point is stored.

## Data flow map

```
dev logFailure
  no points in the last 2 hours
        |
        v
default 0 draws a flat line
        |
        v
above -1 is true
        |
        v
problem on HOST-00026D8D201D203A
        |
        v
disable the alert
```

## Related files

| File | Purpose |
|---|---|
| `42-cloudwatch-log-alert.dql` | The timeseries to paste, and the fetch backup. |
| `42-cloudwatch-log-alert.tf` | The record detector if the timeseries stays empty. |
| `0-pic.md` | How a flat 0 becomes a problem. |
| `1-investigation.md` | What the earlier charts showed. |
| `2-result.md` | The settings to save. |
| `3-glossary.md` | The words. |
| `42-cloudwatch-log-alert-follow.txt` | The same notes for a phone. |
| `42.sh` | Copy commands. |

Commands: [42.sh](42.sh)
