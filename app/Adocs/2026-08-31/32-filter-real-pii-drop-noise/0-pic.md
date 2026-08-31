# Pic — real PII vs noise

```
Hits show CleansingResult=0 / counts?
  │
  ├─ YES → those are meaningless records
  │     Require Value = + PII field name
  │     AND not contains CleansingResult
  │
  └─ Still noisy?
        Use stricter query B (must have Value =)
        Or address+phone only query C
```
