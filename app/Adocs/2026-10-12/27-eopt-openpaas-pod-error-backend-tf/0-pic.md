# eopt OpenPaaS Pod Error Pic

## Decision tree

```
pods eoptsystemapi-* or eoptprocessapi-* (frontend left out)
 parse "timestamp level" → level == ERROR
 window 1 h → any line → problem per service (medium)
 email only → PagerDuty 0
 parse empty? → check query 2
 want frontend? → check query 4
```

## Data flow

```
backend pods → S3 forwarder → Grail → detector (1 h, ERROR)
  → problem medium per service → workflow → email
```
