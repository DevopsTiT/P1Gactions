# Glossary

| Term | What it means |
|---|---|
| `interval:1m` | Tells the query to build one bucket per minute. Davis scores those buckets. |
| Query offset | How many minutes to look backward so late CPU points are already stored. |
| Violating samples | How many of those one-minute buckets must be below 101. |
| Sliding window | How many one-minute buckets Davis looks at. Five means the last five minutes, after the offset. |
| Problems | The page that shows the opened problem. The Edit alert page does not. |
