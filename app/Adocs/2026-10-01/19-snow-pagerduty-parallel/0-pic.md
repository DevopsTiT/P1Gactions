# Parallel Picture

```
build-payload
 ├→ post-silva-incident  (correlation_id check → POST)
 └→ trigger-pagerduty    (dedup_key → POST)
each: decision false → skip | sample → skip | DRY_RUN → dry_run
```
