# BILoss CMX Error DQL Pic

## Decision tree

```
lower(host.name) == biloss-retrieve-files-cmx-prod → exact "CMX Error" → table
empty? → check query
```

## Data flow

```
host logs → Grail ? → "CMX Error" → time, host, line
```
