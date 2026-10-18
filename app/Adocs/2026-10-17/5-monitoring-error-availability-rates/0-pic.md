# Monitoring Rates Pic

```
Busy?     → request rate
Failing?  → error rate (= errors/total)
Working?  → success / availability (= good/total)
Slow?     → latency p50/p95/p99 (slow may count as bad)
Target?   → SLO → error budget → burn-rate alert
Always read error % together with traffic
```
