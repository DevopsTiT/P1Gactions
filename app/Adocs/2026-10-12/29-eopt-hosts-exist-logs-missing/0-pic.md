# eopt Hosts Exist Logs Missing Pic

## Decision tree

```
15 eopt hosts ✔ → logs 0 ✘
 queries A to E → found? → rewrite detector filter
                → not found → enable log module or S3 forward
                             → keep Splunk alert meanwhile
                             → or trace fallback (query F)
```

## Data flow

```
pods → OneAgent App only → hosts + traces in Dynatrace
pods → stdout → S3 → Splunk only
```
