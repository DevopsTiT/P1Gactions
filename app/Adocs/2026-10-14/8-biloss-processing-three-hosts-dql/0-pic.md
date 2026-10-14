# BILoss Processing Three Hosts DQL Pic

## Decision tree

```
in(lower(host.name), 3 BILoss hosts)
 → any of 7 phrases (any case) → tag exact case → table
 empty? → check query → swap host filter
```

## Data flow

```
3 hosts → Grail ? → 7 phrases → tags → JST time → table
```
