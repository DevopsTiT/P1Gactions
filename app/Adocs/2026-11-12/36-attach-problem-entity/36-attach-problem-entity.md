# Attach Problem To Entity

```
want the problem to show on an entity
  the log row already has dt.entity.host?
    yes -> keep that field through summarize
           set dt.source_entity to {dt.entity.host}
    no -> create one custom device
          copy CUSTOM_DEVICE-...
          paste that id into dt.source_entity
          do not wrap it in braces
  the query returns a row?
    no -> Davis has nothing to open
    yes -> Problems shows the title
           Affected entities shows that device
```

| Question | Answer |
|---|---|
| Can the form mark `dt.source_entity` as required? | No. You make it always present by putting a real id in the value. |
| What id should a log-phrase alert use? | One custom device you create once. |
| What does the placeholder do? | It copies a field from the query. An empty field leaves the problem with no entity. |

## Summary

Paste a real entity id into `dt.source_entity`. Keep `event.type` as `CUSTOM_ALERT`. When the query returns a row, Davis opens a problem and that problem lists the entity under Affected entities.

## Investigation

The Edit alert screen has this row:

| Key | Value on the screen |
|---|---|
| `dt.source_entity` | `{dt.entity.custom_device}` |

The braces mean "copy this field from the query result". The log queries end in `summarize` and `fieldsAdd alert_key`. After `summarize`, only the count and the fields you grouped by are left. `dt.entity.custom_device` is not one of those fields, so the placeholder stays empty.

A problem still can open from `CUSTOM_ALERT` and the event name. It then has no affected entity, so it does not show on a host, a service, or a device page.

## Result

Use one custom device for a log-phrase alert. Create it once. Reuse the same id on every detector that should show up in the same place.

1. Create the device with the command in [36.sh](36.sh). The token needs permission to write entities. The reply contains `entityId`. It looks like `CUSTOM_DEVICE-` plus letters and numbers.
2. On the Edit alert screen, replace the placeholder with that id. No braces.
3. Keep `event.type` as `CUSTOM_ALERT`.
4. Keep the event name starting with the prefix the alerting profile matches.
5. Save. Wait until the query window contains a matching row. Davis runs about once a minute.
6. Open Problems and search the event name. The device is listed under Affected entities.

In Terraform, add this property inside the same `event_template` block the other detectors already use:

```hcl
property {
  key   = "dt.source_entity"
  value = "CUSTOM_DEVICE-PASTE_THE_ID"
}
```

The snippet file is [36-attach-problem-entity.tf](36-attach-problem-entity.tf).

Do not paste a production host id onto a batch or a log-phrase alert. That puts the problem on a host that did not fail.

Use a host only when the log line really belongs to that host. The query has to keep the host field:

```
fetch logs, from: now()-5m
| filter isNotNull(dt.entity.host)
| summarize failed_count = count(), by: { dt.entity.host }
| filter failed_count > 0
| fieldsAdd alert_key = dt.entity.host
```

Then set the value to `{dt.entity.host}`. The braces are correct here because the query returns that field. Each host gets its own problem.

You can delete the `dt.smartscape_source.id` row for these log alerts. `dt.source_entity` is the field that fills Affected entities.

To see the device id later:

```
fetch dt.entity.custom_device
| filter contains(entity.name, "ALJ SA Support Batch", caseSensitive:false)
| fields entity.name, id
```

## Data flow map

```
create one custom device
        |
        v
CUSTOM_DEVICE-... pasted into dt.source_entity
        |
        v
query returns one row
        |
        v
Davis event
  event.type CUSTOM_ALERT
  event.name starts with the prefix
        |
        +--> Problems shows the title
        |
        +--> Affected entities shows the custom device
        |
        +--> alerting profile matches the title and sends mail
```

## Related files

| File | Purpose |
|---|---|
| `36-attach-problem-entity.tf` | The one property to add. |
| `0-pic.md` | Which id to paste. |
| `1-investigation.md` | Why the placeholder stays empty. |
| `2-result.md` | The steps that make the problem show. |
| `3-glossary.md` | The words. |
| `36-attach-problem-entity-follow.txt` | The same notes for a phone. |
| `36.sh` | The command that creates the device. |

Commands: [36.sh](36.sh)
