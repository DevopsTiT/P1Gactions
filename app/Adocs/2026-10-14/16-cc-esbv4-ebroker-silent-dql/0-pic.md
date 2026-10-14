# CC ESBv4 Ebroker Silent Apps Pic

## Decision tree

```
phrase SPL → prefix + contains
wildcard phrase → split parts
#67 → parse level → ERROR
#72 → lookup on request ID
#76 → last log per app → > 1 hour
```

## Data flow

```
#72: "Sending request" IDs -> lookup -> Interceptor exception lines with same ID
#76: logs -> app -> max(timestamp) -> silent apps
```
