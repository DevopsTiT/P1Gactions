# Common DQL Picture

## Decision Tree

```
find logs → summarize by source fields
see lines → fields timestamp, content
count     → summarize count()
chart     → makeTimeseries interval:1m
extract   → parse
latest    → sort desc + dedup
join      → lookup
```

## Data Flow

```
fetch → filter → parse / fieldsAdd → summarize | makeTimeseries → sort / limit
```
