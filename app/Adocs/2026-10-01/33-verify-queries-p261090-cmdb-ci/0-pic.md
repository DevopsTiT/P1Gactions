# Verify Queries Pic

```
query 2 (history) rows? ── yes ─► query 3 top offering ─► query 4 valid? ─► rerun seq 30 ─► query 10
        │ no
        ▼
query 6 (group offerings) rows? ── yes ─► query 7 Development pick ─► query 4 ─► rerun ─► query 10
        │ no
        ▼
workflow cannot find offering ─► SERVICE_MAP entry or CMDB link for ts12
```
