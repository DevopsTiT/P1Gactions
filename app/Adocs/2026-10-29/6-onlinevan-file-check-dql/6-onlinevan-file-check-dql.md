# OnlineVAN File Check Query

```
Untitled tile
  what is the list? → 16 expected Windows file paths
  what is looked up? → logs from the last 24 hours whose source contains OnlineVAN
  match? → same source path
  last_seen empty? → status NG, log count 0
  last_seen present? → status OK, date, time, and count
  why 16 records? → one row per expected file, including the silent ones
```

| Key point | Detail |
|---|---|
| Purpose | Check whether each expected OnlineVAN file showed up in the logs. |
| List size | 16 paths. Inbox and outbox under sonpo7, sonpo5, sonpo3, and sonpo15. |
| Log window | Last 24 hours. This run scanned 81.35 GiB. |
| OK | A log line exists for that exact source path. |
| NG | No matching log in that window. |

## Summary

The query starts with a handmade list of files. It joins that list to real logs. A file with no log in the last day is marked NG. A file that was seen is marked OK, with the latest time and the number of lines.

## Investigation

| Source | Finding |
|---|---|
| Tile | Untitled. Data tab, DQL editor. |
| First command | `data` with one `record` per expected path in field `source`. |
| Lookup | `fetch logs, from:now() - 24h`, then `contains(log.source, "OnlineVAN")`, then max timestamp and count by source. |
| Result | 16 records. Executed 10/29/2026 11:28:41. Timeframe is the previous 24 hours. Scanned bytes 81.35 GiB. |
| Photo | The right edge of several lines is cut off. |

## Result

The query has three parts.

### 1. The expected files

`data` plus `record` builds a small table that does not come from Dynatrace storage. Each row is one path, for example:

`D:\OnlineVAN\data\sonpo7\inbox\562006060100.txt`

The doubled backslashes are how a Windows path is written inside the query text. The visible folders are `sonpo7`, `sonpo5`, `sonpo3`, and `sonpo15`, and each path is an `inbox` or an `outbox`. There are 16 records, so there are 16 expected files.

### 2. The lookup into logs

```
fetch logs, from:now() - 24h
| filter contains(log.source, "OnlineVAN")
| summarize last_seen = max(timestamp), log_count = count(), by: {source}
```

| Piece | What it does |
|---|---|
| from:now() - 24h | Read logs from the last day. |
| contains(log.source, "OnlineVAN") | Keep log sources whose path text includes OnlineVAN. |
| max(timestamp) | The newest time that source was seen. |
| count() | How many log lines that source had. |
| lookup | Attach those two numbers to the expected file when the path matches. |

`sourceField: source` is the path on the expected-file row. `lookupField: source` is the path on the log summary. They must be the same string. A different slash, a different drive letter, or different capital letters means no match, and the file stays NG.

This `contains` does not set `caseSensitive:false`. Adding that flag makes `onlinevan` and `OnlineVAN` match the same way.

The 81.35 GiB figure is this log read. The outer list is only 16 files. The inner `fetch logs` still scans the OnlineVAN log volume for 24 hours.

### 3. The status columns

| Column | When a log was found | When no log was found |
|---|---|---|
| status | OK | NG |
| last_date | The date of the newest log line | No log found |
| last_time | The time of that line | - |
| log_count | How many lines | 0 |

`isNull(last_seen)` is the test. No joined timestamp means the file was absent. The final lines keep status, center, business, source, last date, last time, and log count, then sort by center. The right edge of the editor is cut off, so the exact `formatTimestamp` pattern is not fully visible.

## Data flow map

```
16 expected paths
    -> lookup logs from the last 24 hours
    -> path matches?
         yes -> OK, last date, last time, count
         no  -> NG, No log found, count 0
    -> one row per expected file
```

## Related files

| File | What it is |
|---|---|
| 6-onlinevan-file-check-dql-follow.txt | The same explanation, easy to copy. |
| 0-pic.md | The check flow. |
| 1-investigation.md | What was on the screen. |
| 2-result.md | How to read one row. |
| 3-glossary.md | The words in the query. |
| 6.sh | Copy commands. Run them yourself. |
