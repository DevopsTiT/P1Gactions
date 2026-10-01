# DQL Yes Or No Per Pic2 Item

## Decision Tree

```
Your query (host group HOST_GROUP-551B8509BA489285 + contains one path) works
 │
 ├─ Want all 23 pic2 paths at once, one row each?  → Q1
 │      result YES / NO, code 1 / 0, log_count, real file names
 ├─ Want one single row, one column per path?       → Q2
 │      value = number of matching files (0 = NO)
 └─ Want to prove the method on a path you know?    → Q3 (CalcServer.log → should say YES)
```

## Short Takeaway

| Question | Answer |
|---|---|
| Base | Your query: host group `HOST_GROUP-551B8509BA489285`, `contains(log.source, ..., caseSensitive: false)`, last 7 days |
| How 23 paths are checked together | `coalesce(if(contains(...), "01 path"), if(contains(...), "02 path"), ...)` labels each source with the pic2 item it matches |
| How NO rows appear | `append [data record(item = ...)]` adds all 23 items, so items with zero logs show `NO` |
| Output Q1 | `item`, `result` (YES/NO), `code` (1/0), `log_count`, `sources` |
| Speed | Summarize by `log.source` first, so the 23 checks run on a few hundred rows, not millions of log lines |
| Wildcard items | Text before `*` is used (items 07, 11, 12) |

## Summary

Q1 gives exactly what you asked: one row per pic2 item with YES or NO and a 1/0 code, all in one run. Q2 is the same check as one wide row. Q3 runs your CalcServer.log test in the same style so you can confirm the method returns YES for a file you know exists.

## Q1 — One Row Per Item, YES / NO And Code

```
fetch logs
| filter dt.entity.host_group == "HOST_GROUP-551B8509BA489285"
| summarize log_count = count(), by:{log.source}
| fieldsAdd item = coalesce(
    if(contains(log.source, "/opt/IBM/WebSphere/Profiles/DMGR01/logs/dmgr/SystemOut.log", caseSensitive: false), "01 /opt/IBM/WebSphere/Profiles/DMGR01/logs/dmgr/SystemOut.log"),
    ... items 02 to 22, see the .dql file ...
    if(contains(log.source, "/var/opt/universal/log/unv.log", caseSensitive: false), "23 /var/opt/universal/log/unv.log"))
| filter isNotNull(item)
| summarize log_count = sum(log_count), sources = collectDistinct(log.source), by:{item}
| append [ data record(item = "01 ..."), ..., record(item = "23 ...") ]
| summarize log_count = sum(log_count), sources = arrayFlatten(collectArray(sources)), by:{item}
| fieldsAdd found = isNotNull(log_count) and log_count > 0
| fieldsAdd result = if(found, "YES", else: "NO"), code = if(found, 1, else: 0)
| fields item, result, code, log_count, sources
| sort item asc
```

Full Q1, Q2 and Q3 are in [`5-dql-yes-no-per-pic2-item.dql`](5-dql-yes-no-per-pic2-item.dql).

## How Each Step Works

| Step | What it does |
|---|---|
| `summarize ... by:{log.source}` | One row per log file with its log count |
| `coalesce(if(contains(...), "NN path"), ...)` | Gives the first pic2 item the file matches; null if none |
| `filter isNotNull(item)` | Drops files that are not in pic2 |
| First `summarize by:{item}` | Adds up logs per pic2 item and keeps the real file names |
| `append [data record(...)]` | Adds all 23 items so missing ones still appear |
| Second `summarize by:{item}` | Merges real counts with the checklist rows |
| `result`, `code` | YES and 1 when logs exist, NO and 0 otherwise |

## Common Mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Copying only part of the `coalesce` list | Some items always NO | Paste the full Q1 from the `.dql` file |
| Timeframe shorter than 7 days | Quiet files (HULFT trace, batch logs) show NO | Keep "Last 7 days" like your screenshot |
| Expecting `*` to work in `contains` | Never matches | Already replaced with the text before `*` |
| Reading Q2 numbers as log counts | They are file counts | 0 means NO, 1 or more means YES |

## Data Flow

```
fetch logs (HOST_GROUP-551B8509BA489285, 7 days)
  → summarize by log.source
  → label with pic2 item (coalesce + contains)
  → summarize by item
  → append 23 checklist rows
  → summarize by item → result YES/NO, code 1/0
```

## Related Files

| File | What it is |
|---|---|
| `5-dql-yes-no-per-pic2-item.dql` | Q1, Q2, Q3 |
| `../3-simple-filter-contains-pic2/` | Single yes/no for all items together |
| `5.sh` | Clipboard and mirror one-liners |
