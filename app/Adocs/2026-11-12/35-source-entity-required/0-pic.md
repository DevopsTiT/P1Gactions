# Source Entity Required

```
log alert
  title and event name -> required
  event.type CUSTOM_ALERT -> keep
  dt.source_entity -> optional
    query has no entity -> leave it empty
```
