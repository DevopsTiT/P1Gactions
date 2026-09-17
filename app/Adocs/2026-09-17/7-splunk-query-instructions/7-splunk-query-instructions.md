# Splunk Query Instructions

```
Want to query in Splunk?
  │
  ├─ 1 Open Search & Reporting
  ├─ 2 Set time range (Last 15 minutes / 60 minutes)
  ├─ 3 Write SPL: index=... | filter-like terms | stats/table
  ├─ 4 Run (magnifying glass / Enter)
  └─ 5 Save as report/alert/dashboard if useful
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What a Splunk query is | A search in **SPL** (Search Processing Language) |
| Where to run it | **Search & Reporting** app (main search bar) |
| Basic shape | `index=... sourcetype=... keyword` then `| stats` / `| table` / `| timechart` |
| Time range | Set with the time picker — as important as the search text |

## Summary

Splunk stores machine data in **indexes**. You ask questions with **SPL** in the Search bar. Start narrow (index + time), add keywords/fields, then pipe (`|`) commands to count, table, or chart. Below: UI steps, syntax, starters, and how this compares to Dynatrace DQL.

---

## Investigation

UI-focused Splunk search how-to for beginners. Not Dynatrace DQL (see `../6-dynatrace-query-instructions/`), but the investigation habit is similar: time range → narrow → aggregate → save.

## Result

Follow Parts 1–7. Practice with Last 15 minutes and a known `index` / `sourcetype` from your team.

---

## 1) What a Splunk query is (plain English)

A **query** (search) asks Splunk: “Show me matching events, then summarize them.”

| Term | What it means |
| --- | --- |
| SPL | Search Processing Language (Splunk’s query language) |
| Event | One log line / record Splunk indexed |
| Index | “Bucket” / database of related data (e.g. `main`, `aws`, `app`) |
| Sourcetype | Format/family of data (e.g. `aws:cloudwatchlogs`, `syslog`) |
| Field | Extracted key=value (e.g. `status=500`, `host=web01`) |
| Pipe `\|` | Send results to the next command |

Analogy: index = filing cabinet, sourcetype = folder style, keywords = what you look for, `| stats` = count the matches.

---

## 2) Where to run queries (UI)

| Place | What it is for |
| --- | --- |
| **Search & Reporting** | Main place to type SPL and run |
| **Dashboards** | Saved charts/tables that run searches |
| **Reports** | Saved searches you reopen |
| **Alerts** | Saved search that notifies when condition matches |
| **Pivot** (optional) | Clicky UI over datasets (less raw SPL) |

**Beginner path:** Search & Reporting only.

---

## 3) How to query in the UI (step by step)

1. Log in to Splunk.  
2. Open app **Search & Reporting**.  
3. Find the big **search bar** at the top.  
4. Set the **time picker** (right side): start with **Last 15 minutes**.  
5. Type SPL (examples below).  
6. Press **Enter** or click the search icon.  
7. Read results:
   - **Events** tab = raw matching lines  
   - **Patterns** / fields sidebar = interesting fields  
   - **Statistics** = after `| stats` / `| table`  
   - **Visualization** = charts after `| timechart` etc.  
8. Click a field in the left **Fields** panel to filter faster (`status=500`).  
9. If useful: **Save As** → Report / Dashboard Panel / Alert.

### Good habit loop

```
Wide search (index + time)
  → click one event → learn field names
  → add field filters
  → add | stats or | table
  → Save As report
```

---

## 4) SPL syntax (core)

### Shape

```spl
index=<name> sourcetype=<name> <keywords> <field>=<value>
| <command> ...
| <command> ...
```

### Search terms (before the first pipe)

| Piece | Example | Meaning |
| --- | --- | --- |
| Index | `index=aws` | Which data store |
| Sourcetype | `sourcetype=aws:cloudwatchlogs` | Data format |
| Keyword | `"UPLOAD_FAILED"` | Free text match |
| Field equals | `status=500` | Exact field match |
| AND / OR / NOT | `ERROR OR WARN` | Boolean logic |
| Wildcards | `host=web*` | Prefix match |
| Quotes | `"connection refused"` | Phrase |

**Always prefer an index** (and sourcetype when you know it). Searching without `index=` can be slow or restricted.

### Common pipe commands

| Command | What it does | Example |
| --- | --- | --- |
| `table` | Show columns | `\| table _time, host, status` |
| `fields` | Keep/remove fields | `\| fields - _raw` |
| `stats` | Count/sum/avg/group | `\| stats count by host` |
| `timechart` | Values over time | `\| timechart count` |
| `top` | Most common values | `\| top status` |
| `rare` | Least common values | `\| rare user` |
| `sort` | Order rows | `\| sort - count` |
| `head` / `tail` | First/last N | `\| head 100` |
| `where` | Filter after eval | `\| where count > 10` |
| `eval` | Create/calc fields | `\| eval env=upper(env)` |
| `rex` | Extract with regex | `\| rex field=_raw "action:(?<action>\\w+)"` |
| `spath` / `xpath` | JSON/XML extract | for structured logs |
| `dedup` | Unique by field | `\| dedup host` |
| `transaction` | Group related events | advanced |
| `join` / `append` | Combine searches | advanced / costly |

### Important default fields

| Field | Meaning |
| --- | --- |
| `_time` | Event timestamp |
| `_raw` | Original text |
| `host` | Host that sent data |
| `source` | File/path/stream |
| `sourcetype` | Type/format |
| `index` | Index name |

---

## 5) Starter queries (copy-paste)

Replace `index=...` / `sourcetype=...` with your real names (ask your team if unsure).

### 1) Smoke test — recent events in an index

```spl
index=main
| head 100
```

### 2) Keyword search

```spl
index=main "ERROR"
| head 100
```

### 3) Filter by host + keyword

```spl
index=main host=web01 "timeout"
| table _time, host, source, _raw
| sort - _time
```

### 4) Count errors by host

```spl
index=main (ERROR OR status=500)
| stats count as errors by host
| sort - errors
```

### 5) Timechart — errors over time

```spl
index=main ERROR
| timechart span=5m count as errors
```

### 6) Top status codes

```spl
index=web sourcetype=access_combined
| top status
```

### 7) Extract a field with rex (action example)

```spl
index=aws "action:" "cmxDocumentId:"
| rex field=_raw "action:(?<action>\w+)"
| rex field=_raw "cmxDocumentId:(?<cmxDocumentId>\w+)"
| table _time, action, cmxDocumentId
| head 100
```

### 8) Stats count by action

```spl
index=aws "action:"
| rex field=_raw "action:(?<action>\w+)"
| stats count as cnt by action
| sort - cnt
```

### 9) Failed uploads style (after fields exist)

```spl
index=aws sourcetype=aws:cloudwatchlogs "UPLOAD_FAILED"
| rex field=_raw "cmxDocumentId:(?<cmxDocumentId>\w+)"
| stats count as failed by cmxDocumentId
| where failed > 0
| sort - failed
| head 100
```

### 10) Compare to Dynatrace DQL habit

| Goal | Splunk (SPL) | Dynatrace (DQL) |
| --- | --- | --- |
| Latest rows | `index=... \| head 100` | `fetch logs \| limit 100` |
| Filter text | `"UPLOAD_FAILED"` | `filter contains(content, "UPLOAD_FAILED")` |
| Aggregate | `\| stats count by host` | `\| stats count() by host.name` |
| Time | UI time picker | UI time range |
| Extract | `rex` / props/transforms | `parse` |

Same investigation idea; different language and UI.

---

## 6) How to manage searches

| Goal | How in UI |
| --- | --- |
| Reuse tomorrow | **Save As → Report** |
| Share with team | Permissions on report/dashboard |
| Always visible | **Save As → Dashboard Panel** |
| Alert | **Save As → Alert** (condition: number of results, etc.) |
| Schedule | Report/alert schedule (cron-like) |

### Alert idea (concept)

1. Prove the search returns the bad events you care about.  
2. Save As → Alert.  
3. Trigger when results > 0 (or threshold).  
4. Action: email, Slack webhook, PagerDuty, script (per your org).  

---

## 7) Common mistakes

| Mistake | Fix |
| --- | --- |
| No time range / All time | Use Last 15–60 minutes first |
| No `index=` | Always set index (faster, often required) |
| Leading wildcard `*error` | Can be very slow; avoid if possible |
| Heavy `join` on huge data | Prefer `stats` + keys; ask for help |
| Wrong sourcetype | Click an event; copy real sourcetype |
| Empty results | Widen time; check index access; confirm keyword |
| Confusing Events vs Statistics | Need `| stats` / `| table` for Statistics tab |

### Permissions note

If `index=secret` returns nothing, you may lack **index access**. Ask a Splunk admin — it is not always a bad query.

---

## 8) Mini cheatsheet

```
index=<idx> sourcetype=<st> <keywords> field=value
| rex field=_raw "pattern(?<field>\w+)"
| stats count by field
| sort - count
| head 100
```

Boolean:

```
index=main (ERROR OR FATAL) NOT DEBUG
```

Time in search (optional; UI picker is usually enough):

```
index=main earliest=-15m latest=now ERROR
```

---

## Data flow map

```
You (Search & Reporting)
  → set time picker
  → SPL: index/sourcetype/keywords/fields
  → Run
  → Events / Statistics / Visualization
  → Save As report / dashboard / alert
```

## Related files

| Path | Why |
| --- | --- |
| `../6-dynatrace-query-instructions/` | Same idea in Dynatrace DQL |
| `../2-dynatrace-dql-syntax-top10/` | DQL examples for comparison |
| `7.sh` | Paths |

## Commands

See `7.sh` in this folder.
