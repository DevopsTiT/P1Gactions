# BILoss Retrieve Files CMX DQL Pic

## Decision tree

```
lower(host.name) == biloss-retrieve-files-cmx-prod
 → any of 7 phrases (any case) → tag exact case → table
 empty? → check query → swap host filter
```

## Data flow

```
host logs → Grail ? → 7 phrases → tags → JST time → table
```
