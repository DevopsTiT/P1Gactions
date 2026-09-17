# Dynatrace Query Instructions

```
Want to query in Dynatrace?
  │
  ├─ 1 Pick where: Logs / Notebooks / Dashboard / Log alert
  ├─ 2 Set time range (Last 15 min / 1 hour / custom)
  ├─ 3 Write DQL: fetch → filter → parse → stats → sort → limit
  ├─ 4 Run → read table/chart
  └─ 5 Save query or turn into alert/dashboard tile
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What “query” means here | Ask Dynatrace for logs/events/spans/metrics with **DQL** |
| Best place to start | **Logs** app or **Notebooks** |
| Basic shape | `fetch` → `filter` → `parse` / `fields` → `stats` → `sort` → `limit` |
| Time range | Set in the UI (often more important than the query text) |

## Summary

In Dynatrace, most modern investigation uses **DQL** (Dynatrace Query Language). You pick a place to run it, set a time range, write a pipe-based query, and run it. Below: where to click, syntax basics, step-by-step UI, and starter queries.

---

## Investigation

Focused on **how to run queries in the UI** (not Workflows, not classic Problem notifications). Companion examples: `../2-dynatrace-dql-syntax-top10/`.

## Result

Follow Parts 1–6. Copy starter queries into Logs or Notebooks with time range **Last 15 minutes** first.

---

## 1) What a Dynatrace query is (plain English)

A **query** is a question to Dynatrace data, for example:

- “Show me the latest 100 logs”
- “Which uploads failed in the last 15 minutes?”
- “Which hosts have the most ERROR logs?”

| Term | What it means |
| --- | --- |
| DQL | Dynatrace Query Language (pipe `|` steps) |
| fetch | Choose the data source (`logs`, `spans`, …) |
| filter | Keep only matching rows |
| parse | Pull fields out of free-text log lines |
| stats | Count / sum / group |
| limit | Cap how many rows you get back |

Analogy: `fetch` = open the fridge, `filter` = pick items, `stats` = count them, `limit` = show top N.

---

## 2) Where to run queries (UI places)

| Place | What it is for | When to use |
| --- | --- | --- |
| **Logs** | Log search + DQL | Fast incident “what happened?” |
| **Notebooks** | Saved docs with DQL cells | Repeatable investigations, sharing |
| **Dashboards** | Tiles that run queries | Always-on views |
| **Log alerts / scheduled alerts** | Query on a timer | Alert when results appear (Terraform `search_query`) |
| **Workflows** (optional) | Automation may run a query action | Enrich then ticket/page |

**Beginner path:** start in **Logs** or **Notebooks**.

---

## 3) How to query in the UI (step by step)

### Option A — Logs app

1. Dynatrace left menu → **Logs** (or Logs and events).  
2. Switch to **DQL** mode if you see a simple search bar vs DQL toggle.  
3. Set **time range** (start with **Last 15 minutes**).  
4. Paste a query (see starters below).  
5. Click **Run** / Execute.  
6. Read the **table** (or chart if offered).  
7. Click a row to open raw record fields (learn real field names).

### Option B — Notebooks

1. Open **Notebooks** → **Create notebook** (or open existing).  
2. Add a **DQL** / Query section.  
3. Set time range for the section or notebook.  
4. Paste DQL → Run.  
5. **Save** the notebook so you can reuse it tomorrow.

### Option C — From a raw log to a better query

1. Run a wide query (`fetch logs | limit 20`).  
2. Open one record.  
3. Copy real attribute names (`aws.log_group`, `content`, `status`, …).  
4. Add `filter` / `parse` using those exact names.  
5. Re-run.

**Field names differ by ingest.** Always verify on one sample record in your tenant.

---

## 4) DQL syntax (core)

### Shape

```dql
fetch <source>
| <command> ...
| <command> ...
```

### Common sources

| Source | Meaning |
| --- | --- |
| `logs` | Log lines / records |
| `spans` | Trace spans |
| `events` | Events (tenant-dependent) |
| `bizevents` | Business events (if enabled) |
| `metrics` | Metric query form of DQL |

### Commands you use most

| Command | What it does | Example |
| --- | --- | --- |
| `filter` | Keep matching rows | `filter status == "ERROR"` |
| `filterOut` | Drop matching rows | `filterOut status == "DEBUG"` |
| `fields` | Keep listed columns | `fields timestamp, content` |
| `fieldsAdd` | Add calculated column | `fieldsAdd n = stringLength(content)` |
| `parse` | Extract from text | `parse content, "LD 'action:' WORD:action"` |
| `stats` | Aggregate | `stats count() by action` |
| `sort` | Order | `sort timestamp desc` |
| `limit` | Cap rows | `limit 100` |

### Operators

| Operator | Meaning |
| --- | --- |
| `==` `!=` | Equal / not equal |
| `and` `or` `not` | Combine conditions |
| `contains(field, "text")` | Field contains text |
| `>` `<` `>=` `<=` | Compare numbers |
| `in(...)` | Value in list |
| `isNull` / `isNotNull` | Null checks |

### Parse tokens (common)

| Token | Meaning |
| --- | --- |
| `LD` | Skip until next marker |
| `WORD:name` | One word → field `name` |
| `'action:'` | Literal text |
| `INT:name` / `DOUBLE:name` | Numbers |

---

## 5) Starter queries (copy-paste)

Set UI time range to **Last 15 minutes** first.

### 1) Smoke test — latest logs

```dql
fetch logs
| sort timestamp desc
| limit 100
```

### 2) Errors

```dql
fetch logs
| filter status == "ERROR" or loglevel == "ERROR" or contains(content, "ERROR")
| sort timestamp desc
| limit 100
```

### 3) One AWS Lambda log group (CDUS example)

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-createDocumentAction")
| sort timestamp desc
| limit 100
```

### 4) Keyword hunt

```dql
fetch logs
| filter contains(content, "UPLOAD_FAILED")
| sort timestamp desc
| limit 50
```

### 5) Parse action + document id

```dql
fetch logs
| filter contains(content, "action:") and contains(content, "cmxDocumentId:")
| parse content, "LD 'action:' WORD:action LD 'cmxDocumentId:' WORD:cmxDocumentId"
| fields timestamp, action, cmxDocumentId, content
| sort timestamp desc
| limit 100
```

### 6) Count by action

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-createDocumentAction")
| filter contains(content, "action:")
| parse content, "LD 'action:' WORD:action"
| stats count() as cnt by action
| sort cnt desc
| limit 20
```

### 7) Failed uploads per document

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-createDocumentAction")
| filter contains(content, "action:") and contains(content, "cmxDocumentId:")
| parse content, "LD 'action:' WORD:action LD 'cmxDocumentId:' WORD:cmxDocumentId"
| stats
    count(if(action == "UPLOAD_STARTED", 1, null)) as started,
    count(if(action == "UPLOAD_COMPLETED", 1, null)) as completed,
    count(if(action == "UPLOAD_FAILED", 1, null)) as failed,
    by: {cmxDocumentId}
| filter failed > 0
| sort failed desc
| limit 100
```

### 8) Pending uploads per document

```dql
fetch logs
| filter contains(aws.log_group, "/aws/lambda/document-upload-api-prod-createDocumentAction")
| filter contains(content, "action:") and contains(content, "cmxDocumentId:")
| parse content, "LD 'action:' WORD:action LD 'cmxDocumentId:' WORD:cmxDocumentId"
| stats
    count(if(action == "UPLOAD_STARTED", 1, null)) as started,
    count(if(action == "UPLOAD_COMPLETED", 1, null)) as completed,
    count(if(action == "UPLOAD_FAILED", 1, null)) as failed,
    by: {cmxDocumentId}
| filter started > 0 and completed == 0 and failed == 0
| sort started desc
| limit 100
```

### 9) Slow spans

```dql
fetch spans
| filter duration > 2000ms
| fields start_time, duration, request.url, service.name, http.response.status_code
| sort duration desc
| limit 20
```

More examples: `../2-dynatrace-dql-syntax-top10/2-dynatrace-dql-top10-examples.dql`

---

## 6) How to manage queries (save, share, alert)

| Goal | How |
| --- | --- |
| Reuse tomorrow | Save in **Notebook** |
| Team share | Share notebook / dashboard |
| Always visible | Pin query as **Dashboard** tile |
| Alert when rows appear | Scheduled **log alert** with same DQL as `search_query` |
| Incident habit | Start wide → filter → parse → stats |

### Turn a working query into an alert (concept)

1. Prove the DQL in Logs/Notebooks.  
2. Copy into log alert / Terraform `search_query`.  
3. Set schedule + time range (e.g. every 5 min, last 15 min).  
4. Trigger on number of results (or your threshold).  

See: `../1-cdus-pending-match-failed-pattern/` and `../3-failed-uploads-match-pending-syntax/`.

---

## 7) Common mistakes

| Mistake | Fix |
| --- | --- |
| No time range / too wide | Start Last 15–60 minutes |
| Wrong field name | Open one raw log; copy exact attribute |
| `limit` before `stats` | Aggregate first, then sort/limit |
| Parse matches nothing | First `contains(...)`, then tighten parse |
| Empty result | Broaden filter; confirm log group name; check ingest |
| Confused with Workflows | Query explores data; Workflow automates actions |

---

## 8) Query vs Workflow vs classic notification

| Tool | Job |
| --- | --- |
| DQL query | Investigate / chart / alert on data |
| Workflow | When Problem happens → call PD/SNOW |
| Problem notification | Classic push Problem → SNOW |

You often use **all three**: query to understand, alert/workflow to act.

---

## Data flow map

```
You
  → Logs / Notebooks
  → set time range
  → DQL: fetch → filter → parse → stats → sort → limit
  → Run
  → table/chart
  → optional: save notebook / dashboard / log alert
```

## Related files

| Path | Why |
| --- | --- |
| `../2-dynatrace-dql-syntax-top10/` | Top 10 DQL examples file |
| `../1-cdus-pending-match-failed-pattern/` | Pending alert DQL |
| `../3-failed-uploads-match-pending-syntax/` | Failed alert DQL style |
| `6.sh` | Paths |

## Commands

See `6.sh` in this folder.
