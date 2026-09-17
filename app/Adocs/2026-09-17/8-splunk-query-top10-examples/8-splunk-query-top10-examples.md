# Splunk Query Top10 Examples

```
Need Splunk practice searches?
  → Open Search & Reporting
  → Time: Last 15 minutes
  → Paste one example below (fix index=)
  → Run → tighten fields → Save As report
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Language | SPL (Search Processing Language) |
| Always set | Time picker + `index=` |
| These 10 | Smoke → filter → stats → timechart → rex → alert-style |

## Summary

Ten copy-paste Splunk searches from simple to useful. Replace `index=main` / `index=aws` with your real indexes. Set time to **Last 15 minutes** first.

---

## Investigation

Follow-up to `../7-splunk-query-instructions/`. Examples only; UI how-to stays in seq 7.

## Result

Use examples 1–10 below. Same content in `8-splunk-query-top10-examples.spl`.

---

## Top 10 Splunk examples

### 1) Latest events (smoke test)

```spl
index=main
| head 100
```

**Why:** Prove search works and you can see data.

---

### 2) Keyword search — ERROR

```spl
index=main "ERROR"
| sort - _time
| head 100
```

**Why:** Fast free-text hunt in raw logs.

---

### 3) Filter by host + keyword

```spl
index=main host=web01 ("timeout" OR "timed out")
| table _time, host, source, _raw
| sort - _time
```

**Why:** Narrow to one host and show readable columns.

---

### 4) Count by host

```spl
index=main (ERROR OR FATAL OR status=500)
| stats count as errors by host
| sort - errors
```

**Why:** Which hosts are noisiest right now.

---

### 5) Timechart — volume over time

```spl
index=main ERROR
| timechart span=5m count as errors
```

**Why:** See spikes; use Visualization tab.

---

### 6) Top status codes (web)

```spl
index=web sourcetype=access_combined
| top limit=10 status
```

**Why:** Quick view of HTTP status distribution. Change sourcetype if yours differs.

---

### 7) Eval + where — only high counts

```spl
index=main ERROR
| stats count as errors by host
| where errors > 10
| sort - errors
```

**Why:** Hide low noise; keep hot hosts.

---

### 8) Rex extract — action field

```spl
index=aws "action:"
| rex field=_raw "action:(?<action>\w+)"
| table _time, action, _raw
| head 100
```

**Why:** Pull a field from free text when it is not already extracted.

---

### 9) Stats by action + document id (upload-style)

```spl
index=aws sourcetype=aws:cloudwatchlogs ("action:" AND "cmxDocumentId:")
| rex field=_raw "action:(?<action>\w+)"
| rex field=_raw "cmxDocumentId:(?<cmxDocumentId>\w+)"
| stats count as cnt by action, cmxDocumentId
| sort - cnt
| head 100
```

**Why:** Same investigation pattern as your Dynatrace CDUS upload queries.

---

### 10) Failed uploads aggregate (alert-style)

```spl
index=aws sourcetype=aws:cloudwatchlogs "UPLOAD_FAILED"
| rex field=_raw "cmxDocumentId:(?<cmxDocumentId>\w+)"
| stats count as failed by cmxDocumentId
| where failed > 0
| sort - failed
| head 100
```

**Why:** List document ids with failures — good candidate for **Save As → Alert** when results > 0.

---

## Mini cheatsheet

```
index=<idx> sourcetype=<st> <keywords> field=value
| rex field=_raw "pat(?<field>\w+)"
| stats count by field
| where count > 0
| sort - count
| head 100
```

## Common swaps

| If empty results | Try |
| --- | --- |
| Wrong index | Ask team for real index name |
| Wrong sourcetype | Open one event → copy sourcetype |
| No `action:` in aws | Broader: `index=aws | head 20` first |
| No host field | Use `source` or site-specific field |

## Data flow map

```
Time picker
  → index/sourcetype/keywords
  → optional rex
  → stats / timechart / table
  → Statistics or Visualization
  → Save As report/alert
```

## Related files

| Path | Why |
| --- | --- |
| `8-splunk-query-top10-examples.spl` | All 10 in one file |
| `../7-splunk-query-instructions/` | How to run in UI |
| `../6-dynatrace-query-instructions/` | Dynatrace DQL twin habit |
| `8.sh` | Paths |

## Commands

See `8.sh` in this folder.
