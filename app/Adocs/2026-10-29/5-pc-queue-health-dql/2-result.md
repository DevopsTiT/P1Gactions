# Result

The query returns the latest average messaging status for each PolicyCenter queue. This run found 16 queues.

| Piece | Meaning |
|---|---|
| app == "pc" | PolicyCenter only. |
| by queue.id, queue.name | One row per queue. |
| arrayLast | The newest point, not the whole line. |
| 16 records | 16 queues in that two-hour window. |
