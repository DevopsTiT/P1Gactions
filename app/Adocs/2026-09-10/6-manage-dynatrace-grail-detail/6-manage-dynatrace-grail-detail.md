# Manage Dynatrace Grail In Detail

```
What do you need to manage?
  │
  ├─ How long data lives? → Buckets + retention
  ├─ What gets stored / masked / dropped? → OpenPipeline
  ├─ Who can read which data? → IAM + security context
  ├─ Cost / query spend? → Bucket model + query scope
  └─ Day-2 health? → ingest volume, DQL verify, weekly hygiene
```

| Key point | Detail |
| --- | --- |
| What Grail is | Dynatrace data lakehouse (logs, spans, events, metrics, …) |
| What “manage” means | Retention, routing, processing, access, cost, quality |
| Main knobs | Buckets, OpenPipeline, IAM policies, OneAgent ingest |
| Query language | DQL (`fetch logs`, …) — see seq 5 cheat sheet |

## Summary

**Grail** is where Dynatrace keeps observability data. Managing it is not “run one query” — it is controlling **what enters**, **where it is stored**, **how long it stays**, **who can read it**, and **how expensive queries are**. Day-2 work = buckets + OpenPipeline + permissions + verify with DQL.

---

## 1. Plain English — pieces you manage

| Piece | What it means | Why you care |
| --- | --- | --- |
| Grail | Central storage for observability data | Single place for Logs / Traces / Events queries |
| Table | Data type (logs, spans, events, bizevents, …) | You `fetch` a table in DQL |
| Bucket | Storage “bin” inside a table with its own retention | Prod logs 90d vs debug 10d |
| Default buckets | Built-in (e.g. `default_logs`, `default_spans`) | Everything lands here unless you route |
| OpenPipeline | Ingest pipeline: filter, mask, enrich, assign bucket, drop | Shape data **before** it is stored |
| DQL | Query language over Grail | Triage, dashboards, verify |
| IAM / security context | Who may read which buckets / records | Least privilege; separate teams |
| DPS / billing | Dynatrace Platform Subscription usage | Retention + query cost |

```
Sources (OneAgent, APIs, Firehose, …)
        │
        ▼
OpenPipeline (process / mask / route / drop)
        │
        ▼
Grail buckets (retention + access)
        │
        ▼
DQL / Notebooks / Dashboards / Apps
```

Official organize guide:  
https://docs.dynatrace.com/docs/platform/grail/organize-data  

Log bucket assignment:  
https://docs.dynatrace.com/docs/analyze-explore-automate/logs/lma-bucket-assignment

---

## 2. Architecture of management (what you control)

```
                    ┌─────────────────────────────┐
                    │  Identity & access (IAM)      │
                    │  bucket read / security ctx   │
                    └──────────────┬────────────────┘
                                   │
┌──────────────┐   ┌───────────────▼───────────────┐   ┌────────────────┐
│ Ingest       │──►│ OpenPipeline                  │──►│ Grail buckets  │
│ OneAgent     │   │  process / mask / enrich      │   │ retention      │
│ Log API      │   │  bucket assignment / drop     │   │ table: logs…   │
│ Firehose …   │   └───────────────────────────────┘   └────────┬───────┘
└──────────────┘                                                 │
                                                                 ▼
                                                        DQL consumers
```

| Layer | Manage what | Healthy look |
| --- | --- | --- |
| Ingest | What hosts/apps send | Expected volume; no silent gaps |
| OpenPipeline | Mask PII, drop noise, assign bucket | Fake PII → `***`; debug not in long-retention bucket |
| Buckets | Retention days + table | Matches compliance (e.g. 90d prod logs) |
| IAM | Who reads which bucket | Dev cannot read prod PII bucket |
| Query | Timeframe + filters | Short windows; prefer bucket-scoped queries |

---

## 3. Step-by-step — manage buckets (retention)

### 3.1 What a bucket is

Think of a **bucket** as a labeled drawer:

| Drawer | Example | Retention |
| --- | --- | --- |
| Default logs | `default_logs` | Often **35 days** (confirm in your tenant) |
| Default spans | `default_spans` | Often **10 days** |
| Custom | `logs_prod_90d` | You choose (commonly 10 days–years; UI/API limits apply) |

Rules of thumb:

| Rule | Why |
| --- | --- |
| Do not put everything in one long-retention bucket | Cost + slow queries + wider blast radius |
| Shorten retention carefully | **Deletes** data older than the new period |
| Never delete `dt_*` / system defaults casually | Built-ins are protected / special |

### 3.2 Create a custom log bucket (UI)

1. Dynatrace → **Settings**  
2. **Storage management** → **Bucket storage management**  
3. **Bucket** → create  
4. Set:

| Field | Example |
| --- | --- |
| Name | `logs_prod_90d` (allowed chars: lowercase, numbers, `_`, `-`) |
| Table | `logs` |
| Retention days | `90` (match compliance / Splunk sheet where relevant) |

5. Save  

Pass check: bucket appears in the list; status healthy / live.

### 3.3 Permissions needed to manage buckets

| Permission | Purpose |
| --- | --- |
| `storage:bucket-definitions:read` | List / view buckets |
| `storage:bucket-definitions:write` | Create / update |
| `storage:bucket-definitions:delete` | Delete user buckets |
| `storage:bucket-definitions:truncate` | Truncate contents |

### 3.4 Dangerous operations (stop and confirm)

| Action | Effect |
| --- | --- |
| Shorten retention | Data beyond new window is **gone** |
| Delete bucket | Irreversible; blocked if OpenPipeline still references it (`409`) |
| Truncate | Empties data — treat like production wipe |

---

## 4. Step-by-step — OpenPipeline (route + process)

OpenPipeline is how you **manage content before Grail stores it**.

### 4.1 Open the right scope

1. **Settings** → **Process and contextualize** → **OpenPipeline**  
2. Pick scope: **Logs** (most common for you), or Spans / Events / …  
3. Work with **Pipelines** + **Dynamic routing**

### 4.2 Typical pipeline stages you manage

| Stage / processor | What it does | When you use it |
| --- | --- | --- |
| Processing / DQL | Parse, rename, enrich fields | Normalize `loglevel`, extract queue name |
| Mask sensitive data | Replace secrets / PII with `***` | JP PII (氏名, 口座番号, …) |
| Drop record | Do not store the record | Pure noise / forbidden payloads |
| Bucket assignment | Send matching records to a custom bucket | Prod 90d vs test 14d |
| No storage assignment | Skip storage | Explicitly do not retain |
| Security context | Set `dt.security_context` | Record-level access by team |

### 4.3 Route logs into your bucket (happy path)

1. Create bucket (section 3)  
2. OpenPipeline → **Logs** → **Pipelines** → edit or create pipeline  
3. Add **Bucket assignment** processor:

| Field | Example |
| --- | --- |
| Name | `assign-prod-logs-90d` |
| Matching condition | e.g. hosts/tags/env match prod |
| Storage | `logs_prod_90d` |

4. **Dynamic routing**: ensure records hit this pipeline (route match → pipeline)  
5. Save  

Pass check: new logs matching the condition appear when you DQL-filter that bucket (or confirm via pipeline metrics / preview if available).

### 4.4 Your team’s PII manage pattern (already started)

| Order | Layer | Job |
| --- | --- | --- |
| 1 | OneAgent Sensitive data masking | Mask at host before/around capture |
| 2 | OpenPipeline mask | Second net for API / other ingest |
| 3 | DQL verify | Confirm Grail has no raw PII |

Detail: `Daily Files/2026-09-07/22-prevent-jp-pii-oneagent-openpipeline/`

---

## 5. Step-by-step — who can read Grail (IAM)

### 5.1 Bucket read access

Users need policies that allow reading storage, for example conceptually:

```
ALLOW storage:buckets:read WHERE storage:bucket-name = "logs_prod_90d";
ALLOW storage:logs:read;
```

(Exact policy language follows your Account Management IAM docs — adjust to tenant templates.)

| Goal | Practice |
| --- | --- |
| Prod on-call reads prod logs | Grant prod bucket only |
| Dev team | Dev / test buckets only |
| Break-glass admin | Separate role, audited |

### 5.2 Record-level security context

OpenPipeline can set **`dt.security_context`**. Then IAM can allow read only when context matches (team / app / env). Use this when one bucket holds multi-tenant data.

### 5.3 Query hygiene = access hygiene

| Do | Do not |
| --- | --- |
| Short timeframe | `fetch logs` with no filter over months |
| Filter host / app / loglevel early | Full-table scans for curiosity |
| Prefer known bucket when policy allows | Broad queries across all buckets |

---

## 6. Cost and retention models (manage spend)

On DPS, buckets can use models such as:

| Model | Plain English | When |
| --- | --- | --- |
| Usage-based queries | You pay per query scan/execution | Ad-hoc heavy exploration |
| Retain with Included Queries | Retention price includes queries for a window | Stable ops / dashboards |

Manage cost by:

| Lever | Action |
| --- | --- |
| Retention | Shorter for noisy / low-value logs |
| Drop at pipeline | Never store DEBUG flood |
| Bucket split | Query small buckets, not everything |
| Dashboard design | Tight filters + reasonable refresh |

---

## 7. Day-2 manage checklist (weekly)

### A. Storage

| Check | Pass means |
| --- | --- |
| Bucket list | Custom buckets still correct retention |
| OpenPipeline routes | Still pointing at intended buckets |
| No orphan pipelines | Unused routes cleaned or documented |

### B. Quality / privacy

| Check | Pass means |
| --- | --- |
| PII verify DQL | No raw 氏名/口座番号 (or only `***`) |
| ERROR/FATAL sample | Fields usable (host, app tag) |
| Ingest gap | Critical hosts still sending logs |

### C. Access / incidents

| Check | Pass means |
| --- | --- |
| IAM reviews | Leavers removed from bucket policies |
| Break-glass | Rare and logged |
| On-call can query | Prod bucket readable by ops role |

### D. Cost

| Check | Pass means |
| --- | --- |
| Top query spend | No runaway Notebooks |
| High-volume log sources | Dropped or short retention |

---

## 8. Detailed example — manage CCI / Lambda “Task timed out” in Grail

**Story:** Splunk had index `cci-fa-comm-calc` + alert on `Task timed out`. After migration, those logs live in Grail. You manage retention, searchability, and optional alert.

### Step A — Know the ingest path

| Item | Example |
| --- | --- |
| Source | `/aws/lambda/cci-fa-comm-calc` (from your sheet) |
| Splunk index (AS-IS) | `cci-fa-comm-calc`, retention 100d |
| Grail target | e.g. bucket `logs_aws_lambda_100d` or `default_logs` |

### Step B — Bucket decision

| Choice | When |
| --- | --- |
| Keep default | Pilot / low volume |
| Custom 100d bucket | Match old Splunk retention for CCI family |
| Shorter + archive elsewhere | Cost-first |

### Step C — OpenPipeline (optional enrich)

| Processor | Example |
| --- | --- |
| Add field | `app = "cci-fa-comm-calc"` |
| Mask | If any secrets appear in Lambda logs |
| Bucket assignment | Match Lambda log group / attribute → `logs_aws_lambda_100d` |

### Step D — Query / alert in Grail (ops)

```dql
fetch logs
| filter contains(content, "Task timed out")
| filter not contains(content, "DEBUG")
| summarize hits = count(), by: { host.name }
| sort hits desc
```

Schedule this in a Notebook / workflow / metric event equivalent if you replace the Splunk cron alert.

### Step E — Manage ongoing

| Cadence | Action |
| --- | --- |
| Weekly | Run timeout DQL; compare to incident count |
| Monthly | Review retention vs compliance |
| On change | If Lambda name changes, update pipeline match |

---

## 9. Manage by data type (quick matrix)

| Data | Default idea | Manage via |
| --- | --- | --- |
| Logs | Often 35d default | OpenPipeline Logs + log buckets |
| Spans / traces | Often 10d default | OpenPipeline Spans + span buckets |
| Events | Depends on kind | OpenPipeline Events |
| Metrics | Separate metric storage rules | Metrics settings / Grail metrics capabilities |
| Biz events | Business pipelines | OpenPipeline Business events |

---

## 10. Troubleshooting

| Symptom | Likely cause | What to check |
| --- | --- | --- |
| DQL returns empty | Wrong timeframe / no ingest / IAM | Time picker; host sending; bucket read policy |
| Data disappears early | Retention too short / shortened | Bucket retention days |
| Cannot delete bucket | Still referenced | OpenPipeline bucket assignment list |
| PII still visible | Mask missing / wrong path | OneAgent scope + OpenPipeline Logs pipeline |
| Huge bill | Wide queries / long retention / no drop | Top queries; drop DEBUG; split buckets |
| Logs in wrong bucket | Route / match condition | Dynamic routing + processor condition |

---

## Investigation

Based on Dynatrace docs for Grail organize-data, log bucket assignment, OpenPipeline processing, and bucket management API permissions — mapped to your AXA-style log migration, PII masking, and CCI timeout use cases.

## Result

Manage Grail as five loops: **ingest → OpenPipeline → buckets → IAM → DQL verify**. Use weekly hygiene; treat retention shorten / delete as irreversible.

## Data flow map

```
App / Lambda / Host
  → ingest
  → OpenPipeline (mask | drop | enrich | bucket assign)
  → Grail bucket (retention N days)
  → IAM allows read?
        yes → DQL / dashboard / alert
        no  → empty / denied
```

## Related files

| File | Purpose |
| --- | --- |
| `6.sh` | UI path reminders |
| Seq 5 | Common Grail DQL cheat sheet |
| Seq 22 (2026-09-07) | JP PII OneAgent + OpenPipeline |
| Docs | Grail organize-data + log bucket assignment |

## Commands

See `6.sh` (UI reminders only).
