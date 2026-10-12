# Powercenter Down Pic

## Decision tree

```
ISP_MASTER_ELECT_LOCK in last 1 min
 count > 3 → problem medium → email
 host filter? → check query 1
 overlap with 35 and 36 → keep one if possible
```

## Data flow

```
PowerCenter nodes → lock messages → Grail → detector (1 min, > 3) → problem → workflow → email
```
