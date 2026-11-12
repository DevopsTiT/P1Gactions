# Alert Condition Is Not Set

```
This alert has a query
  Set scope is Completed
    the query can find INIT_START lines
  section 2 Define alert condition
    it is collapsed
    it does not say Completed
    Davis has no violation rule
  Save is still on the screen
    the editor is still open
  Problems stays empty
```

| What is finished | What is not finished |
|---|---|
| The query for `Runtime Version` lines. | Define alert condition. |
| The identity field `aws.log.group`. | The event name under Add details. |
| The actor. | A saved run that can open a problem. |

## Summary

This alert can find the startup lines. It does not yet say when those lines are a problem. Set scope is marked Completed. Define alert condition is not. Davis opens a problem from section 2, after Save.

## Investigation

| Item on the form | State |
|---|---|
| Screen | Edit alert, Advanced tab. Save is still visible. |
| Set scope | Completed. |
| Data type | Records. |
| Query | The e-signature log group, and `content` contains `Runtime Version`. |
| Matching lines | 514 INFO `INIT_START` lines over the last 7 days. |
| Identity field | `aws.log.group`. |
| Section 2 | Define alert condition is collapsed and is not marked Completed. |

## Result

1. Expand **Define alert condition**.
2. Set the condition. For a count, switch the data type to **Timeseries** and use the ERROR query below. For Records, the condition has to say which of these rows is a violation.
3. Expand **Add details**. Set the title and the event name to `Lambda log ERROR`.
4. Press **Save**.
5. Wait one minute, then open **Problems** for the last 2 hours with the filter bar cleared.

The query on this form matches normal startup lines. A finished Records condition on this text would open a problem because those INFO lines exist. That problem would mean the function started, not that it failed.

Use this query when the problem should mean an error.

```
fetch logs
| filter contains(aws.log.group, "/aws/lambda/light-digital-api-dev-confirm-e-signature", caseSensitive:false)
| filter loglevel == "ERROR"
| makeTimeseries error_count = count(), interval:1m
```

| Field | Value |
|---|---|
| Data type | Timeseries |
| Threshold | Above 0 |

## Data flow map

```
Set scope Completed
  query finds INIT_START lines
        |
        v
Define alert condition
  not completed
        |
        v
Davis has no violation
        |
        v
Problems stays empty
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Which section is missing. |
| `1-investigation.md` | What the form shows. |
| `2-result.md` | What to finish before Save. |
| `3-glossary.md` | The words. |
| `11-alert-condition-not-set-follow.txt` | The same answer for a phone. |
| `11.sh` | Copy commands. |

Commands: [11.sh](11.sh)
