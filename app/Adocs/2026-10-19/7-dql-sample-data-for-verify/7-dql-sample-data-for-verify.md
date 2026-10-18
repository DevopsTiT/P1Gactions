# DQL Sample Data For Verify

## Decision tree

```
Need to verify DQL before / without prod logs?
  Logic only (filters, parse, math)?
    → Method A: Notebook `data record(...)` synthetic rows
  Need lookup table (sslcert)?
    → Method B: upload CSV lookup → `load "/lookups/..."`
  Need real Grail logs like prod?
    → Method C: ingest sample logs (API / OpenPipeline / test pod)
  Which query family?
    81 ssl lookup → B (+ A for time math)
    82–84 portals-amp JSON → A first, then C
    Earlier BILoss / esbv4 / host filters → A or C
```

## Short takeaway

| Method | What it is | Best for |
|---|---|---|
| A — `data record` | Fake rows inside the Notebook | Fast unit-test of DQL logic |
| B — Lookup CSV | Table file Dynatrace can `load` | Query 81 sslcert |
| C — Ingest logs | Push real-shaped logs into Grail | End-to-end with `fetch logs` |

## Summary

You do not need production traffic to verify DQL. Start with **Method A** (synthetic `data` records) to prove filters and JSON parse. Add a **lookup CSV** for SSL cert queries. Only then ingest a few **sample logs** if you must test `fetch logs` field names in your tenant.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Grail | Dynatrace data lake for logs/metrics/events | Where `fetch logs` reads |
| `data record` | DQL command that invents rows in a query | Verify without ingest |
| Lookup | Small reference table (like Splunk lookup) | Query 81 `sslcert_lookup` |
| `content` | Log body field | Holds JSON string for portals queries |
| Verify | Run DQL and see expected rows | Before you trust migration |

---

## Method A — Synthetic rows in a Notebook (start here)

### What this is

Dynatrace Notebooks can run DQL that **creates** sample rows with `data`, then pipes them through the same filters as your real query. Swap `fetch logs` for `data …` while testing.

### Pattern

```dql
data record(
    timestamp: now(),
    content: "{\"level\":\"error\",\"message\":{\"url\":\"save\",\"type\":\"X\"}}",
    log.source: "portals-amp-backend",
    k8s.container.name: "portals-amp-backend",
    host.name: "demo-host"
  ),
  record(
    timestamp: now(),
    content: "{\"level\":\"info\",\"message\":{\"url\":\"other\",\"type\":\"Y\"}}",
    log.source: "other-app",
    host.name: "demo-host"
  )
| filter contains(log.source, "portals-amp-backend")
| fields timestamp, log.source, content
```

**Expected:** only the first record survives.

If your tenant uses slightly different `data` syntax, use the Notebook **Insert → Data** helper or docs for `data` / `record` — the idea is the same: invent rows, then reuse your `| filter` / `| parse` chain.

---

## Method B — Lookup sample data (query 81)

### What this is

Query 81 does `load "/lookups/sslcert_lookup"`. That needs a **lookup table** with at least `dest` and `ssl_end_time` (unix seconds as string/number).

### Sample CSV (`sslcert_lookup.csv`)

```csv
dest,ssl_end_time
ebroker-inssuite-prod.op-prod-lp1.axa-direct-jp.intraxa,1767225600
ebroker-inssuite-prod.op-prod-lp1.axa-direct-jp.intraxa,1893456000
other-host.example.intraxa,1700000000
```

| Row intent | Meaning |
|---|---|
| First row | Expiry soon (pick a unix time **within next 30 days** from *today* when you test) |
| Second row | Far future — should **not** match `< now()+30d` |
| Third row | Wrong `dest` — filtered out |

**How to set `ssl_end_time` for a hit:** use a time ~10–20 days from now, e.g. in a shell you run yourself:

```
date -u -v+15d +%s
```

(macOS). Put that number in the first CSV row.

### Upload (tenant UI wording varies)

1. Dynatrace → Settings / Notebooks / Lookups (or **Settings → Log and events → Lookup tables**).  
2. Create / upload lookup named so DQL can `load "/lookups/sslcert_lookup"`.  
3. Run query 81 (or the verify variant below).

### Verify DQL for 81 (after upload)

```dql
load "/lookups/sslcert_lookup"
| filter dest == "ebroker-inssuite-prod.op-prod-lp1.axa-direct-jp.intraxa"
| fieldsAdd ssl_end = timestampFromUnixSeconds(toLong(ssl_end_time))
| filter ssl_end < now() + 30d
| fields dest, ssl_end, ssl_end_time
```

**Expected:** only the “soon expiry” row.

### Verify without lookup (math only)

```dql
data record(
    dest: "ebroker-inssuite-prod.op-prod-lp1.axa-direct-jp.intraxa",
    ssl_end_time: toString(toLong((now() + 15d) / 1s))
  ),
  record(
    dest: "ebroker-inssuite-prod.op-prod-lp1.axa-direct-jp.intraxa",
    ssl_end_time: toString(toLong((now() + 400d) / 1s))
  )
| fieldsAdd ssl_end = timestampFromUnixSeconds(toLong(ssl_end_time))
| filter ssl_end < now() + 30d
| fields dest, ssl_end
```

(Adjust division if your tenant’s timestamp units differ — goal is unix **seconds** into `timestampFromUnixSeconds`.)

---

## Method C — Sample logs for `fetch logs` (queries 82–84)

### What the DQL expects

| Piece | Sample value |
|---|---|
| Identity | `k8s.container.name` or `k8s.pod.name` or `log.source` contains `portals-amp-backend` |
| Body | `content` = JSON string (sometimes with escaped quotes) |
| JSON | `level`, `message.url`, `message.type` |

### Sample JSON bodies (logical)

**82 — error on save/quote/…**

```json
{
  "level": "error",
  "message": {
    "url": "save",
    "type": "SOME_TYPE"
  }
}
```

**83 — credit card exception**

```json
{
  "level": "error",
  "message": {
    "url": "payWithCreditCard_Adj",
    "type": "CAUGHT_EXCEPTION_ON_BACKEND"
  }
}
```

**84 — credit card completed**

```json
{
  "level": "info",
  "message": {
    "url": "payWithCreditCard_Adj",
    "type": "EXECUTION_COMPLETED"
  }
}
```

### Escaped `content` string (as in Splunk `_raw`)

If logs look like `{\"level\":\"error\",...}` use that in sample ingest / `data`:

```text
{\"level\":\"error\",\"message\":{\"url\":\"save\",\"type\":\"T\"}}
```

Your DQL already unescapes with `replaceString` then `parse … JSON`.

### Option C1 — Verify with `data` (no ingest)

File companion: `7-verify-portals-amp-with-data.dql` (below). Paste into Notebook: proves 82–84 logic.

### Option C2 — Ingest real logs into Grail

Pick one path your platform allows:

| Path | What you do |
|---|---|
| **Logs Ingest API** | POST JSON log lines with attributes + content (use Dynatrace “Log Monitoring API” / OpenPipeline ingest docs for your version) |
| **Test pod** | Deploy a tiny pod named/labeled `portals-amp-backend` that prints the JSON lines to stdout; OneAgent / log module ships them |
| **OpenPipeline** | Push via configured pipeline with test attributes |

Minimal conceptual payload shape (field names vary by API version — follow tenant docs):

```json
{
  "content": "{\"level\":\"error\",\"message\":{\"url\":\"save\",\"type\":\"T\"}}",
  "k8s.container.name": "portals-amp-backend",
  "log.source": "portals-amp-backend",
  "timestamp": "2026-10-19T00:00:00.000Z"
}
```

Then run the **real** `fetch logs` DQL from your `2.sh` (82–84).

---

## Ready-made verify queries (Method A)

### Verify 82 logic

```dql
data record(
    timestamp: now(),
    content: "{\\\"level\\\":\\\"error\\\",\\\"message\\\":{\\\"url\\\":\\\"save\\\",\\\"type\\\":\\\"T\\\"}}",
    log.source: "portals-amp-backend"
  ),
  record(
    timestamp: now(),
    content: "{\"level\":\"error\",\"message\":{\"url\":\"save\",\"type\":\"T\"}}",
    log.source: "portals-amp-backend"
  ),
  record(
    timestamp: now(),
    content: "{\"level\":\"info\",\"message\":{\"url\":\"save\",\"type\":\"T\"}}",
    log.source: "portals-amp-backend"
  ),
  record(
    timestamp: now(),
    content: "{\"level\":\"error\",\"message\":{\"url\":\"other\",\"type\":\"T\"}}",
    log.source: "portals-amp-backend"
  )
| filter contains(log.source, "portals-amp-backend")
| fieldsAdd raw = replaceString(replaceString(content, "\\\\\"", "\""), "\\\\", "\\")
| parse raw, "JSON:j"
| fieldsAdd msg_url = toString(j[message][url]), level = toString(j[level])
| filter in(msg_url, array("save", "ampupdateCoverages", "quote", "bind"))
| filter lower(level) == "error"
| fields timestamp, msg_url, level, content
```

**Expected:** rows with `url=save` and `level=error` (both escaped and plain JSON samples if unescape works).

### Verify 83 logic

```dql
data record(
    timestamp: now(),
    content: "{\"level\":\"error\",\"message\":{\"url\":\"payWithCreditCard_Adj\",\"type\":\"CAUGHT_EXCEPTION_ON_BACKEND\"}}",
    log.source: "portals-amp-backend"
  ),
  record(
    timestamp: now(),
    content: "{\"level\":\"error\",\"message\":{\"url\":\"payWithCreditCard_Adj\",\"type\":\"EXECUTION_COMPLETED\"}}",
    log.source: "portals-amp-backend"
  )
| filter contains(log.source, "portals-amp-backend")
| fieldsAdd raw = content
| parse raw, "JSON:j"
| fieldsAdd msg_url = toString(j[message][url]), msg_type = toString(j[message][type])
| filter matchesPhrase(msg_url, "payWithCreditCard_Adj")
| filter matchesPhrase(msg_type, "CAUGHT_EXCEPTION_ON_BACKEND")
| fields timestamp, msg_url, msg_type, content
```

**Expected:** only the CAUGHT_EXCEPTION row.

### Verify 84 logic

Same as 83 but filter `msg_type` == `EXECUTION_COMPLETED` → only the second sample row.

---

## Also useful for earlier DQL (8–11, 17–19, 53)

| Query type | Sample data tip |
|---|---|
| Host + keyword in `content` | `data record(host.name: "BILoss-…", content: "RuntimeException …")` then same filters |
| `matched_keywords` array | Two records: one matching keyword, one not |
| Stale hosts (18) | Several records with different `timestamp` / host; `summarize max(timestamp)` |
| Index≈src prefix (53) | `k8s.pod.name` / `host.name` starting with `bc2-ui` |

Example BILoss-style:

```dql
data record(
    timestamp: now(),
    host.name: "BILoss-processing-prod",
    content: "CC Error something RuntimeException"
  ),
  record(
    timestamp: now(),
    host.name: "BILoss-processing-prod",
    content: "all good"
  )
| filter host.name == "BILoss-processing-prod"
| filter matchesPhrase(content, "CC Error") or matchesPhrase(content, "RuntimeException")
| fields host.name, content
```

---

## Verify checklist

| Step | Pass |
|---|---|
| Method A runs in Notebook | You see expected rows only |
| Lookup CSV uploaded (81) | `load "/lookups/sslcert_lookup"` returns rows |
| 30d filter (81) | Only near-expiry dest row |
| 82 | error + url in {save, …} |
| 83 | payWithCreditCard_Adj + CAUGHT_EXCEPTION |
| 84 | payWithCreditCard_Adj + EXECUTION_COMPLETED |
| Optional Method C | Same results with `fetch logs` after ingest |

## Result

| Goal | How |
|---|---|
| Fast logic check | Method A `data record` |
| SSL lookup (81) | Method B CSV + `load` |
| Real `fetch logs` | Method C ingest a few lines |

## Data flow map

```
Sample strategy
  ├─ A: Notebook data record → same | filter / parse as prod DQL
  ├─ B: CSV → lookup store → load "/lookups/sslcert_lookup"
  └─ C: Ingest API / test pod → Grail → fetch logs
```

## Related files

| File | Purpose |
|---|---|
| `7-dql-sample-data-for-verify.md` | This guide |
| `7-sslcert_lookup.sample.csv` | Lookup sample for 81 |
| `7-verify-portals-amp-with-data.dql` | Pasteable Method A verifies for 82–84 |
| `7-sample-log-lines.jsonl` | Example lines for ingest |
| `7.sh` | Git one-liners (not run) |

## Commands

See `7.sh`. None have been run. Upload CSV / paste DQL in Dynatrace UI yourself.

```
# example only — generate unix seconds ~15 days ahead (macOS); put into CSV
date -u -v+15d +%s

cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-19/7-dql-sample-data-for-verify
git commit -m "dql sample data for verify guide"
git push
```
