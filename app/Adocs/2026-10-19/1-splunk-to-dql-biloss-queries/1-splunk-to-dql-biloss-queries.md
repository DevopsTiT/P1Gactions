# Splunk To DQL BILoss Queries

## Decision tree

```
Splunk → DQL for BILoss log searches?
  Host filter?
    → filter host.name == "…" (or host == "…" if that attribute exists)
  Keyword in log body (_raw)?
    → matchesPhrase(content, "…")
  matched_keywords list?
    → fieldsAdd + arrayRemoveNulls(array(if(…), …))
  Time column?
    → formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z")
  sourcetype=access_*?
    → map to log.source / logattributes in your tenant (confirm field name)
```

## Short takeaway

| Splunk | DQL |
|---|---|
| `_raw` | `content` |
| `host` | `host.name` (fallback: `host` if present) |
| `_time` + `strftime` | `timestamp` + `formatTimestamp` |
| `search "a" OR "b"` | `matchesPhrase(content, "a") or matchesPhrase(content, "b")` |
| `mvappend(if(match…))` | `arrayRemoveNulls(array(if(matchesPhrase…)))` |
| `table …` | `fields …` |

## Summary

Queries 8–10 are the same pattern: filter host(s), filter error phrases, build `matched_keywords`, format time, show columns. Query 11 is a broad error / HTTP status search. Paste the DQL into a Dynatrace Notebook or Logs → Advanced query. Adjust `from:` timeframe and confirm `host.name` vs `host` in your Grail schema.

## Investigation

### Field mapping notes

| Concept | What it means | Why you care |
|---|---|---|
| `content` | Log message body (Splunk `_raw`) | Where keywords are matched |
| `host.name` | Host that produced the log | Common Grail field; if empty, try `host` |
| `timestamp` | Event time | Use for `formatTimestamp` |
| `log.source` | Closest common stand-in for Splunk `sourcetype` | Confirm in your tenant with `| fieldsAdd *` or schema browser |
| `matchesPhrase` | Phrase search in text | Safer than raw regex for these keywords |

If `host.name` returns nothing, change filters to `host == "BILoss-…"`.

---

### Query 8 — DQL

Three processing hosts; CC / Camunda / exception keywords.

```dql
fetch logs, from:now()-24h
| filter host.name == "BILoss-processing-prod"
    or host.name == "BILoss-pre-processing-prod"
    or host.name == "BILoss-link-data-to-cc-prod"
| filter matchesPhrase(content, "CC Error")
    or matchesPhrase(content, "Camunda Error")
    or matchesPhrase(content, "callCamundaProcess error")
    or matchesPhrase(content, "RuntimeException")
    or matchesPhrase(content, "Failed to initialize clients")
    or matchesPhrase(content, "PSQLException")
    or matchesPhrase(content, "IllegalArgumentException")
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(matchesPhrase(content, "CC Error"), "CC Error", null),
    if(matchesPhrase(content, "Camunda Error"), "Camunda Error", null),
    if(matchesPhrase(content, "callCamundaProcess error"), "callCamundaProcess error", null),
    if(matchesPhrase(content, "RuntimeException"), "RuntimeException", null),
    if(matchesPhrase(content, "Failed to initialize clients"), "Failed to initialize clients", null),
    if(matchesPhrase(content, "PSQLException"), "PSQLException", null),
    if(matchesPhrase(content, "IllegalArgumentException"), "IllegalArgumentException", null)
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z")
| fields time, host.name, matched_keywords, content
```

---

### Query 9 — DQL

Upload-to-CMX host; CMX / Runtime / init clients.

```dql
fetch logs, from:now()-24h
| filter host.name == "BILoss-upload-to-cmx-prod"
| filter matchesPhrase(content, "CMX Error")
    or matchesPhrase(content, "RuntimeException")
    or matchesPhrase(content, "Failed to initialize clients")
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(matchesPhrase(content, "CMX Error"), "CMX Error", null),
    if(matchesPhrase(content, "RuntimeException"), "RuntimeException", null),
    if(matchesPhrase(content, "Failed to initialize clients"), "Failed to initialize clients", null)
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z")
| fields time, host.name, matched_keywords, content
```

---

### Query 10 — DQL

Jyusei matching-check host; record id error / Runtime / init clients.

```dql
fetch logs, from:now()-24h
| filter host.name == "BILoss-jyusei-ika-matching-check-prod"
| filter matchesPhrase(content, "Error processing record with id")
    or matchesPhrase(content, "RuntimeException")
    or matchesPhrase(content, "Failed to initialize clients")
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(matchesPhrase(content, "Error processing record with id"), "Error processing record with id", null),
    if(matchesPhrase(content, "RuntimeException"), "RuntimeException", null),
    if(matchesPhrase(content, "Failed to initialize clients"), "Failed to initialize clients", null)
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z")
| fields time, host.name, matched_keywords, content
```

---

### Query 11 — DQL

Broad: `error` / `failed` / `severe`, or access-style logs with 404/500/503.

```dql
fetch logs, from:now()-1h
| filter matchesPhrase(content, "error")
    or matchesPhrase(content, "failed")
    or matchesPhrase(content, "severe")
    or (
      matchesPhrase(log.source, "access")
      and (
        matchesPhrase(content, "404")
        or matchesPhrase(content, "500")
        or matchesPhrase(content, "503")
      )
    )
| fields timestamp, host.name, log.source, content
```

**Note:** Splunk `sourcetype=access_*` does not exist 1:1 in Dynatrace. Confirm the real field (`log.source`, `logattributes[…]`, or a custom attribute) with a small explore query, then tighten the `matchesPhrase(log.source, "access")` filter.

Explore helper:

```dql
fetch logs, from:now()-1h
| filter matchesPhrase(content, "404") or matchesPhrase(content, "500")
| fields log.source, host.name, content
| limit 20
```

---

### If `arrayRemoveNulls` is unavailable in your tenant

Use a string instead of an array:

```dql
| fieldsAdd matched_keywords = concat(
    if(matchesPhrase(content, "RuntimeException"), "RuntimeException; ", ""),
    if(matchesPhrase(content, "Failed to initialize clients"), "Failed to initialize clients; ", "")
  )
```

## Result

| Query | Hosts | Keywords focus |
|---|---|---|
| 8 | processing / pre-processing / link-data-to-cc | CC, Camunda, exceptions |
| 9 | upload-to-cmx | CMX Error + Runtime + init |
| 10 | jyusei-ika-matching-check | Error processing record + Runtime + init |
| 11 | any | error/failed/severe or access-ish 404/500/503 |

## Data flow map

```
Splunk: host + search keywords + mvappend matched_keywords + table
        │
        ▼
DQL:    fetch logs
        → filter host.name
        → filter matchesPhrase(content, …)
        → fieldsAdd matched_keywords (array of hits)
        → fieldsAdd time (formatTimestamp)
        → fields time, host.name, matched_keywords, content
```

## Related files

| File | Purpose |
|---|---|
| `1-splunk-to-dql-biloss-queries.md` | This guide |
| `1-splunk-to-dql-biloss-queries.dql` | All four queries in one file |
| `1.sh` | Git one-liners (not run) |

## Commands

See `1.sh`. None have been run. Paste DQL into Dynatrace UI yourself.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-19/1-splunk-to-dql-biloss-queries
git commit -m "splunk to dql biloss queries 8-11"
git push
```
