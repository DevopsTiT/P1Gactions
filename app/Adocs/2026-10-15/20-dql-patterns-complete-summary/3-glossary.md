# DQL Patterns Glossary

| Term | What it means |
|---|---|
| Pattern | A repeated query shape used by several of the 85 queries. |
| Skeleton | A pattern with placeholders to fill in. |
| `src` | Helper field: pod name, or host name when there is no pod. |
| `summarize` | Group rows and calculate counts, sums or lists. |
| `makeTimeseries` | Count per time bucket for a chart. |
| `max(timestamp)` | The newest log time, used to find silent hosts. |
| `lookup` | Join rows from a second query on a shared field. |
| `expand` | Turn a list into one row per item. |
| `timeseries` | Read metric values over time. |
| `load` | Read an uploaded lookup table. |
| Escaped JSON | JSON stored with `\"`, fixed with `replaceString`. |
