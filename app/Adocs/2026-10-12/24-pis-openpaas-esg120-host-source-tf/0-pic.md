# PIS OpenPaaS ESG120 Pic

## Decision tree

```
host CEAA20B8 + source pisp2.log + "errorCode" + "ESG120"
 window → 5 min
 any line → problem medium
 email only → PagerDuty 0
 host unclear? → check query 1
 no rows? → check query 3 (line split)
```

## Data flow

```
PIS batch → ESG120 Routing failed → pisp2.log
  → Grail → detector (5 min) → problem medium → workflow → email
```
