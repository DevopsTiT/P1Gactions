# CountIf Many Items Each Result

## Decision Tree

```
Your query works for 1 item (CalcServer.log → countIf → YES/NO)
 │
 ├─ Many items, OK with one wide row?      → A: c01..cNN = countIf(...), r01..rNN = YES/NO
 ├─ Many items, want one row per item?     → B: same countIf, then array(record(...)) → expand → fieldsFlatten
 └─ Same as B but lighter on compute?      → C: summarize by log.source first, then sum(if(...))
Adding an item = add one cNN line (+ one rNN line in A, or one record line in B/C)
```

## Short Takeaway

| Question | Answer |
|---|---|
| Pattern | One `summarize` with one `countIf(contains(...))` per item, named `c01`, `c02`, ... |
| YES / NO | `fieldsAdd rNN = if(cNN > 0, "YES", else: "NO")` |
| One row per item | Put the counts into `array(record(item = ..., log_count = cNN), ...)`, then `expand` and `fieldsFlatten` |
| Result columns (B, C) | `item`, `log_count`, `result` (YES/NO), `code` (1/0) |
| Your last run | 465.66 GiB scanned for 7 days. Many items in one query cost the same scan as one item, so combine them instead of running 23 queries. |

## Summary

You keep your exact pattern and just repeat the `countIf` line for each path. Query A returns one row with a count and a YES/NO per item. Query B (or the lighter C) reshapes those counts into one row per item, which is easier to read and export.

## A — One Row, Many Columns

```
fetch logs
| filter dt.entity.host_group == "HOST_GROUP-551B8509BA489285"
| summarize
    c01 = countIf(contains(log.source, "/opt/app/Calculator/Log/CalcServer.log", caseSensitive: false)),
    c02 = countIf(contains(log.source, "/app/ICM_CPW/log/ap/default.log", caseSensitive: false)),
    c03 = countIf(contains(log.source, "/app/log/ap/default.log", caseSensitive: false))
| fieldsAdd
    r01 = if(c01 > 0, "YES", else: "NO"),
    r02 = if(c02 > 0, "YES", else: "NO"),
    r03 = if(c03 > 0, "YES", else: "NO")
```

Result: `c01 | c02 | c03 | r01 | r02 | r03` → for example `533 | 0 | 0 | YES | NO | NO`.

## B — One Row Per Item

```
fetch logs
| filter dt.entity.host_group == "HOST_GROUP-551B8509BA489285"
| summarize
    c01 = countIf(contains(log.source, "/opt/app/Calculator/Log/CalcServer.log", caseSensitive: false)),
    c02 = countIf(contains(log.source, "/app/ICM_CPW/log/ap/default.log", caseSensitive: false)),
    c03 = countIf(contains(log.source, "/app/log/ap/default.log", caseSensitive: false))
| fieldsAdd items = array(
    record(item = "01 /opt/app/Calculator/Log/CalcServer.log", log_count = c01),
    record(item = "02 /app/ICM_CPW/log/ap/default.log", log_count = c02),
    record(item = "03 /app/log/ap/default.log", log_count = c03))
| fields items
| expand items
| fieldsFlatten items
| fieldsAdd result = if(items.log_count > 0, "YES", else: "NO"), code = if(items.log_count > 0, 1, else: 0)
| fields item = items.item, log_count = items.log_count, result, code
| sort item asc
```

Result:

| item | log_count | result | code |
|---|---|---|---|
| 01 /opt/app/Calculator/Log/CalcServer.log | 533 | YES | 1 |
| 02 /app/ICM_CPW/log/ap/default.log | 0 | NO | 0 |
| 03 /app/log/ap/default.log | 0 | NO | 0 |

The full 11-item versions of A, B and C are in [`8-countif-many-items-each-result.dql`](8-countif-many-items-each-result.dql).

## How B Works

| Step | What it does |
|---|---|
| `summarize c01 = countIf(...)` | One count per item, all in one pass over the logs |
| `array(record(item = ..., log_count = c01), ...)` | Packs each item name with its count into a list |
| `expand items` | Turns the list into one row per item |
| `fieldsFlatten items` | Makes `items.item` and `items.log_count` normal columns |
| `result`, `code` | YES and 1 when the count is above 0 |

## How To Add An Item

| Query | Add |
|---|---|
| A | One `cNN = countIf(...)` line and one `rNN = if(cNN > 0, ...)` line |
| B | One `cNN = countIf(...)` line and one `record(item = "...", log_count = cNN)` line |
| C | One `cNN = sum(if(...))` line and one `record(...)` line |

Watch the commas: every line except the last in each list ends with `,`.

## Common Mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Missing comma between `countIf` lines | Syntax error | Comma after every line except the last |
| Reusing a name like `c02` twice | Error or wrong column | Number each item once |
| Running one query per item | 23 times 465 GiB scanned | Combine items in one query |
| `*` inside the path | Never matches | Use the text before `*` |

## Data Flow

```
fetch logs (host group, 7 days)
  → summarize: c01..cNN = countIf(contains(log.source, item))
     A → fieldsAdd rNN YES/NO            → 1 wide row
     B → array(record) → expand → flatten → 1 row per item (item, log_count, result, code)
```

## Related Files

| File | What it is |
|---|---|
| `8-countif-many-items-each-result.dql` | A, B, C with 11 items |
| `../5-dql-yes-no-per-pic2-item/` | Earlier coalesce + append version with all 23 pic2 items |
| `8.sh` | Clipboard and mirror one-liners |
