# DQL Search PII Discovery

```
Start PII audit on AXA prod hosts?
  │
  ├─ Step 0: Do logs exist for each host group? (inventory count)
  │     └─ NO hits → fix OneAgent / log ingest first
  │
  ├─ Step 1: Which app tier? (from Prod-HostGroupUpdate spreadsheet)
  │     ├─ HR / Customer MDM / Tax → HIGH → run per-host discovery first
  │     ├─ HULFT / FTP → MEDIUM → credentials + file paths
  │     └─ imageWARE / EIP / DFS / BC calc → LOW–MEDIUM → broad @ scan then app-specific
  │
  ├─ Step 2: Count before you sample
  │     └─ summarize count() by host.name + log.source
  │           └─ count > 0 → run sample query with limit 10–20
  │
  ├─ Step 3: Per-PII-type regex (email, EMPLID, My Number, etc.)
  │     └─ Note which log.source has the most hits
  │
  ├─ Step 4: Escalate findings
  │     ├─ App owner (Magaki) — stop logging at source if possible
  │     └─ Apply masking from seq 5 (`5-dynatrace-pii-hostgroup-axa`)
  │
  └─ Safety: read-only DQL, small samples, no broad export of raw PII
```

```
Time window choice
  │
  ├─ now()-1h   → quick spot check after a deploy or config change
  ├─ now()-24h  → daily discovery baseline (start here)
  └─ now()-7d   → weekly sweep — always summarize first; sample second
```

| Question | Answer |
| --- | --- |
| What is this guide? | **Discovery** DQL — find PII in logs **before** you mask |
| What comes after? | Masking and verification in seq 5 (`5-dynatrace-pii-hostgroup-axa`) |
| Where to run? | Logs and Events (Advanced mode), Notebooks, or Grail DQL |
| First query to run? | Inventory count by `dt.host_group.id` + `host.name` (last 24h) |
| Highest-risk hosts? | `EAA0059` (HR), `EAA006B` (MDM), `EAA0088` (Tax) |

## Summary

Use **DQL discovery queries** to audit what PII is already in Dynatrace logs on your AXA production hosts. Start with an **inventory count** (do logs arrive?), then **count hits per host and log source**, then **sample a small number of lines** to confirm real PII vs false positives. Run high-risk apps first (People Soft HR, Customer MDM, Tax Payment). When you know what leaks, apply the masking rules from seq 5 and re-run the seq 5 **verification** queries to confirm leaks trend to zero.

**DQL is read-only** for discovery — it does not mask or delete data. Treat results as sensitive; do not export raw log content broadly.

---

## What is DQL discovery vs masking?

| Term | What it means | Why you care |
| --- | --- | --- |
| DQL | Dynatrace Query Language — query language for logs in Grail | You use it to search and count log records |
| Discovery | Find where PII appears (count + sample) | You must know the problem before you mask |
| Masking | Replace or remove PII at capture, ingest, or display | Covered in seq 5 — do this **after** discovery |
| `host.name` | Hostname on the log record | Scopes queries to one server (e.g. `EAA0059`) |
| `dt.host_group.id` | Dynatrace host group ID from spreadsheet | Scopes queries to a group of hosts |
| `log.source` | Path or name of the log file | Tells you **which app log** contains PII |
| `content` | Raw log line text | Where regex and phrase matching run |

---

## How to run DQL in Dynatrace UI

### Option A — Logs and Events (fastest for ad-hoc)

1. Open **Logs and Events** (left menu).
2. Switch from **Simple mode** to **Advanced mode** (DQL editor).
3. Paste a query block from this guide or `6.sh`.
4. Set the time range in the picker **or** use `from: now()-24h` inside the query.
5. Click **Run**.
6. For sample queries, inspect `content` — **do not screenshot or export** raw PII to shared channels.

### Option B — Notebooks (repeatable audit)

1. Open **Notebooks** → **Create notebook**.
2. Add a **DQL** cell.
3. Paste the query; run the cell.
4. Save the notebook in a **restricted workspace** (PII audit team only).
5. Use **parameters** later for time range if your tenant supports them.

### Option C — Advanced mode tips

| Tip | Detail |
| --- | --- |
| Count first | Always run a `summarize count()` query before a `fields content` sample |
| Use `limit` | Sample queries: `limit 10` or `limit 20` — never pull thousands of PII lines |
| Time in query | `fetch logs, from: now()-24h` overrides or aligns with the UI picker |
| No results? | Widen to `now()-7d`, confirm host group migration, check OneAgent log monitoring |

---

## Time window guide

| Window | When to use | Risk |
| --- | --- | --- |
| `now()-1h` | After deploy, after enabling log source, quick check | May miss low-volume apps |
| `now()-24h` | **Default for discovery** — daily audit | Good balance |
| `now()-7d` | Weekly sweep, finding rare leaks | Large result sets — **summarize only** first |

Change the window in every query by editing `from: now()-24h` to your chosen range.

---

## Step 0 — Inventory: confirm logs arrive

Run this before any PII hunt. If a host has zero logs, discovery cannot find PII there (yet).

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE",
    "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP",
    "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"
  })
| summarize log_count = count(), by: { dt.host_group.id, host.name }
| sort log_count desc
```

**Interpret:** Every spreadsheet host should appear with `log_count > 0`. Missing host → check OneAgent and log monitoring on that server.

---

## Per-PII-type discovery queries

Run these **after** inventory. Replace `now()-24h` with your window. Add `| filter host.name == "..."` to scope to one host.

### Email addresses

**Count by host and log source:**

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE",
    "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP",
    "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"
  })
| filter matchesRegex(content, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

**Sample (after count > 0):**

```text
fetch logs, from: now()-24h
| filter host.name == "EAA0059.PRPRIVMGMT.intra"
| filter matchesRegex(content, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")
| fields timestamp, log.source, content
| limit 10
```

### EMPLID / employee ID (People Soft HR)

**Count:**

```text
fetch logs, from: now()-24h
| filter host.name == "EAA0059.PRPRIVMGMT.intra"
| filter matchesPhrase(content, "EMPLID")
| summarize hit_count = count(), by: { log.source }
| sort hit_count desc
```

**Sample (EMPLID=value shape):**

```text
fetch logs, from: now()-24h
| filter host.name == "EAA0059.PRPRIVMGMT.intra"
| filter matchesRegex(content, "(?i)EMPLID[=:\\s]+[A-Z0-9]+")
| fields timestamp, log.source, content
| limit 10
```

### My Number (Japan — 12-digit pattern)

Legal review required before treating matches as My Number. Use for **discovery only**.

**Count:**

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "EAA0059.PRPRIVMGMT.intra",
    "EAA006B.PRPRIVMGMT.intra",
    "EAA0088.PRPRIVMGMT.intra"
  })
| filter matchesRegex(content, "\\b\\d{12}\\b")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

**Sample:**

```text
fetch logs, from: now()-24h
| filter host.name == "EAA0059.PRPRIVMGMT.intra"
| filter matchesRegex(content, "\\b\\d{12}\\b")
| fields timestamp, log.source, content
| limit 10
```

### customer_id (Customer MDM)

**Count:**

```text
fetch logs, from: now()-24h
| filter host.name == "EAA006B.PRPRIVMGMT.intra"
| filter matchesPhrase(content, "customer_id")
| summarize hit_count = count(), by: { log.source }
| sort hit_count desc
```

**Sample:**

```text
fetch logs, from: now()-24h
| filter host.name == "EAA006B.PRPRIVMGMT.intra"
| filter matchesRegex(content, "(?i)customer_id[=:\\s]+\\S+")
| fields timestamp, log.source, content
| limit 10
```

### taxpayer_id (Tax Payment)

**Count:**

```text
fetch logs, from: now()-24h
| filter host.name == "EAA0088.PRPRIVMGMT.intra"
| filter matchesPhrase(content, "taxpayer_id")
| summarize hit_count = count(), by: { log.source }
| sort hit_count desc
```

**Sample:**

```text
fetch logs, from: now()-24h
| filter host.name == "EAA0088.PRPRIVMGMT.intra"
| filter matchesRegex(content, "(?i)taxpayer_id[=:\\s]+\\S+")
| fields timestamp, log.source, content
| limit 10
```

### Password / token / Bearer

**Count (all AXA inventory hosts):**

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE",
    "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP",
    "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"
  })
| filter matchesRegex(content, "(?i)(password|passwd|token|Bearer)\\s*[=:]\\s*\\S+")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

**Sample (HULFT hosts):**

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "EAA007F.PRPRIVMGMT.intra",
    "EAA0080.PRPRIVMGMT.intra",
    "EAA0081.PRPRIVMGMT.intra"
  })
| filter matchesRegex(content, "(?i)(password|passwd|user)\\s*[=:]\\s*\\S+")
| fields timestamp, log.source, content
| limit 10
```

### Credit card / long digit runs (13–19 digits)

**Count:**

```text
fetch logs, from: now()-24h
| filter host.name == "EAA0088.PRPRIVMGMT.intra"
| filter matchesRegex(content, "\\b(?:\\d[ -]*?){13,19}\\b")
| summarize hit_count = count(), by: { log.source }
| sort hit_count desc
```

**Sample:**

```text
fetch logs, from: now()-24h
| filter host.name == "EAA0088.PRPRIVMGMT.intra"
| filter matchesRegex(content, "\\b(?:\\d[ -]*?){13,19}\\b")
| fields timestamp, log.source, content
| limit 10
```

---

## Broad discovery — any `@` symbol

Fast first pass across all inventory hosts. High false-positive rate (email headers, URLs) — use to find **hot spots**, then narrow with per-type regex.

**Count by host:**

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE",
    "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP",
    "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"
  })
| filter matchesPhrase(content, "@")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

**Broad regex sweep (multiple PII shapes in one query):**

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE",
    "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP",
    "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE"
  })
| filter matchesRegex(content, "(?i)(EMPLID|customer_id|taxpayer_id|password|passwd|Bearer)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

---

## Per-host discovery queries (spreadsheet)

Run count → sample for each host. Priority order matches seq 5 risk tiers.

### EAA0059 — People Soft HR

Host group: `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE`

```text
fetch logs, from: now()-24h
| filter host.name == "EAA0059.PRPRIVMGMT.intra"
| filter matchesRegex(content, "(?i)(EMPLID|employee_id|@|\\b\\d{12}\\b)")
| summarize hit_count = count(), by: { log.source }
| sort hit_count desc
```

### EAA006B — Customer MDM

Host group: `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE`

```text
fetch logs, from: now()-24h
| filter host.name == "EAA006B.PRPRIVMGMT.intra"
| filter matchesRegex(content, "(?i)(customer_id|CUST_ID|CUST_NAME|address|@)")
| summarize hit_count = count(), by: { log.source }
| sort hit_count desc
```

### EAA0088 — Tax Payment Report Management

Host group: `C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP`

```text
fetch logs, from: now()-24h
| filter host.name == "EAA0088.PRPRIVMGMT.intra"
| filter matchesRegex(content, "(?i)(taxpayer_id|account_no|TIN|\\b\\d{12}\\b)")
| summarize hit_count = count(), by: { log.source }
| sort hit_count desc
```

### EAA007F / EAA0080 / EAA0081 — Hulft

Host group: `C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP`

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "EAA007F.PRPRIVMGMT.intra",
    "EAA0080.PRPRIVMGMT.intra",
    "EAA0081.PRPRIVMGMT.intra"
  })
| filter matchesRegex(content, "(?i)(password|passwd|user\\s*=|/[^\\s]+\\.(csv|txt|xml|dat))")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### EAA008F / EAA0090 / EAA0091 / EAA0092 — imageWARE

Host group: `C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE`

```text
fetch logs, from: now()-24h
| filter in(host.name, {
    "EAA008F.PRPRIVMGMT.intra",
    "EAA0090.PRPRIVMGMT.intra",
    "EAA0091.PRPRIVMGMT.intra",
    "EAA0092.PRPRIVMGMT.intra"
  })
| filter matchesRegex(content, "(?i)(form_data|applicant_name|address|postal_code|@)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### EAA006F — Enterprise Integration Platform

Host group: `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE`

```text
fetch logs, from: now()-24h
| filter host.name == "EAA006F.PRPRIVMGMT.intra"
| filter matchesRegex(content, "(?i)(error|exception|payload|customer_id|EMPLID)")
| summarize hit_count = count(), by: { log.source }
| sort hit_count desc
```

### FTP SSTB — `*-HFTP-01.ads-jp.intraxa`

Host group: `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE`

```text
fetch logs, from: now()-24h
| filter matchesValue(host.name, "*-HFTP-01.ads-jp.intraxa")
| filter matchesRegex(content, "(?i)(password|passwd|user\\s*=|/[^\\s]+\\.(csv|txt|xml|dat))")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### S-HQFS-01 — DFS

```text
fetch logs, from: now()-24h
| filter host.name == "S-HQFS-01.ads-jp.intraxa"
| filter matchesPhrase(content, "@")
| summarize hit_count = count(), by: { log.source }
| sort hit_count desc
```

### CEAA101D — BC calc

```text
fetch logs, from: now()-24h
| filter host.name == "CEAA101D.PRPRIVMGMT.intra"
| filter matchesRegex(content, "(?i)(@|\\b\\d{12}\\b|customer_id)")
| summarize hit_count = count(), by: { log.source }
| sort hit_count desc
```

---

## Per-host-group discovery queries

Use host group when one group maps cleanly to one app family. **Exception:** `C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE` mixes HR, MDM, FTP, DFS, EIP, BC calc — always add `host.name` filter for high-PII apps on that group.

### C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE (shared infra — split by host)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BASE")
| filter matchesRegex(content, "(?i)(EMPLID|customer_id|password|@)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
| limit 50
```

### C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(password|passwd|user\\s*=|/[^\\s]+\\.(csv|txt|xml|dat))")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)(taxpayer_id|account_no|\\b\\d{12}\\b)")
| summarize hit_count = count(), by: { log.source }
| sort hit_count desc
```

### C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_MIDDLEWARE-SHARED-PRODUCT_A_imageWARE")
| filter matchesRegex(content, "(?i)(form_data|applicant_name|address|@)")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

---

## How to interpret results

| Result | What it means | Next action |
| --- | --- | --- |
| `log_count = 0` for a host | No logs ingested for that host in the time window | Fix OneAgent log monitoring before PII audit |
| `hit_count > 0` on count query | PII **pattern** found — may include false positives | Run sample query with `limit 10`; confirm real PII in `content` |
| Sample shows real email / ID / password | Confirmed leak in Grail | Escalate to Magaki (app owner); apply seq 5 masking |
| Sample shows masked value already (`xxx@xxx.xxx`) | Masking may already be active | Switch to seq 5 **verification** queries (post-mask) |
| High hits on one `log.source` | That log file is the main leak path | App team: reduce logging at source; you: scope mask rule to `log.source` |
| 12-digit regex matches timestamps or IDs | False positive | Tighten regex or add context (`mynumber`, `個人番号`) |

### Escalation checklist

1. Record: host name, log source, PII type, approximate hit count (not raw lines).
2. Share **redacted** samples with Magaki only (private ticket or restricted notebook).
3. Open masking work using seq 5 (`5-dynatrace-pii-hostgroup-axa`).
4. After masking deploy, run seq 5 verification DQL — leaks should trend to zero.

---

## Safety — read-only audit rules

| Rule | Why |
| --- | --- |
| Discovery DQL is read-only | `fetch` and `summarize` do not change or delete Grail data |
| Count before sample | Reduces how much raw PII you expose to your screen |
| Use `limit 10` or `limit 20` on samples | Enough to confirm; not a bulk export |
| Do not export full result sets | CSV export of raw `content` spreads PII |
| Restrict notebook access | PII audit notebooks belong in a locked workspace |
| Redact screenshots | Blur `content` before posting to Slack or tickets |
| Legal review for My Number | 12-digit regex is a shape match, not legal classification |

---

## After discovery — link to masking (seq 5)

| Phase | Guide | What you do |
| --- | --- | --- |
| **Now (seq 6)** | This guide | Find PII with discovery DQL |
| **Next (seq 5)** | `5-dynatrace-pii-hostgroup-axa` | OneAgent masking, OpenPipeline processors, verification DQL |
| **General concepts (seq 1)** | `1-dynatrace-logs-pii-filter` | PII layers, OpenPipeline vs query-time mask |

---

## Data flow map

```
Prod-HostGroupUpdate spreadsheet (hostname + dt.host_group.id)
        │
        ▼
Step 0: DQL inventory count (logs arriving?)
        │
        ▼
Step 1: Per-PII-type count (email, EMPLID, My Number, …)
        │
        ▼
Step 2: Per-host / per-host-group count (prioritize HR, MDM, Tax)
        │
        ▼
Step 3: Sample query (limit 10) → confirm real PII in content
        │
        ├─ False positive → refine regex / log.source
        │
        └─ Confirmed PII → escalate to Magaki
                │
                ▼
        seq 5: OneAgent + OpenPipeline masking
                │
                ▼
        seq 5 verification DQL (leak count → 0)
```

---

## Related files

| File | Role |
| --- | --- |
| `6-dql-search-pii-discovery.md` | This guide |
| `6-dql-search-pii-discovery-question.md` | User question |
| `6-dql-search-pii-discovery-follow.txt` | Chat-ready copy |
| `6.sh` | All discovery DQL one-liners |
| `5-dynatrace-pii-hostgroup-axa/` | Masking and post-mask verification (seq 5) |
| `1-dynatrace-logs-pii-filter/` | General Dynatrace PII concepts (seq 1) |

## Commands

All discovery DQL one-liners are in `6.sh`. Paste each line into **Logs and Events → Advanced mode** or a **Notebook** DQL cell. See section **How to run DQL in Dynatrace UI** above.
