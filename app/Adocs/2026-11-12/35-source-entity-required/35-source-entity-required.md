# Source Entity Required

```
Davis Edit alert
  Title filled in?
    empty -> the form will not save
  Event name filled in?
    empty -> the form will not save
  event.type is CUSTOM_ALERT?
    yes -> the alerting profile can match the problem
  dt.source_entity set?
    empty -> the problem still opens
    {dt.entity.custom_device} -> only attaches an entity when the query returns one
    a real entity id -> the problem shows on that entity
```

| Question | Answer |
|---|---|
| Is `dt.source_entity` required? | No |
| What is required on this screen? | Title and event name |
| What keeps the mail path working? | `event.type` set to `CUSTOM_ALERT`, and a title the profile matches |

## Summary

`dt.source_entity` tells Dynatrace which entity the problem belongs to. Your log alerts do not need it. They open a problem from the event name and `CUSTOM_ALERT`. The value on this screen, `{dt.entity.custom_device}`, only fills in when the query result actually has a custom device.

## Investigation

The Edit alert screen shows these event properties:

| Property | Value on the screen | What it does |
|---|---|---|
| `dt.smartscape_source.id` | `{dt.smartscape_source.id}` | Links the event to a Smartscape object when the query provides one |
| `event.type` | `CUSTOM_ALERT` | Makes this a custom alert the alerting profile can match |
| `event.description` | The anomaly sentence | Text inside the problem |
| `event.name` | `Test on cloudwatch logs` | The problem title |
| `dt.source_entity` | `{dt.entity.custom_device}` | The affected entity, when that field exists |

The form marks Title and Event name with a star. `dt.source_entity` has no star. The trash icon next to it means you can remove that row.

The Terraform used for the Splunk alerts sets `event.type`, `event.name`, `event.description`, `alert.severity`, `app.name`, and `pagerduty.enabled`. It does not set `dt.source_entity`. Those detectors still return a row and open a problem.

The queries end in `summarize` and `fieldsAdd alert_key`. That result has a count and an alert key. It does not have a custom device, a host, or a service.

## Result

Leave `dt.source_entity` empty for these log alerts. Keep `event.type` as `CUSTOM_ALERT`. Keep the event name starting with the prefix the alerting profile matches, such as `ALJ_SABATCH`.

Add `dt.source_entity` later only when you want the problem to sit on a real host, service, or custom device. Paste that entity's id, or return the entity from the query. The placeholder `{dt.entity.custom_device}` does not invent an entity.

`dt.smartscape_source.id` is the same kind of optional link. You can remove that row too for these log alerts.

## Data flow map

```
log query returns one row
        |
        +--> event.name and CUSTOM_ALERT
        |      problem opens
        |      alerting profile matches the title
        |      email goes out
        |
        +--> dt.source_entity
               empty -> problem still opens
               real entity id -> problem also shows on that entity
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | When the entity field matters. |
| `1-investigation.md` | What the Edit alert screen shows. |
| `2-result.md` | What to keep and what you can remove. |
| `3-glossary.md` | The words. |
| `35-source-entity-required-follow.txt` | The same notes for a phone. |
| `35.sh` | Copy commands. |

Commands: [35.sh](35.sh)
