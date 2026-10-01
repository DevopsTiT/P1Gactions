# Payload Keys Picture

```
OPEN
 ├─ SILVA POST incident   16 keys (correlation_id = display_id)
 └─ PD trigger            routing_key, event_action=trigger, dedup_key, payload{summary, source, severity, ...}, links
CLOSE
 ├─ SILVA PATCH incident  state, close_code, close_notes, comments, work_notes
 └─ PD resolve            routing_key, event_action=resolve, dedup_key (same as trigger)
```
