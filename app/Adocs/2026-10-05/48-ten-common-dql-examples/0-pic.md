# Ten DQL Examples Picture

## Decision Tree

```
logs     → fetch logs (1 to 4)
metrics  → timeseries (5, 6, 8)
traces   → fetch spans (7)
problems → fetch dt.davis.problems (9)
entities → fetch dt.entity.host (10)
```

## Data Flow

```
fetch / timeseries → filter → fieldsAdd → summarize → sort → limit
```
