# DQL Dedup Pic

```
4 records (2 real failures × 2 syslog paths)
  → dedup timestamp, content
  → 2 records → count 2 → below threshold 3 (correct)
check: lines > distinct_lines → keep dedup; equal → remove it
```
