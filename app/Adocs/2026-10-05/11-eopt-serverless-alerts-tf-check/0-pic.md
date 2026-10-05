# EOPT Serverless Alerts Check Pic

```
eopt-serverless.tf (2 x dynatrace_log_alert → plan fails)
  parse "LD '-' x4 LD SPACE WORD:level"
    Node default line → works
    Python / JSON      → fails silently → check loglevel first
  ALERT 1 (*/5)    → detector window 5 → problem → email workflow lists last 10 min ERROR lines
  ALERT 2 (daily)  → scheduled workflow 10:00 JST → count + latest 100 → email if > 0
```
