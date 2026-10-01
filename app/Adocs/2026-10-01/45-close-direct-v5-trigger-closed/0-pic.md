# Close Trigger Pic

```
Trigger Event state?
 active            → wrong (open only)
 active or closed  → wrong (runs twice; guard skips the open run)
 closed            → right → Save → Deploy
```

```
Problem closes → trigger (closed) → prepare-close (is_closed?)
   ├─ yes → close-silva-incident (incident_state = Resolved)
   │      → close-pagerduty (resolve dedup_key)
   └─ no  → both tasks: skipped
```
