# CloudWatch Entity Variable

```
dev logFailure metric
  default 0 fills empty slots
  fieldsAdd dt.entity.host
  notebook shows a flat 0 line
    condition above -1
    dt.source_entity = {dt.entity.host}
    problem opens
    disable the alert
  notebook still 0 records
    do not save
    there is no series to judge
```

| Piece | Value |
|---|---|
| Log group | `/aws/lambda/gov-inquiry-system-dev-logFailure` |
| Variable | `{dt.entity.host}` |
| Condition | `errors` above -1 |

## Summary

This is the CloudWatch version of the host test. The metric stays on the dev log group. `default: 0` gives the empty window a line. `fieldsAdd` puts the proved host id on that row. `{dt.entity.host}` copies it onto the problem. Above -1 is true for a 0 line, so the problem opens. Disable the alert after you see it.

## Investigation

Last 2 hours of `log.lambda_errors` for this log group returned 0 records. The metric has no `dt.entity.host` dimension. Putting a host in `by` removes the line.

The host id `HOST-00026D8D201D203A` is already proved on the CPU query. It is only the anchor here. The Lambda logs did not come from that machine.

## Result

**1. Notebook, Last 2 hours.** Save the alert only if you see a flat line at 0.

```
timeseries errors = sum(log.lambda_errors),
  default: 0,
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
| fieldsAdd dt.entity.host = "HOST-00026D8D201D203A"
```

**2. Paste that query into the Timeseries box.**

| Setting | Value |
|---|---|
| Line | `errors` |
| Condition | Above -1 |
| Window | A few minutes |
| Title | `TESTDUMMY cloudwatch logs` |
| Event name | `TESTDUMMY cloudwatch logs` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `{dt.entity.host}` |

Keep the braces. Do not add `isNotNull`. Do not add email.

**3. Save. Wait about 3 minutes.** Open Problems and search `TESTDUMMY`. Affected entities should list `HOST-00026D8D201D203A`. Then disable the alert.

This opens because the filled value is 0, not because a new error arrived. A real error alert removes `default: 0` and uses above 0.

If the notebook is still 0 records, do not save. `default: 0` did not create a series, so the alert has nothing to judge.

## Data flow map

```
empty log.lambda_errors window
        |
        v
default 0
        |
        v
fieldsAdd dt.entity.host
        |
        v
{dt.entity.host} on the problem
  above -1 is true
        |
        v
disable the alert
```

## Related files

| File | Purpose |
|---|---|
| `50-cloudwatch-entity-variable.dql` | The query to prove, then paste. |
| `0-pic.md` | How the empty metric still opens a problem. |
| `1-investigation.md` | Why the host is added after the metric. |
| `2-result.md` | The problem field and the condition. |
| `3-glossary.md` | The words. |
| `50-cloudwatch-entity-variable-follow.txt` | The same notes for a phone. |
| `50.sh` | Copy commands. |

Commands: [50.sh](50.sh)
