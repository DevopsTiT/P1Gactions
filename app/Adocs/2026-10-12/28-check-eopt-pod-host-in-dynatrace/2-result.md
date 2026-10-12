# Check eopt Pod Host Result

| Result | Action |
|---|---|
| Logs tab shows lines | Log ingest works for this pod. |
| Query 2 returns rows | Answer 27 filter on host.name is correct. |
| Query 2 empty, query 3 rows | Use `entityName(dt.entity.host)` in the detector. |
| Both empty | Fix log ingest first. |
| Query 6 level parsed | Detector ready. |
| `loglevel` already ERROR | Use `filter loglevel == "ERROR"` instead of parse. |
