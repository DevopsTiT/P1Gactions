# Pic — empty after scan

```
No data + Scanned GB > 0
  │
  ├─ matchesRegex / \s still in query?
  │     YES → delete content filter; use contains only
  │
  ├─ Step A: host group + fields + limit 5 (no content filter) @ 24h
  │     empty → check ingest / ID
  │     rows → host OK
  │
  ├─ Step B: contains("axacleansingservice") @ 24h
  │
  └─ Step C: host + contains("address, Value =") @ 24h
```
