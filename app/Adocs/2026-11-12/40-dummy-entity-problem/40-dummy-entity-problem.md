# Dummy Entity Problem

```
need a problem on an entity now
  notebook returns one HOST id?
    yes -> alert that one host
           cpu below 101
           dt.source_entity = {dt.entity.host}
           problem opens in a few minutes
           disable the alert
    no host rows -> this environment has no host metric
           a Lambda error chart cannot force a problem today
```

| Question | Answer |
|---|---|
| What fires today? | One host whose CPU is being reported. |
| What attaches the entity? | `dt.source_entity` set to `{dt.entity.host}` |
| What must the title avoid? | A name that starts with `ALJ_` |

## Summary

Paste a one-host CPU query, set the condition to below 101, and point `dt.source_entity` at `{dt.entity.host}`. Any live CPU reading crosses that line, so a problem opens on that host. Disable the alert after you see it.

## Investigation

`log.lambda_errors` for the dev log group is flat in the recent window. A short alert window has nothing to cross, so that metric cannot open a problem today.

`dt.entity.custom_device` is empty on that metric. Filtering on it removes the line.

`dt.host.cpu.usage` is reported for every monitored host. Grouping by `dt.entity.host` puts a real entity id on the result. The event template can copy that id.

A title that starts with `ALJ_` matches an existing mail profile. This test uses `TESTDUMMY host entity`.

## Result

**1. In a notebook, last 30 minutes, copy one id.** It looks like `HOST-` plus letters and numbers.

```
timeseries cpu = avg(dt.host.cpu.usage), by: {dt.entity.host}
| filter isNotNull(dt.entity.host)
| limit 5
| fields dt.entity.host
```

If this returns 0 records, stop. This environment has no host CPU metric, so this dummy cannot attach `dt.entity.host`.

**2. Paste this into the alert query.** Replace the id.

```
timeseries cpu = avg(dt.host.cpu.usage),
  filter: {dt.entity.host == "HOST-PASTE_ONE_ID"},
  by: {dt.entity.host}
```

**3. Define alert condition.**

| Setting | Value |
|---|---|
| Line | `cpu` |
| Condition | Below 101 |
| Window | A few minutes |

A CPU reading is below 101, so the condition is met as soon as Davis evaluates it.

**4. Add details.**

| Key | Value |
|---|---|
| Title | `TESTDUMMY host entity` |
| Event name | `TESTDUMMY host entity` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `{dt.entity.host}` |

The braces stay on this one. The query returns `dt.entity.host`, so Davis copies the id. Delete the `{dt.entity.custom_device}` row. Do not add an email action.

**5. Save and wait about 3 minutes.** Open **Problems** and search `TESTDUMMY`. The host is listed under Affected entities.

**6. Disable the alert.** It will keep the problem open, and it will open again, while it stays enabled.

If the yellow note still asks for `dt.smartscape_source.id`, add it to `by` only after the notebook still returns a row:

```
timeseries cpu = avg(dt.host.cpu.usage),
  filter: {dt.entity.host == "HOST-PASTE_ONE_ID"},
  by: {dt.entity.host, dt.smartscape_source.id}
```

Then set `dt.smartscape_source.id` to `{dt.smartscape_source.id}`. If that query returns 0 records, remove `dt.smartscape_source.id` and keep the host-only query.

## Data flow map

```
one HOST id
        |
        v
cpu below 101
        |
        v
Davis event
  event.type CUSTOM_ALERT
  event.name TESTDUMMY host entity
  dt.source_entity = that HOST id
        |
        +--> Problems shows TESTDUMMY
        |
        +--> Affected entities shows the host
        |
        v
disable the alert
```

## Related files

| File | Purpose |
|---|---|
| `40-dummy-entity-problem.dql` | The find query and the alert query. |
| `0-pic.md` | How the dummy opens one problem. |
| `1-investigation.md` | Why the Lambda metric cannot fire today. |
| `2-result.md` | The settings to paste. |
| `3-glossary.md` | The words. |
| `40-dummy-entity-problem-follow.txt` | The same notes for a phone. |
| `40.sh` | Copy commands. |

Commands: [40.sh](40.sh)
