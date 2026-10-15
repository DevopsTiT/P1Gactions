# ESBv4 Quote Timeout Count Per Channel

## Decision tree

```
Run the query for one channel (#78, #79, or #80)
 requests = 0 → no quote traffic for that channel in 24h, or esbv4 logs missing → run esbv4 check (answer 1)
 requests > 0, timed_out = 0 → healthy channel
 requests > 0, timed_out > 0 → look at timeout_pct
   small % → occasional slow pc calls
   high % → pc quote API problem for that channel → run the list query (answer 1) for details
```

## Short takeaway

| Query | Channel | Returns |
|---|---|---|
| #78 | inswebauto | One row: requests, timed_out, timeout_pct |
| #79 | inswebbike | One row: requests, timed_out, timeout_pct |
| #80 | kakakucomauto | One row: requests, timed_out, timeout_pct |

## Summary

Check 3 counted all three channels in one table. These three queries do the same count, one channel at a time. Each returns a single row with total quote requests, how many timed out, and the timeout percentage. The only thing that changes is the channel name in the "Sending request" filter and the `channel` label.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| `requests` | Number of "Sending request" lines for the channel in 24 hours. |
| `timed_out` | How many of those requests share an ID with a pc quote timeout. |
| `timeout_pct` | timed_out divided by requests, times 100. |
| `countIf()` | Counts only rows where the condition is true. |
| `lookup` | Joins the timeout IDs onto the request lines. |

### What changed from Check 3

| Check 3 | Per-channel query |
|---|---|
| Matches any channel: `"Sending request to /esb/ebroker/"` and `"/online/_quote"` | Matches one channel: `"Sending request to /esb/ebroker/<channel>/online/_quote"` |
| Builds `channel` with nested `if()` | Sets `channel` as a fixed label after summarize |
| `summarize ... by:{ channel }` | `summarize` with no `by`, so one row |
| No percentage | Adds `timeout_pct` |

## Result

### #78 inswebauto

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Sending request to /esb/ebroker/inswebauto/online/_quote", caseSensitive:false)
| parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
| lookup [
    fetch logs, from:now()-24h
    | fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
    | filter startsWith(src, "esbv4")
    | filter contains(content, "/pc/service/edge/ebroker/quote' failed: Timeout exceeded.", caseSensitive:false)
    | parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
    | filter isNotNull(query)
    | dedup query
    | fields query
  ], sourceField:query, lookupField:query, prefix:"err."
| summarize requests = count(), timed_out = countIf(isNotNull(err.query))
| fieldsAdd channel = "inswebauto",
            timeout_pct = if(requests > 0, round(toDouble(timed_out) / requests * 100, decimals:2), else: 0.0)
| fields channel, requests, timed_out, timeout_pct
```

### #79 inswebbike

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Sending request to /esb/ebroker/inswebbike/online/_quote", caseSensitive:false)
| parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
| lookup [
    fetch logs, from:now()-24h
    | fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
    | filter startsWith(src, "esbv4")
    | filter contains(content, "/pc/service/edge/ebroker/quote' failed: Timeout exceeded.", caseSensitive:false)
    | parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
    | filter isNotNull(query)
    | dedup query
    | fields query
  ], sourceField:query, lookupField:query, prefix:"err."
| summarize requests = count(), timed_out = countIf(isNotNull(err.query))
| fieldsAdd channel = "inswebbike",
            timeout_pct = if(requests > 0, round(toDouble(timed_out) / requests * 100, decimals:2), else: 0.0)
| fields channel, requests, timed_out, timeout_pct
```

### #80 kakakucomauto

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Sending request to /esb/ebroker/kakakucomauto/online/_quote", caseSensitive:false)
| parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
| lookup [
    fetch logs, from:now()-24h
    | fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
    | filter startsWith(src, "esbv4")
    | filter contains(content, "/pc/service/edge/ebroker/quote' failed: Timeout exceeded.", caseSensitive:false)
    | parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
    | filter isNotNull(query)
    | dedup query
    | fields query
  ], sourceField:query, lookupField:query, prefix:"err."
| summarize requests = count(), timed_out = countIf(isNotNull(err.query))
| fieldsAdd channel = "kakakucomauto",
            timeout_pct = if(requests > 0, round(toDouble(timed_out) / requests * 100, decimals:2), else: 0.0)
| fields channel, requests, timed_out, timeout_pct
```

| You see | Meaning |
|---|---|
| `requests` = 0 | No traffic for that channel, or esbv4 logs are missing. |
| `timed_out` = 0 | Healthy. |
| `timeout_pct` high | pc quote API problem for that channel. Use the list query in answer 1. |

## Data flow map

```
channel request lines (with ID)  ─┐
                                  ├─ lookup on ID → count all, count matched → one row
pc quote timeout lines (IDs) ─────┘
```

## Related files

| File | What it holds |
|---|---|
| `2-esbv4-quote-timeout-count-per-channel.dql` | The three count queries |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Changes from Check 3 |
| `2-result.md` | How to read the row |
| `3-glossary.md` | Glossary |
| `2.sh` | Git one-liners |
| Answer 1 (same date) | The list queries for #78 to #80 |

## Commands

See `2.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/2-esbv4-quote-timeout-count-per-channel
git commit -m "esbv4 quote timeout count per channel"
git push
```
