# Investigation

| What was checked | Finding |
|---|---|
| Your query | Email query without `from:now()-10m` |
| Seq 21 detector query | No `from:`, correct |
| Seq 21 email task | `from:now()-10m` |
| Without `from:` | Default window applies (typically last 2 hours) |
