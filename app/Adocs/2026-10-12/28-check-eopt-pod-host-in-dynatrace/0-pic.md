# Check eopt Pod Host Pic

## Decision tree

```
host page → Logs tab → lines?
 no → fix log ingest
 yes → Notebook
   query 2 rows? → keep host.name filter
   query 2 empty, query 3 rows? → use entityName(dt.entity.host)
   query 6 level ok? → detector ready
   loglevel filled? → use loglevel instead of parse
```

## Data flow

```
pod → OneAgent (App only) → host entity = pod name
  → logs with host.name → Notebook checks → detector
```
