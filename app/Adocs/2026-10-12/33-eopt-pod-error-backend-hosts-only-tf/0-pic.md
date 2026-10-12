# eopt Backend Hosts Only Pic

## Decision tree

```
eoptsystemapi-* or eoptprocessapi-* → parse level → ERROR → problem per service
eoptfrontend-* → answer 32
```

## Data flow

```
backend pods → Grail → detector (1 h) → problem medium → workflow → email
```
