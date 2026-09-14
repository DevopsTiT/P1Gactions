# Plain English Flow — Pic

```
Problem OPEN = alarm on
  → create WF packs data
  → opens SNOW ticket (stamp = Problem ID)
  → pages PD (same stamp as dedup_key)
  → writes stamp on ticket note

Problem CLOSE = all clear
  → close WF finds ticket by stamp
  → closes ticket + stops page
```
