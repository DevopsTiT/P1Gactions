# Close Test Ticket Pic

```
Saved? ── no ──► leave the form, nothing to close
   │
  yes
   ▼
Form: State = Resolved + Resolution code + Resolution notes ──► Update
   │ blocked?
   ├─ Resolved missing  → In Progress first, save, then Resolved
   ├─ mandatory error   → fill Assigned to / resolution fields
   └─ read-only         → testing 3122 member or SILVA admin
   ▼
Resolved ──(auto-close timer)──► Closed

API path: GET by assignment group → sys_id → PATCH state 6 → GET to verify
```
