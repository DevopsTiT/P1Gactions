# Datalake Batch Result Pic

## Decision tree

```
JST 08:00 to 08:04?
 no → nothing
 yes → datalake_transfer.log lines from 3 hosts, last 8 h
   any → problem low per host → email
 want failures only? → check query 3
```

## Data flow

```
02:00 batch → datalake_transfer.log → Grail → detector (JST guard) → problem per host → workflow → email
```
