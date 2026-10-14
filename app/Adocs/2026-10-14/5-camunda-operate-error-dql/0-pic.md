# Camunda Operate Error DQL Pic

## Decision tree

```
operate prefix (host.name or k8s.pod.name) → uppercase ERROR → table
empty? → check query
```

## Data flow

```
operate pods → Grail ? → prefix → ERROR → time, host, pod, line
```
