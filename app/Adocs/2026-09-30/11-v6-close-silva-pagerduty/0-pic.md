# CLOSE Pic

```
problem CLOSED ──► 1 prepare-close ──┬──► 2 SILVA
                                     │      ├─ open incident? yes → PATCH Resolved
                                     │      ├─ closed incident? → already_resolved
                                     │      └─ none → not_found
                                     └──► 3 PagerDuty resolve (dedup_key)
```

```
OPEN v6  sets correlation_id = display_id,  dedup_key = dt-problem-<display_id>
CLOSE v6 finds by the same two keys
```
