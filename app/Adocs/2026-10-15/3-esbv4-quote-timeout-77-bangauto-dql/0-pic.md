# ESBv4 Quote Timeout 77 Pic

```
Run #77 list query
 rows returned? → bangauto requests timed out at pc quote → check pc-inssuite quote service
 0 rows? → run count version
            requests = 0 → no traffic, or esbv4 logs missing
            timed_out = 0 → healthy
```

```
esbv4 logs
 → timeout lines → request IDs (inner)
 → bangauto _quote lines → request IDs (outer)
 → lookup on ID → matched rows only
```
