# Fill Timeseries Alert

```
this alert form
  replace the lambda query
  with the host query that returned 1 record
  condition cpu below 101
  dt.source_entity = {dt.entity.host}
  save
  Problems shows TESTDUMMY
  disable the alert
```

| Form section | What to put |
|---|---|
| Data type | Timeseries |
| Query | The host CPU query below |
| Condition | `cpu` below 101 |
| Entity | `{dt.entity.host}` |

## Summary

Replace the four query lines on this screen with the host query that already returned one record. Set the condition to below 101. Set `dt.source_entity` to `{dt.entity.host}`. Save, find `TESTDUMMY` in Problems, then disable the alert.

## Investigation

The open alert still queries `log.lambda_errors` for the dev log group and requires `dt.entity.custom_device`. That query has no recent points, and the custom device field is empty.

The notebook already returned 1 record for:

```
timeseries cpu = avg(dt.host.cpu.usage),
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host}
```

The line stayed under 20 from 13:37 to 15:38. Below 101 is already true. The row has `dt.entity.host`.

The yellow note asks for `dt.smartscape_source.id`. This proved query uses `dt.entity.host` instead, because that is the column the notebook returned.

The screen says the config source is Terraform. A save in the UI can be overwritten the next time Terraform runs. For this test, save in the UI, then disable the alert after the problem shows.

## Result

**Query.** Replace the whole query box with:

```
timeseries cpu = avg(dt.host.cpu.usage),
  filter: {dt.entity.host == "HOST-00026D8D201D203A"},
  by: {dt.entity.host}
```

**Leave these as they are.**

| Field | Value |
|---|---|
| Data type | Timeseries |
| Actor | shuge kui |
| Query offset | Empty |
| Delay | Empty |

**Define alert condition.**

| Setting | Value |
|---|---|
| Line | `cpu` |
| Condition | Below 101 |
| Window | A few minutes |

**Add details.**

| Key | Value |
|---|---|
| Title | `TESTDUMMY host entity` |
| Event name | `TESTDUMMY host entity` |
| `event.type` | `CUSTOM_ALERT` |
| `dt.source_entity` | `{dt.entity.host}` |

Keep the braces. Do not add `isNotNull`. Do not add email.

Save. Wait about 3 minutes. Open Problems and search `TESTDUMMY`. Affected entities should list `HOST-00026D8D201D203A`. Then disable the alert.

## Data flow map

```
proved host query
        |
        v
paste into this Timeseries box
  cpu below 101
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
| `48-fill-timeseries-alert.dql` | The query to paste over the Lambda query. |
| `0-pic.md` | Which box to replace. |
| `1-investigation.md` | Why the current query stays. |
| `2-result.md` | The values for each section. |
| `3-glossary.md` | The words. |
| `48-fill-timeseries-alert-follow.txt` | The same notes for a phone. |
| `48.sh` | Copy commands. |

Commands: [48.sh](48.sh)
