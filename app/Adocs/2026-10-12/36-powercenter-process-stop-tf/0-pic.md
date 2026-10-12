# PowerCenter Process Stop Pic

## Decision tree

```
ISP_MASTER_ELECT_LOCK in last 15 min
 any line → problem high per host → email
 host filter? → check query 1
 noisy? → check query 2
```

## Data flow

```
PowerCenter node → lock message → Grail → detector (15 min, any) → problem per host → workflow → email
```
