# PowerCenter Service Down Pic

## Decision tree

```
ISP_MASTER_ELECT_LOCK in last 1 min
 count > 2 → problem medium → email
 host filter? → check query 1
 logs missing? → check query 3
```

## Data flow

```
PowerCenter nodes → lock messages → Grail → detector (1 min, > 2) → problem → workflow → email
```
