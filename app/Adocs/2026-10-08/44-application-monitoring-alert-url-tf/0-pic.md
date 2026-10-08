# Application Monitoring URL Pic

```
URL job NG? (non-200 x2, no 200, 15m)
 yes → problem (application + job) → open last_build console
   5xx → app or upstream | 4xx → URL or auth | timeout → network
 no status parsed? → fix "status=" pattern
 < 2 runs per 15m? → widen to 30m
```

```
"[HTTP Monitor]" console lines → name from path → lookup configuration
  → fails >= 2, oks == 0 → problem → 200 closes
```
