# Investigation

| Source | Finding |
|---|---|
| Tile name | My Axa. |
| Line 1 | `fetch events`. |
| Line 2 | Keeps `event.type == "CUSTOM_INFO"`. |
| Line 3 | Drops events whose `application` field is empty. |
| Line 5 | Keeps only `application == "agj-myaxa"`. |
| Line 7 | Newest event first. |
| Lines 9–15 | Adds `application_status`. `NG` when `contains(jobs, "NG :")` is true. Otherwise `OK`. |
| Lines 17–19 | Output column is `status`. `limit 1` keeps one row. |
| Result line | 0 records. Executed 10/29/2026 11:28:30. Timeframe 09:28:29–11:28:29. Scanned 0.03 GiB. |

The query ran. Zero records means no matching event. The `contains` on the tile has no `caseSensitive:false`.
