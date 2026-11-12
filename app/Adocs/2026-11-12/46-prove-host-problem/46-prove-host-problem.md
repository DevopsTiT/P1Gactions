# Prove Host Problem

```
notebook, last 2 hours
  one row with dt.entity.host?
    yes -> save the same query on the alert
           cpu below 101
           dt.source_entity = {dt.entity.host}
           Problems shows TESTDUMMY
           disable the alert
    no -> do not save the alert
```

| Step | What proves it |
|---|---|
| Notebook returns one row | The query works, and the entity column is filled. |
| Problems shows TESTDUMMY | The alert opened a problem on that host. |

## Summary

Replace the Lambda query with one host CPU series. The notebook must show one row before you save. The condition is below 101, so the problem opens. `{dt.entity.host}` copies the host from that row.

## Investigation

The alert on the screen uses `log.lambda_errors` for `/aws/lambda/gov-inquiry-system-dev-logFailure`, grouped by `dt.entity.custom_device`, then drops nulls. Last 2 hours of that metric, without the custom device, was already 0 records. There is no row and no entity to attach.

Host CPU for `HOST-00026D8D201D203A` has a real `dt.entity.host` column. Any CPU reading is below 101.

## Result

**1. Notebook proof. Picker Last 2 hours.** Save the alert only if this returns one row.

```
timeseries cpu = avg(dt.host.cpu.usage),
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host}
```

The row must show `dt.entity.host` = `HOST-00026D8D201D203A`.

**2. Paste that same query into the Timeseries box.** Data type stays Timeseries. Leave Actor as it is. Leave offset and delay empty.

**3. Define alert condition.**

| Setting | Value |
|---|---|
| Line | `cpu` |
| Condition | Below 101 |
| Window | A few minutes |

**4. Add details.**

| Key | Value |
|---|---|
| Title | `TESTDUMMY host entity` |
| Event name | `TESTDUMMY host entity` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `{dt.entity.host}` |

Keep the braces. Do not add an email action. Do not add `isNotNull`.

**5. Save. Wait about 3 minutes.** Open Problems and search `TESTDUMMY`. Affected entities should list `HOST-00026D8D201D203A`.

**6. Disable the alert.**

If the notebook row is missing, do not save. The alert would have nothing to judge.

## Data flow map

```
notebook last 2 hours
  one host CPU row
        |
        v
same query on the alert
  cpu below 101
  {dt.entity.host}
        |
        v
Problems
  title TESTDUMMY
  affected host HOST-00026D8D201D203A
        |
        v
disable the alert
```

## Related files

| File | Purpose |
|---|---|
| `46-prove-host-problem.dql` | The query to run, then paste. |
| `0-pic.md` | The proof order. |
| `1-investigation.md` | Why the Lambda box cannot prove a problem today. |
| `2-result.md` | The settings that open the problem. |
| `3-glossary.md` | The words. |
| `46-prove-host-problem-follow.txt` | The same notes for a phone. |
| `46.sh` | Copy commands. |

Commands: [46.sh](46.sh)
