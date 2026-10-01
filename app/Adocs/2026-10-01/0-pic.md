# Close State Fix Pic

```
v1 run on INC30341416
  close_code ✔  close_notes ✔  work_notes ✔  state ✘
        ▼
v2 close-silva-incident
  PATCH state + incident_state = Resolved ── changed? ─ yes ─► resolved
        │ no
        ▼
  PATCH In Progress ─► PATCH Resolved ── changed? ─ yes ─► resolved
        │ no
        ▼
  failed + attempts list ─► 42.sh lines 1-6 (compare INC30340215, read sys_audit)
```
