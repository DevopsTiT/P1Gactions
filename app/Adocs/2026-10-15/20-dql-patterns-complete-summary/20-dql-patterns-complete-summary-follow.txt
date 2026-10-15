# DQL Patterns — Complete Summary
## Text Search + Parse + Aggregate + Freshness + Lookup Join + JSON + Metrics + Lookup File

---

## 2. End-to-End Query Flow

```
Splunk query (#1 to #85)
  │
  ├─── time ─────────────► fetch logs, from:now()-24h
  │
  ├─── where ────────────► fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
  │                         filter startsWith(src, "app")   or  in(host.name, array(...))
  │
  ├─── text ─────────────► filter contains(..., caseSensitive:false) / matchesPhrase / not
  │
  ├─── extract ──────────► parse (DPL)  |  replaceString + parse "JSON:j"  |  substring
  │
  ├─── join (optional) ──► lookup [ inner query ], sourceField:, lookupField:, prefix:
  │
  ├─── shape (optional) ─► summarize  |  makeTimeseries  |  max(timestamp)
  │
  └─── output ───────────► sort timestamp desc  →  fields ...
         (0 rows? run only time + where lines: 0 = not onboarded or wrong field)
```

---

## 3. The Patterns

### 3a. Pattern Overview

| Pattern | Name | Main queries | Core DQL commands |
|---|---|---|---|
| P1 | Text search on one app | #2, #4 to #9, #11 to #13, #15, #16, #19, #29 to #31, #33 to #49, #51, #52, #54 to #59, #63, #64, #66 to #71, #73 to #75 | `filter`, `contains`, `matchesPhrase` |
| P2 | Keyword tagging | #1 | `arrayRemoveNulls`, `array`, `if` |
| P3 | Parse a value, then filter or compute | #22, #50, #60, #61, #65, #67 | `parse`, `substring`, `toLong` |
| P4 | Multi-line split | #62 | `splitString`, `expand`, `collectArray` |
| P5 | Count and group | #3, #17, #32, #41, #47, #53 (chart) | `summarize`, `count`, `makeTimeseries` |
| P6 | Freshness (who went quiet) | #18, #76 | `summarize max(timestamp)` |
| P7 | Subsearch as lookup join | #72, #77 to #80 | `lookup [ ]`, `isNotNull` |
| P8 | Escaped JSON (portals-amp) | #20, #23 to #28, #82 to #85 | `replaceString`, `parse "JSON:j"`, `j[a][b]` |
| P9 | Metrics | #21 | `timeseries` |
| P10 | Lookup file and date math | #81 | `load`, `timestampFromUnixSeconds` |
| P11 | Platform usage | #14 | Ingest volume summary |
| (none) | Not shown | #10 | No DQL yet |

### 3b. P1 — Text Search On One App

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2-ui")
| filter contains(content, "phrase", caseSensitive:false)
| filter not matchesPhrase(content, "noise")
| sort timestamp desc
| fields timestamp, src, content
```

| Choice | Use when | Example |
|---|---|---|
| `startsWith(src, "x")` | Splunk `index=x` or `host="x*"` | #42 `bc2` apps |
| `in(host.name, array("a", "b"))` | Splunk lists exact hosts | #1, #8 |
| `lower(host.name) == "x"` | Splunk names one exact host | #7 |
| `contains(..., caseSensitive:false)` | Splunk quoted phrase | #2, #74 |
| `contains(...)` with no option | Splunk `CASE()`, `match` or `regex` | #13 `FAIL` |
| `matchesPhrase(...)` | Splunk bare word | #57 `ready` |
| `not ...` | Splunk `NOT` | #50 |

### 3c. P2 — Keyword Tagging

```
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(contains(content, "RuntimeException"), "RuntimeException"),
    if(contains(content, "PSQLException"), "PSQLException")
  ))
```

| Piece | What it does |
|---|---|
| `if(condition, "Name")` | Returns the name when found, otherwise null. |
| `array(...)` | Collects one result per keyword. |
| `arrayRemoveNulls` | Keeps only the names that were found. |

### 3d. P3 — Parse A Value

```
| parse content, "LD 'errcode=' ALNUM:errcode"
| filter errcode == "E01"
```

| Query | Parse or compute | Job |
|---|---|---|
| #50 | `LD 'errcode=' ALNUM:errcode` | Replaces Splunk's auto field `errcode=E01`. |
| #61 | Timestamp layout then `WORD:loglevel` | Reads the log level from a fixed position. |
| #60 | Duration number | Feeds `avg` and `max`. |
| #22 | Expiry date text | Compared with `now()` to find licences expiring soon. |
| #65 | `substring(message, from:400, to:417)` | Replaces Splunk `substr(x, 401, 17)`. DQL counts from 0. |
| #67 | `INT` date parts | Checks the date layout before the level. |

DPL quick map: `.*?` becomes `LD`, `\d+` becomes `DIGIT+` or `INT`, `\w+` becomes `ALNUM` or `WORD`, `\s+` becomes `SPACE+`, literal text goes in single quotes.

### 3e. P4 — Multi-Line Split

```
| fieldsAdd lines = splitString(content, "\n")
| expand lines
| parse lines, "<pattern>"
| summarize details = collectArray(lines), by:{timestamp, src}
```

| Step | What it does |
|---|---|
| `splitString` | Turns one multi-line entry into a list of lines. |
| `expand` | One row per line. |
| `parse` or `filter` | Keeps the lines you want. |
| `collectArray` | Puts the kept lines back together per entry. Replaces Splunk `rex max_match=0`. |

### 3f. P5 — Count And Group

```
| summarize count = count(), by:{src}
| sort count desc
| limit 5
```

| Query | Shape | Splunk |
|---|---|---|
| #17 | Count per source, top 5 | `stats count by host \| sort - count \| head 5` |
| #32 | Count per app | `stats count by index` |
| #3, #41, #47 | Count per ID, keep `count > 1` | `stats count by id \| where count > 1` |
| #20 | `countDistinctExact(account)` per day | `stats dc(account)` |
| #53 extra | `makeTimeseries count(), interval:1h, by:{app}` | `timechart span=1h count by app` |

### 3g. P6 — Freshness

```
fetch logs, from:now()-7d
| summarize last_seen = max(timestamp), by:{host.name}
| filter last_seen < now() - 2h
| sort last_seen asc
```

| Piece | What it does |
|---|---|
| `max(timestamp)` | Newest log time per host. Replaces Splunk `metadata`. |
| `filter last_seen < now() - 2h` | Keeps hosts silent for longer than the limit. |

### 3h. P7 — Subsearch As Lookup Join

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Sending request to /esb/ebroker/<channel>/online/_quote", caseSensitive:false)
| parse content, "LD (<UUID pattern>):query"
| lookup [
    fetch logs, from:now()-24h
    | fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
    | filter startsWith(src, "esbv4")
    | filter contains(content, "<timeout phrase>", caseSensitive:false)
    | parse content, "LD (<UUID pattern>):query"
    | filter isNotNull(query)
    | dedup query
    | fields query
  ], sourceField:query, lookupField:query, prefix:"err."
| filter isNotNull(err.query)
```

| Piece | Why |
|---|---|
| Parse the ID on both sides | DQL cannot paste subsearch text like Splunk `format`. |
| `dedup query` | One inner row per ID, so the join does not multiply rows. |
| `prefix:"err."` | The joined field arrives as `err.query`, separate from the outer one. |
| `filter isNotNull(err.query)` | Same as Splunk's AND with the subsearch. |
| Only the channel changes in #77 to #80 | bangauto, inswebauto, inswebbike, kakakucomauto. |

### 3i. P8 — Escaped JSON (portals-amp)

```
| filter contains(k8s.container.name, "portals-amp") or contains(k8s.pod.name, "portals-amp") or contains(log.source, "portals-amp")
| fieldsAdd raw = replaceString(content, "\\\"", "\"")
| parse raw, "JSON:j"
| fieldsAdd msg_url = toString(j[message][url]), msg_type = toString(j[message][type])
| filter contains(msg_url, "payWithCreditCard_Adj")
| filter msg_type == "EXECUTION_COMPLETED"
```

| Piece | Why |
|---|---|
| `replaceString` | Turns `\"` into `"` so the text is valid JSON. |
| `parse raw, "JSON:j"` | Replaces Splunk `spath`. |
| `contains(msg_url, ...)` | The URL field holds the full address, so `==` never matches. |
| `endsWith(msg_url, "/quote")` (#82) | Short names would match too much with `contains`. |
| Current state | These return 0 rows: portals-amp logs go to Splunk only. |

### 3j. P9, P10, P11 — Metrics, Lookup File, Platform

| Pattern | Skeleton | Note |
|---|---|---|
| P9 metrics (#21) | `timeseries { usage = avg(dt.kubernetes.container.cpu_usage), cpu_limit = avg(dt.kubernetes.container.limits_cpu) }, by:{k8s.pod.name}` then `fieldsAdd pct = usage[] / cpu_limit[] * 100` | Reads metrics, not logs. |
| P10 lookup file (#81) | `load "/lookups/sslcert_lookup"` then `fieldsAdd ssl_end = timestampFromUnixSeconds(toLong(ssl_end_time))` then `filter ssl_end < now() + 30d` | A Synthetic HTTP monitor is the better long-term fix. |
| P11 platform (#14) | Sum of ingested log size per day | Splunk licence index has no Dynatrace twin. |

---

## 9. Common Issues and Solutions

### Source Filter Issues

| Symptom | Root Cause | Solution |
|---|---|---|
| 0 rows even with only time and source lines | Logs are not in Dynatrace | Onboard the app (portals-amp needs adding to the log forwarder). |
| 0 rows for one app only | The name lives in a different field | Run a check query over `host.name`, `k8s.pod.name` and `log.source`. |
| Wrong app included | Prefix too short | Make the `startsWith` prefix longer. |

### Text Filter Issues

| Symptom | Root Cause | Solution |
|---|---|---|
| Misses lines Splunk finds | `contains` is case-sensitive | Add `caseSensitive:false` or use `matchesPhrase`. |
| 0 rows after copying a Splunk wildcard | Stars kept inside `contains` | Remove the stars. |
| `matchesPhrase` misses a word | The word is glued inside a longer token | Use `contains` instead. |

### Parse Issues

| Symptom | Root Cause | Solution |
|---|---|---|
| Field is always null | Pattern does not fit the real text | Test the pattern with `data record(...)` first. |
| Value longer than expected | `ALNUM` and `LD` are greedy | Add the next literal character after the capture. |
| Substring off by one | Splunk counts from 1, DQL from 0 | Start one lower. |

### Join Issues

| Symptom | Root Cause | Solution |
|---|---|---|
| No joined rows | The ID pattern differs between the two lines | Parse both sides with the same pattern. |
| Duplicate rows | The inner query returns one ID many times | Add `dedup query`. |

### JSON Issues

| Symptom | Root Cause | Solution |
|---|---|---|
| JSON parse gives nothing | Escaped quotes still in the text | Add the `replaceString` step. |
| URL filter returns 0 | `==` on a full URL | Use `contains` or `endsWith`. |

---

## 10. Command Responsibility Matrix

| Job | Command | Splunk twin | Patterns |
|---|---|---|---|
| Read data | `fetch logs` | Time picker and `index` | All log patterns |
| Read metrics | `timeseries` | `mstats` | P9 |
| Read a lookup file | `load` | `inputlookup` | P10 |
| Make test data | `data record(...)` | `makeresults` | Testing |
| Pick the app | `filter startsWith / in / ==` | `index`, `host`, `sourcetype` | P1 to P8 |
| Match text | `contains`, `matchesPhrase` | Search terms | P1 to P8 |
| Extract | `parse`, `substring`, `replaceString` | `rex`, `spath`, `eval` | P3, P4, P7, P8 |
| Add a column | `fieldsAdd` | `eval` | P2, P3, P8, P10 |
| Group | `summarize` | `stats` | P5, P6 |
| Chart | `makeTimeseries` | `timechart` | P5 |
| Join | `lookup` | Subsearch and `lookup` | P7 |
| Order and show | `sort`, `fields`, `limit`, `dedup` | `sort`, `table`, `head`, `dedup` | All |

---

## Related Files

| File | Purpose |
|---|---|
| `20-dql-patterns-complete-summary.md` | This summary |
| `20-dql-patterns-complete-summary-skeletons.dql` | Skeleton for each pattern, ready to copy |
| `0-pic.md` | Pattern picker |
| `1-investigation.md` | Which query belongs to which pattern |
| `2-result.md` | How to use the patterns |
| `3-glossary.md` | Terms |
| `20.sh` | Git one-liners (not run) |
| 2026-10-15 answers 16 to 19 | DQL line by line, match examples, dummy data, SPL to DQL logic |

## Commands

See `20.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/20-dql-patterns-complete-summary
git commit -m "dql patterns complete summary"
git push
```
