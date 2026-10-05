# Ten SPL Queries Picture

## Decision Tree

```
lines → table/head | count → stats | chart → timechart
top values → top | number → rex | percent → eval
latest → dedup | enrich → lookup | alert → where
```

## Data Flow

```
index + keywords → rex/eval → stats/timechart → where → sort → head
```
