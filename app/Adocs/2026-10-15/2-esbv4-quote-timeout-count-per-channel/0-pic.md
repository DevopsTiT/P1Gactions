# ESBv4 Quote Timeout Count Per Channel Pic

## Decision tree

```
requests = 0 → no traffic or esbv4 missing
timed_out = 0 → healthy
timeout_pct high → pc quote problem → list query
```

## Data flow

```
channel requests + timeout IDs -> lookup -> requests, timed_out, timeout_pct
```
