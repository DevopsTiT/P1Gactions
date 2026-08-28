

---

# SOURCE: today/0-index-today.md

# Today Index 2026-08-28

```
today's questions
  1 → Dynatrace Logs PII Filtering
  2 → Pic Style Answer Workflow
  3 → Generate All Files For Today
  next → 4-...
```

## Short takeaway

| Seq | Folder | Topic |
|-----|--------|-------|
| 1 | `1-dynatrace-logs-pii-filter` | Mask/filter PII in Dynatrace logs |
| 2 | `2-pic-style-answer-workflow` | Numbered Files+Adocs answer standard (pic example) |
| 3 | `3-generate-all-files-today` | Backfill + complete all today packs |

## Paths

| Root | Path |
|------|------|
| Files | `/Users/k/Work/AIProjects/Files/2026-08-28/` |
| Adocs | `/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-28/` |

## Per-folder file checklist

| File | Required |
|------|----------|
| `0-pic.md` | Yes |
| `1-investigation.md` | Yes |
| `2-result.md` | Yes |
| `3-glossary.md` | Yes |
| `<seq>-<slug>.md` | Yes |
| `<seq>.sh` | Yes |
| `*-follow.txt` | Yes |

## Investigation

Inventory showed Files missing seq 1; Adocs seq 1 missing companions; seq 2 complete; no day index. All gaps closed in seq 3 work.

## Result

Today is fully generated on both roots. Next question uses **seq 4**.


---

# SOURCE: 1-dynatrace main

# Dynatrace Logs PII Filtering

```
Need PII out of Dynatrace logs?
  │
  ├─ Can you stop logging it in the app?
  │     └─ YES → fix app/logger first (strongest control)
  │
  ├─ Logs collected by OneAgent?
  │     └─ YES → OneAgent Sensitive data masking (capture, before send)
  │
  ├─ Logs via Fluent Bit / OTel / Log ingest API?
  │     └─ YES → mask in shipper OR rely on OpenPipeline at ingest
  │
  ├─ Need centralized rules for all ingest channels?
  │     └─ YES → OpenPipeline (mask / drop / remove fields) → Grail
  │
  ├─ PII already stored in Grail?
  │     └─ YES → Sensitive Data Center (scan + cleanup workflow)
  │              + tighten ingest rules going forward
  │
  └─ Analyst must not SEE raw PII in UI?
        └─ DQL mask at query time (display only — does NOT erase Grail)
```

```
OpenPipeline processor choice
  │
  ├─ Whole log line is toxic → Drop record processor
  ├─ One field always secret → Remove fields processor
  ├─ Pattern inside content → DQL processor (replacePattern / parse)
  └─ Structured JSON field → fieldsRemove or DQL on that attribute
```

| Question | Answer |
| --- | --- |
| What is PII here? | Data that identifies a person (email, phone, SSN, name, IP in some jurisdictions) |
| Best place to filter? | Application logger first, then OneAgent capture, then OpenPipeline ingest |
| What is Grail? | Dynatrace unified data lake where logs are stored after processing |
| What is OpenPipeline? | Ingest-time processing engine (parse, mask, drop) before Grail storage |
| Does DQL query masking delete data? | No. It only changes what you see in that query or notebook |
| Compliance note | GDPR and similar laws expect minimization, masking, retention limits, and audit trails |

## Summary

Dynatrace gives you a **defense-in-depth** stack for log PII: stop logging secrets in the app, mask on the host with **OneAgent**, centralize with **OpenPipeline** processors before **Grail** storage, and use **Sensitive Data Center** to find and clean up mistakes. Treat **DQL query-time masking** as a display safety net for analysts, not as your primary control.

## Key concepts (beginner)

| Term | What it means | Why you care |
| --- | --- | --- |
| PII | Personally Identifiable Information | Regulators and customers expect you to protect it |
| Grail | Dynatrace storage layer for logs and other observability data | Once PII lands here unmasked, you need cleanup workflows |
| OpenPipeline | Configurable ingest pipeline with processors | One place to mask logs from OneAgent, API, syslog, OTel, and more |
| DQL | Dynatrace Query Language | Used in notebooks, log search, and OpenPipeline DQL processors |
| DPL | Dynatrace Pattern Language | Pattern matchers inside `parse` and `replacePattern` |
| Masking at capture | Redaction on the host before data leaves your environment | Strongest option when using OneAgent |
| Masking at ingest | Redaction in OpenPipeline before Grail write | Works across ingest channels |
| Log ingest rules | OneAgent rules that include or exclude log sources | Reduces volume; does not replace masking |
| Sensitive Data Center | Privacy workflows for export, deletion, scheduled scans | Finds PII already stored and supports approved cleanup |

## Where to filter: comparison

| Layer | When to use | PII leaves your network? | Stored masked in Grail? |
| --- | --- | --- | --- |
| Application logging | Always start here | Only if you still log PII | Depends on downstream rules |
| OneAgent sensitive data masking | OneAgent log collection | No (if rule matches before send) | N/A — never sent raw |
| Log shipper (Fluent Bit, OTel) | Non-OneAgent paths | Yes, unless shipper masks | Depends on OpenPipeline |
| OpenPipeline mask / drop | Central policy for all channels | Often yes (already in Dynatrace) | Yes, if processor runs before storage |
| DQL at query time | Analyst dashboards and ad-hoc search | N/A | No — raw may still exist |
| Sensitive Data Center cleanup | Incident or audit finding | N/A | Deletes matching records after approval |

Official reference: [Mask sensitive data in logs](https://docs.dynatrace.com/docs/analyze-explore-automate/logs/lma-use-cases/methods-of-masking-sensitive-data)

## PII types and example controls

| PII type | Example in logs | Preferred control | OpenPipeline / DQL hint |
| --- | --- | --- | --- |
| Email | `user=marie@example.com` | OneAgent built-in email rule or OpenPipeline | `replacePattern` on email shape, or `parse` + `replaceString` |
| Phone | `+1-415-555-0199` | Regex mask at capture or ingest | `replacePattern` for digit groups |
| Credit card | `4111111111111111` | OneAgent built-in payment card rule | `replacePattern` for 13–19 digit groups; validate with test data |
| SSN (US) | `123-45-6789` | Regex at capture or ingest | `replacePattern` for `###-##-####` |
| My Number (Japan) | `123456789012` | App must not log; regex at ingest | 12-digit pattern; legal review required |
| Person name | `customer=Jane Doe` | Do not log names; use user ID | `fieldsRemove customer_name` if structured |
| IP address | `client_ip=203.0.113.45` | Mask if IP is PII in your jurisdiction | `ipMask(ip, 24)` or `replacePattern(..., "IPADDR", ...)` |
| Auth token | `Authorization: Bearer eyJ...` | Never log; drop field | `fieldsRemove authorization` or mask `Bearer` value |
| Password | `password=Secret123` | Never log; code review | `fieldsRemove password` or mask `password=` segment |

Built-in OneAgent rules (payment cards, email) exist but are **off by default** in paid environments until you enable them. See [Sensitive data masking in OneAgent](https://docs.dynatrace.com/docs/analyze-explore-automate/logs/lma-log-ingestion/lma-log-ingestion-via-oa/lma-sensitive-data-masking).

---

## Step-by-step: OpenPipeline mask or drop

**Navigation:** Settings → Process and contextualize → OpenPipeline → Logs → Pipelines

### A. Create a pipeline route (if not using default)

1. Open **Routes** and send matching logs to your custom pipeline (for example by `log.source` or Kubernetes namespace).
2. Use a notebook filter first, then copy the matcher (for example `matchesValue(log.source, "checkout-api")`). See [OpenPipeline processing examples](https://docs.dynatrace.com/docs/platform/openpipeline/use-cases/processing-examples).

### B. Mask with a DQL processor (Processing stage)

1. Pipeline → **Processing** → **Processor** → **DQL**.
2. Set **Matching condition** (which log records this applies to).
3. Paste **DQL processor definition** (processing statements only — not a full `fetch logs` query).
4. **Run sample data** with realistic PII examples.
5. **Save** the pipeline.

**Example — mask email local-part in `content`:**

```text
parse content, "LD 'email: ' LD:user '@'"
| fieldsAdd content = replaceString(content, user, "xxx")
| fieldsRemove user
```

**Example — mask all IPv4 in `content`:**

```text
fieldsAdd content = replacePattern(content, "IPADDR", "xxx.xxx.xxx.xxx")
```

**Example — mask last octet of structured `ip` field:**

```text
fieldsAdd ip = ipMask(ip, 24)
```

**Example — mask common secrets in free text:**

```text
fieldsAdd content = replacePattern(content, "(?i)(password|token|api[_-]?key)\\s*[=:]\\s*\\S+", "$1=***")
```

**Example — multi-pattern PII pass (test carefully):**

```text
fieldsAdd content = replacePattern(content, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", "xxx@xxx.xxx")
| fieldsAdd content = replacePattern(content, "\\b\\d{3}-\\d{2}-\\d{4}\\b", "XXX-XX-XXXX")
| fieldsAdd content = replacePattern(content, "\\b(?:\\d[ -]*?){13,19}\\b", "XXXX-XXXX-XXXX-XXXX")
```

### C. Drop entire records (Processing stage)

Use **Drop record** when a line cannot be salvaged (full PAN dump, debug payload with credentials).

**Matching condition example:**

```text
matchesPhrase(content, "full_card_number_dump")
```

Or drop noisy non-PII traffic that still drives cost:

```text
matchesPhrase(content, "ELB-HealthChecker")
```

Dropped records are **not stored** in Grail.

### D. Remove structured secret fields

Use **Remove fields** processor when JSON logs carry dedicated keys.

| Field to remove | Example key names |
| --- | --- |
| Password | `password`, `passwd` |
| Token | `token`, `access_token`, `id_token` |
| Authorization header | `authorization`, `Authorization` |
| API key | `api_key`, `apiKey`, `x-api-key` |

---

## Step-by-step: OneAgent capture masking

**Navigation:** Settings → Collect and capture → Log monitoring → Configure log module → Sensitive data masking

1. Select **New rule**.
2. **Rule name:** descriptive label (for example `mask-email-checkout`).
3. **Masking type:** Replace with string (for example `***`) or SHA-256 (one-way hash for correlation without exposing raw value).
4. **Search expression:** regex with at most one capture group (entire match is used if no group).
5. **Matchers:** narrow scope (process group, `log.source`, Kubernetes namespace, container name).
6. **Save** and reorder rules — they run top to bottom; host rules beat host group beat environment.

**Example regex ideas (validate in staging):**

| Target | Example search expression |
| --- | --- |
| Email | `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}` |
| US phone | `\b\d{3}[-.]?\d{3}[-.]?\d{4}\b` |
| Bearer token | `Bearer\s+\S+` |

Docs: [Sensitive data masking in OneAgent](https://docs.dynatrace.com/docs/analyze-explore-automate/logs/lma-log-ingestion/lma-log-ingestion-via-oa/lma-sensitive-data-masking)

---

## Step-by-step: Log ingest rules (volume, not masking)

**Navigation:** Settings → Collect and capture → Log monitoring → Log ingest rules

| Goal | Action |
| --- | --- |
| Stop collecting chatty debug files | Exclude by `log.source` or `log.level` |
| Collect only payment service logs | Include matcher on process group or namespace |
| Reduce cost | Combine ingest rules with OpenPipeline drop |

Ingest rules control **what is collected**. They do **not** replace PII masking.

---

## Step-by-step: DQL query-time filtering (analysts)

Use this when you need safer dashboards but cannot change ingest yet.

**Important:** Query-time masking does **not** remove PII from Grail. Anyone with bucket access and a different query may still see raw values.

**Navigation:** Logs and Events → Advanced mode, or a Notebook

**Example — mask email in results:**

```text
fetch logs
| filter matchesValue(service.name, "checkout-api")
| fieldsAdd content_safe = replacePattern(content, "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}", "xxx@xxx.xxx")
| fields timestamp, content_safe, log.source
| limit 50
```

**Example — exclude lines that look like secrets:**

```text
fetch logs
| filter not matchesPhrase(content, "password=")
| filter not matchesPhrase(content, "Bearer ")
| limit 100
```

Workflow tip from Dynatrace: prototype patterns with **Extract fields** in the UI, then promote working DQL to OpenPipeline.

---

## Step-by-step: Application-level (strongest)

| Practice | What to do |
| --- | --- |
| Structured logging | Log `user_id` hash, not email or legal name |
| Denylist fields | Never pass `password`, `ssn`, `pan`, `cvv` to the logger |
| HTTP logging | Log path and status, not `Authorization` header |
| Error messages | Return generic errors to users; keep detail in trace IDs |
| SDK configuration | Disable request/response body logging in frameworks |

If the app never emits PII, downstream rules become a safety net instead of your only control.

---

## Step-by-step: Terraform / IaC

Dynatrace Terraform provider supports both capture-time and ingest-time configuration.

| Resource | Purpose |
| --- | --- |
| `dynatrace_log_sensitive_data_masking` | OneAgent log masking rules (`builtin:logmonitoring.sensitive-data-masking-settings`) |
| `dynatrace_openpipeline_v2_logs_pipelines` | OpenPipeline pipelines with `dql`, `drop`, `fieldsRemove`, and related processors |
| `dynatrace_openpipeline_v2_logs_routes` | Route logs into your custom pipeline |

**Example — OneAgent masking rule (illustrative):**

```hcl
resource "dynatrace_log_sensitive_data_masking" "mask_bearer" {
  name    = "mask-bearer-tokens"
  enabled = true
  scope   = "environment"

  masking {
    type        = "STRING"
    expression  = "Bearer\\s+(\\S+)"
    replacement = "Bearer ***"
  }

  matchers {
    matcher {
      attribute = "log.source"
      operator  = "MATCHES"
      values    = ["/var/log/checkout/*.log"]
    }
  }
}
```

**Example — OpenPipeline DQL mask processor (illustrative):**

```hcl
resource "dynatrace_openpipeline_v2_logs_pipelines" "pii_mask" {
  display_name = "PII mask pipeline"
  custom_id    = "pipeline_pii_mask"

  processing {
    processors {
      processor {
        type        = "dql"
        id          = "processor_mask_email"
        description = "Mask emails in content"
        matcher     = "true"
        sample_data = "{\"content\":\"contact user@example.com\"}"
        dql {
          script = "fieldsAdd content = replacePattern(content, \"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\\\.[a-zA-Z]{2,}\", \"xxx@xxx.xxx\")"
        }
        enabled = true
      }
    }
  }
}
```

**IaC limits to plan for:**

| Limit | Detail |
| --- | --- |
| Processor ordering | Match UI order when defining multiple processors |
| Testing | Always validate with sample data in UI before relying on Terraform alone |
| Routes | Pipeline without route may never see your logs |
| Classic pipeline | Legacy; migrate to OpenPipeline |
| Sensitive Data Center scans | May not have full Terraform coverage yet — confirm provider version |

Registry: [dynatrace_log_sensitive_data_masking](https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/log_sensitive_data_masking), [dynatrace_openpipeline_v2_logs_pipelines](https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/openpipeline_v2_logs_pipelines)

---

## GDPR and compliance (brief)

| Requirement | Dynatrace-aligned action |
| --- | --- |
| Data minimization | Do not collect logs you do not need (ingest rules plus drop) |
| Purpose limitation | Separate buckets and retention per domain (for example audit vs app debug) |
| Storage limitation | Short retention on verbose debug buckets |
| Security | Mask at capture or ingest; restrict Grail bucket IAM |
| Rights requests | Sensitive Data Center export and deletion workflows |
| Accountability | Document rules; use audit logs and approval workflows for cleanup |

Masking is not retroactive for rules you enable later. Plan cleanup for historical mistakes via [Sensitive Data Center](https://docs.dynatrace.com/docs/manage/data-privacy-and-security/data-privacy/sensitive-data-center).

---

## Common mistakes

| Mistake | Why it hurts | Better approach |
| --- | --- | --- |
| Only masking in dashboards | Raw PII remains in Grail | OpenPipeline or OneAgent masking before storage |
| Over-broad regex | Breaks legitimate logs or misses variants | Test with sample data; scope with matchers |
| Logging bodies by default | Tokens and PII hide in JSON | Structured logging with field denylist |
| Assuming built-in rules are on | Defaults are deactivated in paid envs | Explicitly enable and verify |
| Using SHA-256 for reversible needs | Cannot unmask for support | Use tokenized user IDs in the app instead |
| Dropping all errors with PII words | Loses incident signal | Mask fields, keep event metadata |
| No verification after deploy | Silent rule miss | Query for `@`, `Bearer`, digit patterns post-change |
| Ignoring multi-channel ingest | API logs bypass OneAgent rules | OpenPipeline as centralized backstop |

---

## Verification steps

| Check | How |
| --- | --- |
| Ingest masking applied | New logs show `dt.openpipeline.pipelines` attribute pointing to your pipeline |
| Email no longer raw | Search recent logs for a known test email; expect `xxx@xxx.xxx` or `<masked>` |
| Token not present | `fetch logs` with filter on `Bearer` or `password=` returns zero or masked lines |
| OneAgent capture works | Confirm sensitive substring never appears in Grail for test host |
| Drop rule works | Known dropped phrase absent from Grail after ingest |
| Query-time vs ingest | Re-run same DQL without mask — if raw appears, only query path was changed |
| Scanner (if licensed) | Sensitive Data Center scheduled scan shows declining findings after fix |

See commands in `1.sh`.

---

## Data flow map

```
Application / Pod / Host log file
        │
        ▼
┌───────────────────┐
│ Optional: app     │  strip PII fields, use opaque IDs
│ structured logger │
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│ OneAgent Log      │  Sensitive data masking (regex, built-in CC/email)
│ Module            │  Log ingest rules (include / exclude sources)
└─────────┬─────────┘
          │
    OR    │    Fluent Bit / OTel / Syslog / Log ingest API
          │
          ▼
┌───────────────────┐
│ OpenPipeline      │  Route → Processing stage
│                   │    • Drop record (toxic lines)
│                   │    • Remove fields (password, token)
│                   │    • DQL mask (replacePattern, ipMask)
└─────────┬─────────┘
          │
          ▼
┌───────────────────┐
│ Grail log buckets │  stored (hopefully masked) observability data
└─────────┬─────────┘
          │
          ├────────► DQL notebooks / dashboards (query-time mask for display)
          │
          └────────► Sensitive Data Center (scan → alert → approved cleanup)
```

---

## Related files

| File | Location |
| --- | --- |
| Main answer | `app/Adocs/2026-08-28/1-dynatrace-logs-pii-filter/1-dynatrace-logs-pii-filter.md` |
| Verification commands | `app/Adocs/2026-08-28/1-dynatrace-logs-pii-filter/1.sh` |
| Chat-ready copy | `app/Adocs/2026-08-28/1-dynatrace-logs-pii-filter/1-dynatrace-logs-pii-filter-follow.txt` |

## Commands

Read-only DQL verification one-liners are in `1.sh`. Run them in **Logs and Events → Advanced mode** or a **Notebook** after deploy.


---

# SOURCE: 2-pic main

# Pic Style Answer Workflow

```
need answers that work on desktop + mobile + cloud chat?
  write under Files/<date>/<seq>-<slug>/  AND  app/Adocs/<date>/<seq>-<slug>/
  folder seq? → 1, 2, 3… per question that day
  inside folder docs? → 0-pic → 1-investigation → 2-result → 3-glossary
  commands? → <seq>.sh (one command per line, everything included)
  always? → main md + glossary + follow.txt for mobile copy
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| Primary path | `/Users/k/Work/AIProjects/Files/<YYYY-MM-DD>/<seq>-<slug>/` |
| Mirror path | `P1Gactions/app/Adocs/<YYYY-MM-DD>/<seq>-<slug>/` |
| Question folders | Numbered `1`, `2`, `3`… by ask order that day |
| Inner docs | `0-pic`, `1-investigation`, `2-result`, `3-glossary` |
| This example | Seq **2** · slug **pic-style-answer-workflow** · topic = pic-style workflow |

## Summary

This folder is the live example of the new Cursor answer layout. Pic-style means plain arrow/text flows first. Every question gets investigation + result in the main md, a glossary companion, a command shell file, and a dual write for cloud/local/mobile follow.

## Investigation

| Check | Finding |
|-------|---------|
| Requested path `/Users/ts-shuge.kui/Work/AIProjects/Files` | **Does not exist** on this Mac (no user `ts-shuge.kui`) |
| Actual Files root | `/Users/k/Work/AIProjects/Files` (home user `k`) |
| Adocs today | Already had `1-dynatrace-logs-pii-filter` → this question is **seq 2** |
| Scope | New always-on rule + dual-write example + numbered inner docs |
| Cloud vs local | Same folder content; chat shows full text; `*-follow.txt` for mobile copy |

## Result

| Deliverable | Path |
|-------------|------|
| Main answer | `2-pic-style-answer-workflow.md` (this file) |
| Pic overview | `0-pic.md` |
| Investigation detail | `1-investigation.md` |
| Result detail | `2-result.md` |
| Glossary | `3-glossary.md` |
| Commands | `2.sh` |
| Mobile follow | `2-pic-style-answer-workflow-follow.txt` |
| Files copy | `/Users/k/Work/AIProjects/Files/2026-08-28/2-pic-style-answer-workflow/` |
| Adocs copy | `.../P1Gactions/app/Adocs/2026-08-28/2-pic-style-answer-workflow/` |
| Cursor rule | `/Users/k/.cursor/rules/aiprojects-files-numbered-answers.mdc` |

### Going-forward rule (from now on)

1. One folder per question: `<seq>-<kebab-slug>/` under **today’s date**.
2. Dual-write: **Files** + **app/Adocs** (same date/seq/slug when Adocs seq free; else next free Adocs seq with same slug note).
3. Always create: main `<seq>-<slug>.md`, `<seq>.sh`, `3-glossary.md` (or `<seq>-<slug>-glossary.md`), and preferred `*-follow.txt`.
4. Numbered companions: `0-pic.md`, `1-investigation.md`, `2-result.md`, `3-glossary.md`.
5. Main md always includes **Investigation** + **Result** sections.
6. Chat reply always includes the full useful answer (not path-only), for desktop/mobile/cloud.

## Data flow map (pic style)

```
Question asked (desktop / mobile / cloud Cursor)
  → pick next seq for today (1, 2, 3…)
  → create folder <seq>-<slug>/
  → write
       0-pic.md              (flows / decision tree)
       1-investigation.md    (what was checked)
       2-result.md           (what to do / answer)
       3-glossary.md         (terms)
       <seq>-<slug>.md       (full combined answer)
       <seq>.sh              (all commands, one per line)
       <seq>-<slug>-follow.txt
  → copy same set → app/Adocs/<date>/<seq>-<slug>/
  → show full text in chat
```

## Related files

| File | Role |
|------|------|
| [0-pic.md](0-pic.md) | Pic-style decision + flow |
| [1-investigation.md](1-investigation.md) | Path/seq investigation |
| [2-result.md](2-result.md) | Concrete layout + next steps |
| [3-glossary.md](3-glossary.md) | Terms for this workflow |
| [2.sh](2.sh) | All commands |
| [2-pic-style-answer-workflow-follow.txt](2-pic-style-answer-workflow-follow.txt) | Mobile-ready copy |

## Commands

All commands live in [2.sh](2.sh). Review before running.


---

# SOURCE: 3-generate-all main

# Generate All Files For Today

```
generate all files for today?
  list today's seq folders (Files + Adocs)
  missing 0/1/2/3 companions? → create them
  missing Files copy of Adocs seq? → sync
  this request itself? → new seq folder (3)
  verify? → ls both trees + day index
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| Date | 2026-08-28 |
| Seq 1 | Dynatrace logs PII filter — backfilled companions + Files sync |
| Seq 2 | Pic-style answer workflow — already complete |
| Seq 3 | This request — day completeness pack |
| Dual-write | Files + Adocs for every seq |

## Summary

Today’s answer packs are now complete under both Files and Adocs: each question folder has main md, sh, follow, and numbered `0-pic` / `1-investigation` / `2-result` / `3-glossary` documents.

## Investigation

| Check | Before | After |
|-------|--------|-------|
| Files `1-dynatrace...` | Missing | Present with full set |
| Adocs `1-dynatrace...` companions 0–3 | Missing | Present |
| Seq 2 pic workflow | Complete both sides | Unchanged (complete) |
| Day index | Missing | `0-index-today.md` at date root |
| Path mapping | Present | Refreshed |

## Result

| Seq | Folder | Status |
|-----|--------|--------|
| 1 | `1-dynatrace-logs-pii-filter` | Complete on Files + Adocs |
| 2 | `2-pic-style-answer-workflow` | Complete on Files + Adocs |
| 3 | `3-generate-all-files-today` | Complete on Files + Adocs |

### Required file set per question

```
<seq>-<slug>/
  0-pic.md
  1-investigation.md
  2-result.md
  3-glossary.md
  <seq>-<slug>.md
  <seq>.sh
  <seq>-<slug>-follow.txt
```

## Data flow map

```
Today 2026-08-28
  → seq1 Dynatrace (backfill)
  → seq2 Pic workflow (ok)
  → seq3 Generate-all (this)
  → dual-write Files + Adocs
  → 0-index-today.md lists all
```

## Related files

| File | Role |
|------|------|
| [0-pic.md](0-pic.md) | Pic overview |
| [1-investigation.md](1-investigation.md) | Gaps found |
| [2-result.md](2-result.md) | What was generated |
| [3-glossary.md](3-glossary.md) | Terms |
| [3.sh](3.sh) | Verify commands |
| Day index | `../0-index-today.md` |

## Commands

See [3.sh](3.sh).


---

# SOURCE: agent/1-eks-blueprints-deep-dive/1-eks-blueprints-deep-dive.md

# EKS Blueprints Deep Dive

```
need EKS fast + opinionated?
  copy a pattern? → clone repo → cd patterns/<name> → targeted apply
  reuse as module? → NO — patterns are examples, not modules
  only need cluster? → terraform-aws-eks module directly
  only need addons? → terraform-aws-eks-blueprints-addons
  only need teams/tenancy? → terraform-aws-eks-blueprints-teams
  data workloads? → data-on-eks (sibling project)
  GitOps addons? → patterns/gitops + GitOps Bridge
  destroy stuck? → delete workloads → destroy addons → eks → vpc
  401 on apply? → refresh token or switch to exec() auth
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| What this repo is | A catalog of tested EKS **patterns** (examples), not a Terraform module you call with `source =` |
| What problem it solves | Building a complete EKS cluster with networking, IAM, and operational software takes weeks; blueprints shrink that to days |
| How you use it | Reference the HCL, or copy-paste a pattern and customize locally |
| v5 model | Cluster = `terraform-aws-eks`; addons/teams live in sibling repos; this repo holds patterns only |
| Deploy order | VPC first → EKS second → everything else (targeted `apply`) |
| Destroy order | Workloads/Karpenter nodes first → addons → EKS → VPC |

## Summary

Amazon EKS Blueprints for Terraform is an AWS Solution Architect–maintained collection of ready-to-run EKS cluster recipes. Each folder under `patterns/` shows a full architecture (VPC + EKS + addons + demo pieces) for a specific goal: Karpenter, private clusters, GitOps, GPU/ML, multi-tenancy, and more. You learn from the code or copy it; you do not consume the whole project as one reusable module.

---

## 1. What this is (plain English)

**Amazon EKS** is AWS’s managed Kubernetes control plane. You still must choose networking, node compute, IAM for pods, ingress, secrets, autoscaling, and day-2 tooling.

**EKS Blueprints** answers: “Show me a working, opinionated setup for *this* use case.”

| Term | What it means | Why you care |
|------|---------------|--------------|
| Pattern / blueprint | A complete Terraform example under `patterns/` | Copy or study; deployable as-is for learning |
| Snippet | Smaller reusable idea inside a pattern | Steal pieces (IRSA, subnet tags, Helm values) |
| Supporting module | Separate GitHub/Terraform Registry module | Real reusable building blocks (addons, teams, single addon) |
| Add-on | Software on the cluster (CoreDNS, ALB controller, Karpenter, Argo CD) | Makes the cluster usable for real workloads |

Analogy: Blueprints is a **cookbook** of full meals. The Registry modules are the **ingredients**. Your production repo is the **restaurant kitchen** that adapts recipes.

---

## 2. Why it exists (motivation)

Kubernetes is powerful but choice-heavy. Teams burn months integrating CNI, ingress, autoscaling, secrets, GitOps, and AWS IAM.

Customers asked AWS for **purpose-built, complete clusters** so they can onboard workloads in **days, not months**. Blueprints ships those recipes with testing and docs.

| Without blueprints | With blueprints |
|--------------------|-----------------|
| Design VPC tags for ALB/Karpenter yourself | Pattern already tags subnets correctly |
| Wire OIDC/IRSA for every Helm chart | Addons module / pattern shows the wiring |
| Discover private-cluster VPC endpoints by trial | Fully-private pattern lists required endpoints |
| Guess destroy order and leak ENIs | Docs + pattern READMEs give ordered teardown |

---

## 3. How you are supposed to consume it

There are **two** supported ways:

| Mode | What you do | When to use |
|------|-------------|-------------|
| Reference | Read the pattern; recreate the same ideas in your own Terraform | You already have VPC/cluster standards |
| Copy & paste | Clone, `cd patterns/<name>`, change locals (name, region, CIDR), apply | Learning, PoC, starting point for a new platform |

**Not supported:** treating this repo’s patterns as a Terraform module (`module "blueprints" { source = "..." }`).

Why:

- Patterns barely expose `variables` / `outputs` on purpose
- They use `locals` for name, region, CIDR so examples stay simple
- Publishing them as modules would confuse “example” vs “library”

If you need a different region or cluster name: **edit the pattern locally**, then apply.

---

## 4. Repo layout (what lives where)

```
terraform-aws-eks-blueprints-main/
├── README.md                 # Project pitch, consumption, caveats, related projects
├── docs/                     # MkDocs site source (getting-started, FAQ, v4→v5, pattern pages)
│   ├── getting-started.md
│   ├── faq.md
│   ├── v4-to-v5/             # Migration story and examples
│   └── patterns/             # Doc mirrors of many patterns
├── patterns/                 # ★ All runnable blueprints live here
│   ├── karpenter/
│   ├── fully-private-cluster/
│   ├── gitops/
│   └── ... (~30 pattern areas)
├── .github/                  # CI: plan-examples, e2e, docs publish, pre-commit
└── mkdocs.yml                # Docs site config
```

Important mental model for **v5**:

| Location | Contains modules? | Role |
|----------|-------------------|------|
| This repo (`terraform-aws-eks-blueprints`) | No (patterns only) | Recipes and architecture guidance |
| `terraform-aws-eks` (community) | Yes | Create the EKS cluster |
| `terraform-aws-eks-blueprints-addon` | Yes | One Helm addon + IRSA |
| `terraform-aws-eks-blueprints-addons` | Yes | Bundle of EKS + Helm addons |
| `terraform-aws-eks-blueprints-teams` | Yes | Multi-tenancy (namespaces, RBAC, quotas) |

---

## 5. v4 → v5: the big architectural shift

### What worked in early Blueprints

- Got teams from zero to running clusters quickly (often under 1–2 weeks)
- Popular recipes: Spark on EKS, Karpenter on Fargate, WireGuard+Cilium encryption, serverless Fargate

### What did not scale

| Pain | Why it hurt |
|------|-------------|
| Too many addon variants | CNCF landscape is huge; each chart has many install shapes |
| Terraform managing in-cluster objects | Dependency order fails easily; Terraform does not continuously reconcile like a controller |
| Public API endpoint often required | Terraform “pushes” from outside the VPC |
| Nesting Helm wrappers as modules | Bottleneck to review/test every chart; versioning gets muddy |
| Duplicate cluster modules | `terraform-aws-eks` already existed and Blueprints already used it under the hood |

### What v5 changed

1. **Removed** Blueprints’ own cluster / node-group / Fargate / launch-template / KMS / IRSA / helm-addon / teams / EMR modules from this repo
2. **Point users** at `terraform-aws-eks` for cluster creation
3. **Spin out** addons and teams to dedicated repos
4. **Keep this repo** as the canonical pattern library
5. Prefer **GitOps pull** for many in-cluster installs (Argo CD / GitOps Bridge) over pushing everything from Terraform

### Blueprint vs usage reference

| Type | Focus | Where it lives |
|------|-------|----------------|
| Blueprint | Holistic architecture: security, ops, observability, day-2 | This repo’s `patterns/` |
| Usage reference | “How do I pass this Helm value?” | Addons / Karpenter / other implementation repos |

---

## 6. Related projects (ecosystem map)

| Project | What it is | When you reach for it |
|---------|------------|------------------------|
| [terraform-aws-eks](https://github.com/terraform-aws-modules/terraform-aws-eks) | Community EKS module | Create control plane, MNG, Fargate, Karpenter IAM helpers |
| [terraform-aws-eks-blueprints-addon](https://github.com/aws-ia/terraform-aws-eks-blueprints-addon) | Single Helm release + IRSA | Build one custom addon the Blueprints way |
| [terraform-aws-eks-blueprints-addons](https://github.com/aws-ia/terraform-aws-eks-blueprints-addons) | Many addons together | AWS LB Controller, ExternalDNS, metrics-server, etc. |
| [terraform-aws-eks-blueprints-teams](https://github.com/aws-ia/terraform-aws-eks-blueprints-teams) | Multi-tenancy | Isolate team namespaces and access |
| [terraform-aws-eks-ack-addons](https://github.com/aws-ia/terraform-aws-eks-ack-addons) | ACK controllers on EKS | Manage AWS resources from Kubernetes |
| [crossplane-on-eks](https://github.com/awslabs/crossplane-on-eks) | Crossplane compositions | Provision cloud via K8s XR/XRD |
| [data-on-eks](https://github.com/awslabs/data-on-eks) | Data/AI blueprints | Spark, Ray, Airflow-style data planes |
| [terraform-aws-observability-accelerator](https://github.com/aws-observability/terraform-aws-observability-accelerator) | AMP / AMG / ADOT | Managed observability stack |
| [karpenter-blueprints](https://github.com/aws-samples/karpenter-blueprints) | Karpenter workload scenarios | Deeper NodePool/EC2NodeClass designs |
| GitOps Bridge | IaC metadata → Argo CD | Terraform creates cloud IAM; Argo installs charts |

---

## 7. Step-by-step: deploy any typical pattern

Prerequisites on your laptop:

| Tool | Role |
|------|------|
| `awscli` | Auth to AWS; `eks update-kubeconfig`; (optional) `get-token` for providers |
| `kubectl` | Talk to the cluster after create |
| `terraform` | Plan/apply the pattern |

### Step A — Choose and enter a pattern

```
clone repo → cd patterns/<pattern-name>
```

Example: `patterns/karpenter` for Karpenter on Fargate.

### Step B — Understand the file split (common shape)

Most patterns look like this:

| File | Job |
|------|-----|
| `main.tf` | Providers, versions, `locals` (name, region, CIDR, tags) |
| `vpc.tf` | `terraform-aws-modules/vpc/aws` + subnet tags for ELB/Karpenter |
| `eks.tf` | `terraform-aws-modules/eks/aws` cluster + node/Fargate config |
| `addons.tf` / `karpenter.tf` | Helm releases, blueprints-addons, extra AWS resources |
| `outputs.tf` | Often `configure_kubectl` command |
| `README.md` | Pattern intent, validate steps, destroy notes |

### Step C — Targeted apply (why, then how)

HashiCorp recommends **not** putting computed values into provider blocks. Blueprints still puts `kubernetes` / `helm` / `kubectl` providers in the **same** workspace as the cluster so learners get one folder that works.

To make that safe enough in practice, deploy in stages:

1. Create VPC (network exists)
2. Create EKS (API endpoint + auth exist)
3. Apply the rest (Helm/addons can talk to the API)

See companion commands in [1.sh](1.sh).

### Step D — Wire kubectl

Use the Terraform output (most patterns print something like):

```
aws eks --region <REGION> update-kubeconfig --name <CLUSTER_NAME>
```

Then: `kubectl get nodes`.

**Private clusters:** public endpoint may be off. You must reach the API from inside the VPC (bastion / SSM / PrivateLink pattern). Follow that pattern’s README.

### Step E — Validate

Pattern READMEs usually include:

- `kubectl get nodes`
- `kubectl get pods -A`
- A demo scale-up (for Karpenter: apply `NodePool`, scale a Deployment)

---

## 8. Step-by-step: destroy safely

Wrong destroy order leaves ENIs, security groups, or Karpenter EC2 instances behind.

Recommended flow:

```
1. Delete demo workloads / scale to 0 (esp. Karpenter-created nodes)
2. terraform destroy -target=module.eks_blueprints_addons  (or Helm releases)
3. terraform destroy -target=module.eks
4. terraform destroy   # VPC and leftovers
```

| Risk | What goes wrong | Mitigation |
|------|-----------------|------------|
| Karpenter nodes | Terraform never created those EC2s | Delete apps / NodePools before destroy |
| VPC CNI ENI leak | Subnets/SGs cannot delete | Drain pods → wait → remove CNI-related resources → nodes → cluster |
| Namespace Terminating | Finalizers / orphaned CRDs | List namespaced resources; clear finalizers carefully |
| CloudWatch log group | EKS service recreates log group after TF deletes it | Let EKS own the log group, or delete manually before recreate |

---

## 9. Anatomy deep dive: Karpenter-on-Fargate pattern

This is the textbook v5 pattern. Walk it once and you understand most others.

### Layer 1 — Locals and providers (`main.tf`)

- `local.name` from folder basename (`ex-karpenter`)
- Default region often `us-west-2`
- AWS provider + **alias** `aws.ecr` in `us-east-1` (ECR Public auth for Karpenter chart)
- Helm provider uses `exec { aws eks get-token ... }` against the new cluster

### Layer 2 — VPC (`vpc.tf`)

| Setting | Meaning |
|---------|---------|
| Private + public subnets | Nodes private; NAT for egress; public for internet-facing LBs |
| `kubernetes.io/role/elb = 1` on public | AWS LB Controller finds public subnets |
| `kubernetes.io/role/internal-elb = 1` on private | Internal LBs land correctly |
| `karpenter.sh/discovery = <cluster>` on private | Karpenter discovers which subnets to launch into |
| `single_nat_gateway = true` | Cheaper for demos (not HA prod) |

### Layer 3 — EKS (`eks.tf`)

| Setting | Meaning |
|---------|---------|
| `terraform-aws-modules/eks/aws` ~> 20.x | Official community module |
| `enable_cluster_creator_admin_permissions` | Terraform identity can install Helm |
| `cluster_endpoint_public_access = true` | Laptop Terraform can reach API (demo tradeoff) |
| Fargate profile for `karpenter` namespace | Controller runs serverless; no bootstrap EC2 required |
| CoreDNS often deferred | Comment notes enable after Karpenter nodes exist |
| Tag `karpenter.sh/discovery` on cluster | Discovery for security groups |

### Layer 4 — Karpenter AWS + Helm (`karpenter.tf`)

1. `module "karpenter"` (submodule of terraform-aws-eks): IAM roles, SQS interruption queue, EventBridge
2. `helm_release.karpenter`: chart from `public.ecr.aws/karpenter`, IRSA annotation on ServiceAccount
3. You apply `karpenter.yaml` (`EC2NodeClass` + `NodePool`) after cluster is up
4. Scale a sample Deployment → Karpenter launches EC2 → pods schedule

### Data path for a pending pod (this pattern)

```
Pending pod
  → kube-scheduler cannot place (no EC2 yet)
  → Karpenter watches unschedulable pods
  → matches NodePool requirements
  → EC2NodeClass → RunInstances in tagged private subnets
  → node joins cluster
  → pod binds and runs
  → scale to 0 → Karpenter terminates empty node
```

---

## 10. Complete pattern catalog (grouped)

### Compute and autoscaling

| Pattern folder | What it teaches |
|----------------|-----------------|
| `karpenter` | Karpenter controller on **Fargate**; EC2 nodes on demand |
| `karpenter-mng` | Karpenter alongside **managed node groups** |
| `fargate-serverless` | Fully serverless data plane + Fargate logging |
| `bottlerocket` | Bottlerocket OS + Bottlerocket Update Operator + Karpenter resources |
| `eks-automode` | EKS Auto Mode / custom node pools |
| `targeted-odcr` | On-Demand Capacity Reservations targeting |
| `ml-capacity-block` | ML Capacity Block Reservation |

### Networking and connectivity

| Pattern folder | What it teaches |
|----------------|-----------------|
| `fully-private-cluster` | No internet; required VPC interface/gateway endpoints |
| `privatelink-access` | Reach private EKS API via PrivateLink |
| `private-public-ingress` | Mix of private and public ingress |
| `ipv6-eks-cluster` | Dual-stack / IPv6 cluster networking |
| `aws-vpc-cni-network-policy` | NetworkPolicy with VPC CNI |
| `wireguard-with-cilium` | Transparent encryption (Cilium + WireGuard) |
| `vpc-lattice` | VPC Lattice client/server and cross-cluster pod communication |
| `istio` | Service mesh on EKS |

### Security, identity, secrets, TLS

| Pattern folder | What it teaches |
|----------------|-----------------|
| `external-secrets` | External Secrets Operator pulling from AWS |
| `tls-with-aws-pca-issuer` | cert-manager + AWS Private CA issuer |
| `sso-iam-identity-center` | IAM Identity Center SSO + Cluster Access Manager |
| `sso-okta` | Okta SSO into EKS |
| `multi-tenancy-with-teams` | `team-red` / `team-blue` / admin isolation via teams module |
| `ecr-pull-through-cache` | ECR pull-through cache for upstream registries |

### GitOps and cluster lifecycle

| Pattern folder | What it teaches |
|----------------|-----------------|
| `gitops/getting-started-argocd` | GitOps Bridge: Terraform metadata → Argo CD ApplicationSets |
| `gitops/multi-cluster-hub-spoke-argocd` | Hub-and-spoke multi-cluster Argo CD |
| `blue-green-upgrade` | Blue/green EKS migration with Route53 weighted DNS |

### Workloads: games, stateful, cost, ML

| Pattern folder | What it teaches |
|----------------|-----------------|
| `agones-game-controller` | Agones for game servers on EKS |
| `stateful` | Stateful workload considerations on EKS |
| `kubecost` | Kubecost + AWS billing integration |
| `nvidia-gpu-efa` | NVIDIA GPU + Elastic Fabric Adapter |
| `aws-neuron-efa` | AWS Neuron accelerators + EFA |
| `multi-node-vllm` | Multi-node LLM inference with vLLM |
| `ml-container-cache` | Cache large ML images for faster cold start |

---

## 11. GitOps Bridge (important mental model)

Problem: many addons need **AWS resources** (IAM roles, ACM, Route53) created by Terraform, but installing Helm from Terraform has ordering and security downsides.

**GitOps Bridge** pattern:

```
Terraform creates:
  VPC, EKS, IAM roles for addons, maybe ACM/DNS pieces
  → writes metadata into an Argo CD cluster Secret (annotations)

Argo CD (inside cluster) pulls:
  ApplicationSets from eks-blueprints-add-ons (or your fork)
  → reads metadata (role ARNs, account id, cluster name)
  → installs Helm charts with correct values
```

Why it matters:

- Cloud IAM stays in Terraform (good fit)
- Chart install becomes **pull-based** (better security for private clusters)
- Platform team controls migration/weights (see blue-green pattern) without rewriting app CD pipelines

---

## 12. Blue/green upgrade pattern (lifecycle deep dive)

High-level pieces:

| Stack | Creates |
|-------|---------|
| `environment` | Shared VPC, Route53 subdomain, ACM wildcard, Argo UI secret |
| `eks-blue` | First EKS + Argo + workloads |
| `eks-green` | Second EKS + same GitOps apps |
| Shared DNS | ExternalDNS on both → **weighted** Route53 records |

Migration idea:

```
weight blue=100 green=0  →  shift green up  →  blue=0 green=100  →  decommission blue
```

Platform team can move traffic without asking every app team to cut over manually.

---

## 13. Fully private cluster checklist

If the cluster has **no internet egress / no public API**, you typically need VPC endpoints such as:

| Endpoint | Used for |
|----------|----------|
| `ecr.api` / `ecr.dkr` | Pull images |
| `ec2` | Node/ENI operations |
| `sts` | IRSA / Fargate credentials |
| `logs` | CloudWatch Logs |
| `elasticloadbalancing` | AWS Load Balancer Controller |
| `autoscaling` | Cluster Autoscaler (if used) |
| `s3` | Often required by ECR layers and other flows |
| `ssm` | Session Manager / secrets patterns |
| `aps-workspaces` | Amazon Managed Prometheus (if used) |

Nodes still need **private endpoint access** so the kubelet can register.

---

## 14. Terraform caveats Blueprints wants you to know

| Caveat | Plain English | Practical advice |
|--------|---------------|------------------|
| VPC included in every pattern | Real orgs usually have a shared VPC workspace | Keep for demos; in prod, pass an existing VPC |
| One workspace for cluster + addons | Violates HashiCorp “no computed provider config” ideal | Use targeted apply; later split workspaces |
| Not a module | No rich variables/outputs | Fork/copy and edit `locals` |
| Static token vs `exec()` | Token lasts ~15 minutes; `exec` needs awscli | Prefer `exec` for longer applies; refresh if 401 |

### Provider auth (two options)

| Method | Pros | Cons |
|--------|------|------|
| Static `aws_eks_cluster_auth` token | Simple | Expires (~15 min) → `401` mid-apply |
| `exec { aws eks get-token }` | Fresh token each call | Needs awscli + matching client auth API version |

---

## 15. FAQ troubleshooting map

| Symptom | Likely cause | What to do |
|---------|--------------|------------|
| `terraform destroy` hangs on VPC | ENIs left by VPC CNI | Delete pods → wait → remove CNI → nodes → cluster |
| Recreate fails on CloudWatch log group | EKS recreated log group after TF deleted it | Delete log group manually, or let EKS own creation |
| Helm/K8s provider `401` | Static token expired | `terraform refresh` or switch to `exec` |
| Namespace stuck `Terminating` | Finalizers / orphan CRD objects | List resources in ns; patch finalizers if safe |
| Karpenter nodes remain after destroy | Not in Terraform state | Delete workloads/NodePools first |
| Cannot kubectl to private cluster | No path to private API | Use bastion/SSM/PrivateLink pattern |

---

## 16. How a production team should adopt Blueprints (recommended path)

Do **not** run the GitHub pattern folder forever in prod.

Suggested journey:

```
1. Pick 1–2 patterns closest to your need (e.g. karpenter-mng + external-secrets)
2. Deploy in a sandbox account; break it on purpose; practice destroy
3. Extract ideas into YOUR modules:
     network/  → existing VPC standards
     cluster/  → terraform-aws-eks wrapper
     addons/   → blueprints-addons or Argo ApplicationSets
     teams/    → blueprints-teams
4. Split state: VPC | cluster | GitOps bootstrap | app workloads
5. Add remote state (S3 + lock), CI plan on PR, OIDC for GitHub Actions
6. Define SLOs, ingress, backup, and upgrade strategy (blue-green pattern helps)
```

| Stage | Good outcome |
|-------|--------------|
| Week 1 | Sandbox cluster from a pattern; team can kubectl |
| Week 2–3 | Own module layout; IRSA for critical controllers |
| Week 4+ | GitOps for addons/apps; CI plan; private networking hardening |

---

## 17. Interview-ready one-liners

| Question | Strong answer |
|----------|---------------|
| What is EKS Blueprints? | A pattern library for complete EKS architectures in Terraform, not a cluster module |
| How do you consume it? | Reference or copy-paste; customize locals; do not `module.source` the patterns |
| What changed in v5? | Cluster/addons/teams extracted; this repo is examples only |
| Why targeted apply? | Cluster endpoint must exist before Helm providers can install charts in the same root module |
| Terraform vs GitOps for addons? | TF for cloud IAM/network; GitOps pull for charts—especially private clusters |
| Karpenter + Fargate pattern? | Run Karpenter controller on Fargate; let it create EC2 for workloads |

---

## Data flow map

```
Developer laptop
  │
  │ terraform init / targeted apply
  ▼
AWS account
  │
  ├─► VPC module
  │     public subnets (ELB tags)
  │     private subnets (internal-ELB + karpenter discovery tags)
  │     NAT (+ optional VPC endpoints for private patterns)
  │
  ├─► EKS module (terraform-aws-eks)
  │     control plane
  │     OIDC provider (IRSA / Pod Identity)
  │     Fargate profile and/or MNG and/or Auto Mode
  │     cluster addons: vpc-cni, kube-proxy, (coredns), pod-identity-agent
  │
  ├─► AWS side for controllers
  │     IAM roles, SQS (Karpenter), policies for ALB/ExternalDNS/...
  │
  └─► In-cluster install path (one of)
        A) Terraform helm_release / blueprints-addons  (push)
        B) Argo CD + GitOps Bridge metadata secret     (pull)
              │
              ▼
        Controllers running (Karpenter, LBC, External Secrets, ...)
              │
              ▼
        Workloads schedule → nodes scale → ingress/DNS/secrets wire up
```

GitOps Bridge detail:

```
Terraform (IAM role ARNs, cluster name, repo URLs)
    → Kubernetes Secret (Argo cluster annotations)
        → ApplicationSet templates
            → Helm installs with correct IRSA role per addon
```

Blue/green traffic:

```
User → Route53 weighted record
          ├─ weight N → ALB on blue cluster → app pods
          └─ weight M → ALB on green cluster → app pods
```

---

## Related files

| File | Purpose |
|------|---------|
| [1.sh](1.sh) | Deploy, kubeconfig, validate, and destroy one-liners |
| Repo `README.md` | Official consumption model and related projects |
| `docs/getting-started.md` | Canonical apply/destroy order |
| `docs/faq.md` | Token auth, ENI leaks, log groups, stuck namespaces |
| `docs/v4-to-v5/motivation.md` | Why the project was restructured |
| `patterns/karpenter/` | Best first pattern to study end-to-end |
| `patterns/gitops/getting-started-argocd/` | GitOps Bridge starter |
| `patterns/blue-green-upgrade/` | Multi-cluster migration with weighted DNS |

## Commands

All commands are one-liners in [1.sh](1.sh). Review them before running; do not apply in a shared account without checking region, name, and cost.


---

# SOURCE: agent/3-eks-blueprints-patterns-file-dive/3-eks-blueprints-patterns-file-dive.md

# EKS Blueprints Patterns File Dive

```
need pattern details
  → pick pattern folder under patterns/
  → read every non-image file
  → map providers → VPC/EKS → addons/workloads
  → note notable HCL/YAML keys + how files connect
```

| Question | Answer |
|---|---|
| Scope | 20 small pattern folders in terraform-aws-eks-blueprints |
| Source path | `/Users/k/Codes/GithubProjects/Terraform/terraform-aws-eks-blueprints-main/patterns/` |
| Artifact type | File-by-file deep dive from actual contents |

## Summary

This document inventories every non-image file across 20 EKS Blueprints pattern folders. Each pattern section lists what each file is, what it contains, how it connects, and notable settings.

## Main Content

## aws-neuron-efa

### main.tf
- **What it is:** Terraform bootstrap for providers, locals, VPC, and kubectl helper output.
- **What it contains:** `aws` + `aws.ecr` (us-east-1) + `helm` providers; AZ data; VPC module `~> 5.0`; `configure_kubectl` output.
- **Why it matters:** Foundation for Neuron/EFA cluster; ECR alias needed for Public ECR Helm charts in `helm.tf`.
- **Notable settings:**
  - `region = "us-east-2"`
  - `vpc_cidr = "10.0.0.0/16"`, 3 AZs, single NAT
  - Helm auth via `aws eks get-token`

### eks.tf
- **What it is:** EKS cluster and managed node groups for Trainium + EFA.
- **What it contains:** `terraform-aws-modules/eks/aws` `~> 20.34`; addons; `neuron-efa` + `default` MNGs.
- **Why it matters:** Core of the pattern — Trainium nodes with EFA, placement, RAID0, taints/labels.
- **Notable settings:**
  - `cluster_version = "1.32"`, `enable_efa_support = true`
  - `ami_type = "AL2023_x86_64_NEURON"`, `trn1.32xlarge`, size 2/2/2
  - Labels `vpc.amazonaws.com/efa.present`, `aws.amazon.com/neuron.present`
  - Taint `aws.amazon.com/neuron=true:NoSchedule`
  - NodeConfig `localStorage.strategy: RAID0`

### helm.tf
- **What it is:** Device plugin Helm releases for Neuron and EFA.
- **What it contains:** Public ECR token data; `neuron-helm-chart` 1.1.1; `aws-efa-k8s-device-plugin` v0.5.7.
- **Why it matters:** Exposes Neuron devices and EFA NICs to pods that request them.
- **Notable settings:**
  - Neuron: `nodeSelector.aws.amazon.com/neuron.present`, `npd.enabled: false`
  - EFA: `nodeSelector.vpc.amazonaws.com/efa.present` + neuron toleration

### README.md
- **What it is:** Pattern docs (deploy/validate/destroy).
- **What it contains:** Architecture narrative; embed refs to `eks.tf`/`helm.tf`; kubectl validation sample.
- **Why it matters:** Explains why default MNG exists and why EFA is not separately tainted.
- **Notable settings:** Docs highlight EFA x8, placement group, RAID0, dual device plugins.

---

## ml-capacity-block

### main.tf
- **What it is:** Providers, locals, VPC, kubectl output for capacity-block GPU pattern.
- **What it contains:** `aws` + `helm`; VPC `~> 5.0`; region `us-west-2`.
- **Why it matters:** Shared infra for CBR-backed GPU MNG in `eks.tf`.
- **Notable settings:** `region = "us-west-2"`, single NAT, private subnets for EKS.

### eks.tf
- **What it is:** EKS + MNG wired to an ML Capacity Block Reservation.
- **What it contains:** Required `capacity_reservation_id` variable; EKS `~> 20.34`; `cbr` + `default` MNGs.
- **Why it matters:** Shows exact CBR knobs: AZ-pinned subnet, `CAPACITY_BLOCK`, market options, reservation target.
- **Notable settings:**
  - `ami_type = "AL2023_x86_64_NVIDIA"`, `p5e.48xlarge`
  - `capacity_type = "CAPACITY_BLOCK"`
  - `instance_market_options.market_type = "capacity-block"`
  - `capacity_reservation_id = var.capacity_reservation_id`
  - `subnet_ids = [element(private_subnets, 0)]` (AZ match TODO)
  - GPU taint + EFA/GPU labels + RAID0 + `enable_efa_support`

### helm.tf
- **What it is:** NVIDIA + EFA device plugins.
- **What it contains:** nvidia-device-plugin 0.17.1; aws-efa-k8s-device-plugin v0.5.7 with GPU toleration.
- **Why it matters:** Completes GPU/EFA scheduling stack on CBR nodes.
- **Notable settings:** EFA `nodeSelector` + `nvidia.com/gpu` toleration.

### README.md
- **What it is:** CBR usage docs with three required components.
- **What it contains:** AZ restriction, LT reservation args, `capacity_type = CAPACITY_BLOCK`.
- **Why it matters:** Explains common AZ mismatch failures.
- **Notable settings:** Links to EKS/EC2 capacity blocks docs.

---

## wireguard-with-cilium

### main.tf
- **What it is:** Providers + VPC only (cluster lives in `eks.tf`).
- **What it contains:** `aws` + `helm`; VPC `~> 5.0`; `us-west-2`.
- **Why it matters:** Network base for Cilium WireGuard encryption.
- **Notable settings:** Standard public/private + single NAT.

### eks.tf
- **What it is:** EKS cluster, UDP 51871 SG rule, and Cilium Helm via blueprints-addons.
- **What it contains:** EKS `~> 20.11` (1.30); MNG `m5.large`; `eks_blueprints_addons` with Cilium 1.14.1; kubectl output.
- **Why it matters:** Entire Cilium + WireGuard config lives here.
- **Notable settings:**
  - `node_security_group_additional_rules.ingress_cilium_wireguard` UDP 51871 self
  - Cilium: `cni.chainingMode: aws-cni`, `enableIPv4Masquerade: false`, `tunnel: disabled`
  - `endpointRoutes.enabled: true`, `l7Proxy: false`
  - `encryption.enabled: true`, `encryption.type: wireguard`

### example.yaml
- **What it is:** Optional client/server pods to demo encrypted traffic.
- **What it contains:** nginx `server` pod+Service; busybox `client` with `watch wget`; topology spread.
- **Why it matters:** Used with tcpdump on `cilium_wg0` in README validate steps.
- **Notable settings:** Labels `blog: wireguard`; Service `sessionAffinity: ClientIP`.

### README.md
- **What it is:** Deploy/validate guide for WireGuard encryption.
- **What it contains:** Focal points; `cilium status` Encryption field; tcpdump + connectivity-check steps.
- **Why it matters:** Shows expected `Encryption: Wireguard` and NodeEncryption Disabled.
- **Notable settings:** Requires Linux kernel 5.10+.

---

## external-secrets

### versions.tf
- **What it is:** Terraform/provider version constraints.
- **What it contains:** TF `>= 1.3`; aws; helm; `alekc/kubectl >= 2.0`.
- **Why it matters:** Enables kubectl manifests for ESO CRDs.
- **Notable settings:** Commented S3 backend for e2e.

### main.tf
- **What it is:** Full pattern: cluster, ESO, Secrets Manager + Parameter Store demos, IRSA.
- **What it contains:** Providers (aws/helm/kubectl); EKS; blueprints-addons with `enable_external_secrets`; KMS; ClusterSecretStore/SecretStore/ExternalSecrets; IAM roles/policies; EBS CSI IRSA.
- **Why it matters:** End-to-end External Secrets Operator wiring to AWS secret backends.
- **Notable settings:**
  - `enable_external_secrets = true`
  - ClusterSecretStore → SecretsManager; SecretStore → ParameterStore
  - Sample secrets username/password JSON
  - IRSA policies scoped to secret ARN / SSM path `/${local.name}/*`
  - Note: `secretstore_role` OIDC SA list uses `cluster_secretstore_sa` (same as cluster role), not `secretstore_sa`

### outputs.tf
- **What it is:** kubectl config helper.
- **What it contains:** `configure_kubectl` using region + cluster name.
- **Why it matters:** Post-apply access.
- **Notable settings:** `aws eks --region ${local.region} update-kubeconfig --name ...`

### README.md
- **What it is:** Short pattern overview + validate.
- **What it contains:** Deploy link; `kubectl get externalsecrets/secrets -n external-secrets`.
- **Why it matters:** Confirms both stores and secrets land in `external-secrets` ns.
- **Notable settings:** Namespace `external-secrets`.

---

## fargate-serverless

### versions.tf
- **What it is:** Provider constraints for Fargate pattern.
- **What it contains:** aws, helm, kubernetes `>= 2.20`.
- **Why it matters:** Kubernetes provider used for sample app.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** Fargate-only EKS + addons + 2048 sample app.
- **What it contains:** EKS Fargate profiles; blueprints-addons (CoreDNS Fargate sizing, Fluent Bit, ALB controller); VPC; Deployment/Service for `app-2048`.
- **Why it matters:** Shows serverless data plane patterns and Fargate-specific CoreDNS/logging.
- **Notable settings:**
  - Profiles: `app-*` and `kube-system`
  - `create_cluster_security_group/create_node_security_group = false`
  - CoreDNS `computeType = Fargate`, cpu/memory `0.25` / `256M`
  - `enable_fargate_fluentbit = true`, `flb_log_cw = true`
  - ALB controller with `vpcId` set
  - App toleration `eks.amazonaws.com/compute-type=fargate`

### outputs.tf
- **What it is:** kubectl helper output.
- **What it contains:** `configure_kubectl`.
- **Why it matters:** Cluster access after apply.
- **Notable settings:** Region-scoped update-kubeconfig.

### README.md
- **What it is:** Validate Fargate nodes, Fluent Bit CW logs, ALB ingress example.
- **What it contains:** Sample outputs; ingress create annotations; destroy partial.
- **Why it matters:** Operational checklist for serverless cluster.
- **Notable settings:** Ingress class `alb`, scheme internet-facing, target-type ip.

---

## fully-private-cluster

### versions.tf
- **What it is:** Minimal provider set (AWS only).
- **What it contains:** aws `>= 5.34, < 6.0`.
- **Why it matters:** No Helm/K8s providers — infra-only private cluster.
- **Notable settings:** Commented e2e backend.

### main.tf
- **What it is:** Private VPC (no NAT/public) + VPC endpoints + private EKS.
- **What it contains:** EKS `~> 20.11` with private subnets only; VPC without public subnets/`enable_nat_gateway = false`; Interface+Gateway endpoints.
- **Why it matters:** Demonstrates air-gapped-style cluster dependency on VPC endpoints.
- **Notable settings:**
  - No `cluster_endpoint_public_access = true` (module default private)
  - Endpoints: s3 gateway + autoscaling, ecr.api/dkr, ec2, ec2messages, elb, sts, kms, logs, ssm, ssmmessages
  - Endpoint SG allows HTTPS from VPC CIDR

### outputs.tf
- **What it is:** kubectl config tip (assumes reachable private API).
- **What it contains:** `configure_kubectl`.
- **Why it matters:** Access requires network path into VPC (VPN/Direct Connect/bastion).
- **Notable settings:** Same update-kubeconfig pattern as other patterns.

### README.md
- **What it is:** Private cluster requirements and endpoint list.
- **What it contains:** Required VPC endpoints list; validate nodes/pods; destroy.
- **Why it matters:** Documents why endpoints exist and extra ones (APS, etc.).
- **Notable settings:** Mentions private endpoint access for node registration.

---

## ipv6-eks-cluster

### versions.tf
- **What it is:** AWS provider pin for IPv6 pattern (module v21 era).
- **What it contains:** aws `>= 6.0`.
- **Why it matters:** Matches VPC/EKS module major upgrades used below.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** Dual-stack VPC + IPv6 EKS cluster.
- **What it contains:** EKS module `~> 21.0.7` with `ip_family = "ipv6"`; VPC `~> 6.0.1` with IPv6 prefixes and egress-only IGW.
- **Why it matters:** Shows IPv6 cluster + subnet IPv6 assignment knobs.
- **Notable settings:**
  - `ip_family = "ipv6"`, `create_cni_ipv6_iam_policy = true`
  - `kubernetes_version = "1.33"`, `endpoint_public_access = true`
  - `enable_ipv6`, `create_egress_only_igw = true`
  - Public prefixes `[0,1,2]`, private `[3,4,5]`, `private_subnet_enable_dns64 = false`

### outputs.tf
- **What it is:** kubectl helper.
- **What it contains:** `configure_kubectl` referencing `module.eks.cluster_name`.
- **Why it matters:** Post-deploy access.
- **Notable settings:** Region `us-west-2`.

### README.md
- **What it is:** Validate pods/nodes show IPv6 addresses.
- **What it contains:** `kubectl get pods/nodes -o wide` sample IPv6 INTERNAL-IP.
- **Why it matters:** Success criteria for the pattern.
- **Notable settings:** Expect pod IPs like `2600:1f13:...`.

---

## istio

### versions.tf
- **What it is:** Provider constraints for Istio pattern.
- **What it contains:** aws, helm, kubernetes.
- **Why it matters:** Helm installs Istio charts; kubernetes creates namespace.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** EKS + Istio base/istiod/gateway Helm + ALB controller + SG rules.
- **What it contains:** EKS with ports 15017/15012; `istio-system` ns; blueprints-addons Helm releases for base/istiod/gateway; VPC.
- **Why it matters:** Full mesh control plane + internet-facing NLB ingress gateway.
- **Notable settings:**
  - Istio charts `1.20.2` from `istio-release.storage.googleapis.com`
  - `meshConfig.accessLogFile = /dev/stdout`
  - Gateway annotations: NLB external, target-type ip, internet-facing, cross-zone
  - Label `istio = ingressgateway`
  - `enable_aws_load_balancer_controller = true`

### outputs.tf
- **What it is:** kubectl helper.
- **What it contains:** `configure_kubectl`.
- **Why it matters:** Access for validate/rollout restart.
- **Notable settings:** Standard update-kubeconfig.

### README.md
- **What it is:** Deploy, observability addons, helloworld validate, destroy caveats.
- **What it contains:** `kubectl rollout restart` for istiod dependency; Kiali/Jaeger/Prometheus/Grafana; sample apps; destroy targeting istio-ingress first.
- **Why it matters:** Documents known Istio/ALB destroy race and ingress restart need.
- **Notable settings:** Observability from Istio release-1.20 samples.

---

## multi-tenancy-with-teams

### versions.tf
- **What it is:** Provider pin (aws + kubernetes).
- **What it contains:** No helm.
- **Why it matters:** Teams module uses kubernetes resources.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** EKS with aws-auth managed by teams modules (admin + red/blue).
- **What it contains:** EKS `~> 19.21`; `eks-blueprints-teams` admin + for_each red/blue; VPC; kubernetes provider via `aws_eks_cluster_auth` token.
- **Why it matters:** Namespace isolation with quotas/limit ranges and IAM/aws-auth roles per team.
- **Notable settings:**
  - `manage_aws_auth_configmap = true`
  - Admin: `enable_admin = true`, users = caller ARN
  - Dev teams: namespaces `team-red`/`team-blue` with CPU/mem/pod quotas and LimitRanges
  - Cluster version `1.29`

### outputs.tf
- **What it is:** Per-team kubeconfig role ARN helpers.
- **What it contains:** Admin + list of dev team `update-kubeconfig --role-arn` commands.
- **Why it matters:** Shows how each tenant assumes its IAM role.
- **Notable settings:** Role ARNs from teams modules.

### README.md
- **What it is:** High-level tenancy description (TODO validate).
- **What it contains:** team-red/blue + admin overview.
- **Why it matters:** Intent statement for the pattern.
- **Notable settings:** Validation section marked TODO.

---

## private-public-ingress

### versions.tf
- **What it is:** aws + helm constraints.
- **What it contains:** No kubernetes provider (ingress via Helm addons only).
- **Why it matters:** Two ingress-nginx Helm installs.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** Bottlerocket EKS + dual ingress-nginx (external/internal) + ALB controller.
- **What it contains:** Two SGs; two `eks_blueprints_addons` modules for nginx; third for ALB controller 1.6.0; VPC.
- **Why it matters:** Split public vs private ingress classes with dedicated NLBs/SGs.
- **Notable settings:**
  - AMI `BOTTLEROCKET_x86_64`, 3 nodes
  - External: scheme `internet-facing`, SG open 80/443 to `0.0.0.0/0`
  - Internal: scheme `internal`, SG limited to VPC CIDR
  - Classes `ingress-nginx-external` / `ingress-nginx-internal`
  - `loadBalancerClass: service.k8s.aws/nlb`, topology spread, minAvailable 2

### outputs.tf
- **What it is:** kubectl helper with alias.
- **What it contains:** `update-kubeconfig --alias`.
- **Why it matters:** Convenience naming for multi-cluster local configs.
- **Notable settings:** Alias = cluster name.

### README.md
- **What it is:** Explains dual controllers + ingressClassName usage.
- **What it contains:** Deploy; TODO validate; destroy.
- **Why it matters:** How apps choose public vs private ingress.
- **Notable settings:** Set `ingressClassName` to external or internal class.

---

## stateful

### versions.tf
- **What it is:** aws/helm/kubernetes providers.
- **What it contains:** Needed for storage classes + addons.
- **Why it matters:** Stateful storage CRDs managed by kubernetes provider.
- **Notable settings:** TF `>= 1.3`.

### main.tf
- **What it is:** Stateful-focused EKS: multi-volume + instance-store MNGs, Velero, EFS/EBS CSI, storage classes, KMS.
- **What it contains:** Two MNGs with custom block devices/user data; blueprints-addons; gp2 annotate / gp3+efs StorageClasses; S3 backup bucket; EFS; EBS KMS; EBS CSI IRSA.
- **Why it matters:** Reference for PV/storage best practices and node disk layout.
- **Notable settings:**
  - `multi-volume`: `/dev/xvdb` 24Gi gp3 encrypted; shell mounts containerd dirs
  - `instance-store`: `m5ad.large` + NodeConfig RAID0
  - Velero `s3_backup_location`; `enable_aws_efs_csi_driver`
  - gp3 default SC; efs SC `provisioningMode=efs-ap`
  - SSM policy on nodes for validation

### outputs.tf
- **What it is:** kubectl + Velero location outputs.
- **What it contains:** `configure_kubectl`, `velero_s3_backup_location`.
- **Why it matters:** Points operators at backup bucket path.
- **Notable settings:** Location = bucket ARN + `/backups`.

### README.md
- **What it is:** Feature guide for Velero, CSI, multi-volume, instance store.
- **What it contains:** Validate SC list, nvme-cli checks, velero CLI location.
- **Why it matters:** How to verify containerd on second volume and NVMe mounts.
- **Notable settings:** Expect `gp3 (default)`, `efs`, `gp2` present.

---

## tls-with-aws-pca-issuer

### versions.tf
- **What it is:** aws/helm/kubectl constraints.
- **What it contains:** kubectl for AWSPCAClusterIssuer + Certificate CRDs.
- **Why it matters:** Works around kubernetes provider CRD issue (#1453).
- **Notable settings:** `alekc/kubectl >= 2.0`.

### variables.tf
- **What it is:** Certificate naming inputs.
- **What it contains:** `certificate_name` default `example`; `certificate_dns` default `example.com`.
- **Why it matters:** Feeds PCA subject CN and Certificate resource.
- **Notable settings:** Both strings with defaults.

### main.tf
- **What it is:** EKS + cert-manager + AWS Private CA issuer + sample Certificate.
- **What it contains:** Root ACM PCA + self-signed cert association; blueprints-addons (`enable_cert_manager`, `enable_aws_privateca_issuer`); cert-manager-csi-driver Helm; kubectl manifests.
- **Why it matters:** Private TLS issued into K8s Secret via PCA.
- **Notable settings:**
  - PCA: ROOT, RSA_4096, SHA512WITHRSA, validity 10 years
  - Issuer `AWSPCAClusterIssuer` named as cluster name
  - Certificate duration `2160h`, renewBefore `360h`, RSA 2048
  - Secret name `${certificate_name}-clusterissuer`

### outputs.tf
- **What it is:** kubectl helper.
- **What it contains:** `configure_kubectl`.
- **Why it matters:** Validate Ready Certificate/Secret.
- **Notable settings:** Standard.

### README.md
- **What it is:** Validate PCA issuer pods and Certificate Ready state.
- **What it contains:** Expected secret `example-clusterissuer` type `kubernetes.io/tls`.
- **Why it matters:** Success criteria for TLS issuance.
- **Notable settings:** Namespaces `aws-privateca-issuer`, `cert-manager`.

---

## sso-okta

### versions.tf
- **What it is:** aws + okta + kubernetes providers.
- **What it contains:** `okta/okta ~> 4.1.0`.
- **Why it matters:** Provisions IdP side + K8s RBAC bindings.
- **Notable settings:** TF `>= 1.3`.

### variables.tf
- **What it is:** Admin/developer user lists for Okta.
- **What it contains:** Objects with first/last/email; defaults for admin + 2 users.
- **Why it matters:** Drives Okta user/group membership creation.
- **Notable settings:** Default emails `@example.com`.

### main.tf
- **What it is:** EKS with Okta OIDC identity provider + VPC.
- **What it contains:** `cluster_identity_providers.okta` wired to Okta auth server/app; MNG; VPC.
- **Why it matters:** Connects EKS OIDC auth to Okta issuer/client.
- **Notable settings:**
  - `username_claim = "email"`, `groups_claim = "groups"`
  - issuer/client from `okta_auth_server.eks` / `okta_app_oauth.eks`
  - Cluster `1.30`

### okta.tf
- **What it is:** Okta IdP resources + K8s ClusterRoleBindings.
- **What it contains:** Okta provider placeholders; users/groups; OAuth app; auth server/claims/policy; RBAC for `eks-operators`→cluster-admin and `eks-developers`→view.
- **Why it matters:** Full SSO authN (Okta) + authZ (RBAC groups).
- **Notable settings:**
  - Groups claim filter `STARTS_WITH eks-`
  - App type native, PKCE, redirect `http://localhost:8000`
  - Provider placeholders `dev-<ORG_ID>` and `<OKTA_APU_TOKEN>`

### outputs.tf
- **What it is:** kubectl + oidc-login setup helpers.
- **What it contains:** `configure_kubectl`, `okta_login`, `configure_kubeconfig` exec-credential block.
- **Why it matters:** Client-side OIDC login wiring after apply.
- **Notable settings:** Uses `kubectl oidc-login` with issuer + client id.

### README.md
- **What it is:** Activate users, configure kubeconfig, role differences.
- **What it contains:** Browser auth flow; admin vs viewer groups.
- **Why it matters:** Operational SSO usage after Terraform.
- **Notable settings:** Mentions GuardDuty agents in sample output (illustrative).

---

## targeted-odcr

### main.tf
- **What it is:** Providers, locals, VPC, kubectl output for ODCR pattern.
- **What it contains:** aws/helm; VPC; `us-west-2`.
- **Why it matters:** Base for ODCR GPU MNG in `eks.tf`.
- **Notable settings:** Standard 3-AZ VPC.

### eks.tf
- **What it is:** EKS MNG targeting a Capacity Reservation resource group + ODCR resource group resources.
- **What it contains:** `capacity_reservation_arns` var; EKS; `odcr` + `default` MNGs; `aws_resourcegroups_group` CapacityReservationPool; group memberships.
- **Why it matters:** Shows targeted ODCR via resource group ARN (add/remove capacity without LT rewrite).
- **Notable settings:**
  - `p5.48xlarge`, NVIDIA AMI, EFA, RAID0, GPU taint
  - `capacity_reservation_resource_group_arn = aws_resourcegroups_group.odcr.arn`
  - AZ-pinned first private subnet
  - Duplicate min/max/desired blocks (2/2/2 then 4/5/2 — last wins in HCL)

### helm.tf
- **What it is:** NVIDIA + EFA device plugins (same pattern as CBR/GPU).
- **What it contains:** nvidia 0.17.1; efa v0.5.7 with GPU toleration.
- **Why it matters:** Device exposure for ODCR GPU nodes.
- **Notable settings:** EFA nodeSelector + nvidia toleration.

### README.md
- **What it is:** Three-component ODCR recipe + console validation (images skipped).
- **What it contains:** AZ pin, LT reservation spec, resource group container model.
- **Why it matters:** Explains why resource groups allow capacity changes without node group disruption.
- **Notable settings:** Links to EC2 ODCR tutorials.

---

## ecr-pull-through-cache

### main.tf
- **What it is:** TF/providers/locals for pull-through cache pattern.
- **What it contains:** TF `>= 1.8`; aws/helm/kubernetes; account/AZ data; `cluster_version = "1.30"`.
- **Why it matters:** Shared locals (`name`, `region`, `ecr_url` used in addons).
- **Notable settings:** Region `us-west-2`.

### variables.tf
- **What it is:** Docker Hub credentials for authenticated pull-through.
- **What it contains:** Sensitive object `{username, accessToken}`.
- **Why it matters:** Required for docker-hub cache rule.
- **Notable settings:** Sensitive = true.

### vpc.tf
- **What it is:** Standard VPC module.
- **What it contains:** VPC `~> 5.9`, public/private, single NAT, ELB tags.
- **Why it matters:** Network for EKS nodes pulling via ECR.
- **Notable settings:** Private subnets for cluster.

### eks.tf
- **What it is:** EKS MNG with ECR pull-through IAM + EBS CSI IRSA + kubectl output.
- **What it contains:** EKS `~> 20.20`; IAM policy `ECRPullThroughCache`; node policies include that policy; ebs_csi_driver_irsa.
- **Why it matters:** Nodes can CreateRepository/BatchImportUpstreamImage for cache.
- **Notable settings:**
  - Policy actions: CreateRepository, BatchImportUpstreamImage, TagResource
  - Also `AmazonEC2ContainerRegistryReadOnly`
  - Addons: ebs-csi, coredns, kube-proxy, vpc-cni before_compute

### ecr.tf
- **What it is:** Secrets Manager docker secret + ECR registry pull-through rules + enhanced scanning.
- **What it contains:** secrets-manager module; ecr module with 4 rules (ecr/k8s/quay/dockerhub).
- **Why it matters:** Defines prefixes and upstream registries used by Helm image rewrites.
- **Notable settings:**
  - Prefixes: `ecr`, `k8s`, `quay`, `docker-hub`
  - dockerhub `credential_arn` from secret
  - `registry_scan_type = ENHANCED`, SCAN_ON_PUSH `*`

### addons.tf
- **What it is:** Blueprints addons + Gatekeeper with images rewritten to ECR cache URLs.
- **What it contains:** Argo CD, metrics-server, ALB controller, kube-prometheus-stack; separate gatekeeper addon module.
- **Why it matters:** Proves pull-through by forcing all chart images through account ECR prefixes.
- **Notable settings:**
  - `local.ecr_url = ACCOUNT.dkr.ecr.REGION.amazonaws.com`
  - Image repos under `/quay/...`, `/docker-hub/...`, `/k8s/...`, `/ecr/...`

### README.md
- **What it is:** Deploy with docker_secret var; validate cache rules; destroy ECR repos first.
- **What it contains:** `validate-pull-through-cache-rule` loop; pod list; mass ECR delete note.
- **Why it matters:** Cleanup guidance for auto-created cache repos.
- **Notable settings:** Apply var example for docker secret.

---

## karpenter

### main.tf
- **What it is:** Providers/locals for Karpenter-on-Fargate pattern.
- **What it contains:** aws + aws.ecr + helm; Public ECR token; name `ex-${basename(path.cwd)}`.
- **Why it matters:** Public ECR auth for Karpenter OCI chart.
- **Notable settings:** `region = us-west-2`.

### vpc.tf
- **What it is:** VPC with Karpenter discovery tags on private subnets.
- **What it contains:** VPC module; `karpenter.sh/discovery = local.name` on private subnets.
- **Why it matters:** Subnet auto-discovery for EC2NodeClass.
- **Notable settings:** Discovery tag must match NodeClass selectors.

### eks.tf
- **What it is:** Fargate-backed EKS (Karpenter controller namespace) without classic node SGs.
- **What it contains:** Fargate profile for `karpenter` ns; CoreDNS commented; pod-identity-agent/kube-proxy/vpc-cni; cluster tagged for discovery.
- **Why it matters:** Controller runs on Fargate; worker EC2 comes from Karpenter later.
- **Notable settings:**
  - `create_cluster_security_group/create_node_security_group = false`
  - Tag `karpenter.sh/discovery = local.name` on cluster

### karpenter.tf
- **What it is:** Karpenter IAM/SQS module + Helm install with IRSA (no pod identity).
- **What it contains:** `eks//modules/karpenter` `~> 20.24`; helm_release Karpenter 1.0.2.
- **Why it matters:** Fargate cannot use pod identity — IRSA enabled instead.
- **Notable settings:**
  - `enable_v1_permissions = true`
  - `create_pod_identity_association = false`, `enable_irsa = true`
  - `node_iam_role_name = local.name` (matches EC2NodeClass role)
  - `dnsPolicy: Default`, webhook disabled

### karpenter.yaml
- **What it is:** Manual EC2NodeClass + NodePool (apply after TF).
- **What it contains:** Bottlerocket AMI alias; role `ex-karpenter`; discovery selectors; NodePool instance constraints.
- **Why it matters:** Runtime Karpenter config not applied by Terraform.
- **Notable settings:**
  - categories c/m/r; cpu 4/8/16/32; nitro; generation > 2
  - `consolidationPolicy: WhenEmpty`, `consolidateAfter: 30s`, cpu limit 1000

### example.yaml
- **What it is:** Inflate Deployment to trigger provisioning.
- **What it contains:** pause image, replicas 0, cpu request 1.
- **Why it matters:** Scale to 3 to demo Karpenter node creation.
- **Notable settings:** `replicas: 0` initially.

### README.md
- **What it is:** Fargate Karpenter walkthrough + destroy order.
- **What it contains:** Apply yaml → scale inflate → expect EC2 nodes; destroy example then helm target.
- **Why it matters:** Correct teardown order avoids stuck nodes.
- **Notable settings:** Destroy targets `helm_release.karpenter` first after deleting example.

---

## karpenter-mng

### main.tf
- **What it is:** Same provider/local bootstrap as karpenter, name `ex-karpenter-mng`.
- **What it contains:** aws/ecr/helm; Public ECR token.
- **Why it matters:** OCI chart auth + shared tags.
- **Notable settings:** `local.name = "ex-${basename(path.cwd)}"`.

### vpc.tf
- **What it is:** VPC with discovery tags (same as karpenter).
- **What it contains:** Private subnet `karpenter.sh/discovery`.
- **Why it matters:** NodeClass subnet selection.
- **Notable settings:** Tag value = `local.name`.

### eks.tf
- **What it is:** EKS with tainted Bottlerocket MNG dedicated to Karpenter controller + CoreDNS tolerations.
- **What it contains:** MNG label/taint `karpenter.sh/controller`; CoreDNS toleration JSON; node SG discovery tags.
- **Why it matters:** Avoids deadlock (DNS must run before Karpenter can schedule elsewhere).
- **Notable settings:**
  - MNG `m5.large` Bottlerocket, desired 2
  - Taint NO_SCHEDULE on controller key
  - `node_security_group_tags` include discovery tag

### karpenter.tf
- **What it is:** Karpenter module with Pod Identity + Helm pinned to controller nodes.
- **What it contains:** `create_pod_identity_association = true`; helm nodeSelector/tolerations for controller taint.
- **Why it matters:** Contrast with Fargate pattern (IRSA vs pod identity).
- **Notable settings:**
  - Chart 1.0.2, webhook disabled
  - `nodeSelector.karpenter.sh/controller: 'true'`

### karpenter.yaml
- **What it is:** EC2NodeClass/NodePool for `ex-karpenter-mng`.
- **What it contains:** Same shape as karpenter pattern with role/discovery names updated.
- **Why it matters:** Applied post-TF for worker provisioning.
- **Notable settings:** role `ex-karpenter-mng`; discovery tags match.

### example.yaml
- **What it is:** Same inflate Deployment as karpenter.
- **What it contains:** pause, cpu 1, replicas 0.
- **Why it matters:** Demo scale-out onto Karpenter nodes.
- **Notable settings:** Identical to karpenter/example.yaml.

### README.md
- **What it is:** Explains MNG controller isolation + pod identity + SQS interruption queue.
- **What it contains:** Six-component narrative; validate/scale; destroy order.
- **Why it matters:** Why taint+label+CoreDNS toleration is required.
- **Notable settings:** Note README sample text says “four Fargate nodes” but pattern uses MNG (doc inconsistency).

---

## multi-node-vllm

### main.tf
- **What it is:** Providers/locals/VPC for multi-node vLLM + LWS.
- **What it contains:** aws/helm/http/kubectl/local providers; region `us-east-2`; VPC.
- **Why it matters:** http+kubectl pull LWS manifests; local writes `build.sh`.
- **Notable settings:** TF providers include `hashicorp/http` and `alekc/kubectl`.

### eks.tf
- **What it is:** EKS with `g6e.8xlarge` EFA GPU MNG + default MNG.
- **What it contains:** EKS `~> 20.34`; EFA support; RAID0; GPU taint/labels; subnet pinned to 3rd private subnet.
- **Why it matters:** Hardware base for pipeline-parallel vLLM across nodes.
- **Notable settings:**
  - `ami_type = AL2023_x86_64_NVIDIA`, `g6e.8xlarge`
  - `subnet_ids = [element(private_subnets, 2)]`
  - Cluster `1.32`

### helm.tf
- **What it is:** Device plugins + LeaderWorkerSet install from GitHub release manifests.
- **What it contains:** nvidia/efa helm; `data.http` LWS v0.5.1 manifests applied via kubectl_manifest for_each.
- **Why it matters:** LWS CRD/controller required by `lws.yaml`.
- **Notable settings:** `lws_version = "v0.5.1"`, server_side_apply true.

### ecr.tf
- **What it is:** ECR repo + generated `build.sh` for image build/push and lws.yaml image sed.
- **What it contains:** ecr module; `local_file.vllm` bash script with zstd OCI build.
- **Why it matters:** Bridges Dockerfile → private ECR → LeaderWorkerSet image field.
- **Notable settings:** `repository_force_delete = true`; sed updates `./lws.yaml` image.

### lws.yaml
- **What it is:** vLLM LeaderWorkerSet + ClusterIP Service.
- **What it contains:** LWS size 4; leader OpenAI API server; workers ray_init; EFA/NCCL env; GPU+EFA resource requests.
- **Why it matters:** Workload definition for Llama-3.3-70B pipeline parallel.
- **Notable settings:**
  - `--pipeline-parallel-size 4`, `--tensor-parallel-size 1`
  - `FI_PROVIDER=efa`, HF token placeholder
  - Requests `nvidia.com/gpu: 1`, `vpc.amazonaws.com/efa: 1`, ephemeral-storage 160Gi

### Dockerfile
- **What it is:** Ubuntu 22.04 image with vLLM + EFA + NCCL + aws-ofi-nccl.
- **What it contains:** CUDA keyring; pip vllm; EFA installer 1.37.0; NCCL 2.25.1; aws-ofi-nccl 1.13.2-aws; ray_init.sh.
- **Why it matters:** Collective comms stack for multi-node GPU inference over EFA.
- **Notable settings:** CUDA 12.4; removes bundled NCCL; sm_89 gencode; hf_transfer.

### README.md
- **What it is:** End-to-end deploy/build/infer validate; quota warning for G/VT vCPUs.
- **What it contains:** build.sh timing note; HF token step; curl completion sample.
- **Why it matters:** Operational path after Terraform.
- **Notable settings:** Needs ≥64 vCPU G/VT quota for two g6e.8xlarge.

---

## nvidia-gpu-efa

### main.tf
- **What it is:** Providers/VPC/output for NVIDIA+EFA pattern.
- **What it contains:** aws/helm; VPC; `us-west-2`.
- **Why it matters:** Base for p5 GPU cluster.
- **Notable settings:** Standard VPC layout.

### eks.tf
- **What it is:** EKS with `p5.48xlarge` NVIDIA EFA MNG + default MNG.
- **What it contains:** Same shape as other GPU patterns: RAID0, EFA, labels, GPU taint.
- **Why it matters:** Hardware for NCCL/EFA MPIJob tests.
- **Notable settings:**
  - `AL2023_x86_64_NVIDIA`, `p5.48xlarge`, size 2
  - Cluster `1.32`, `enable_efa_support`

### helm.tf
- **What it is:** NVIDIA + EFA device plugins.
- **What it contains:** nvidia 0.17.1; efa v0.5.7.
- **Why it matters:** Required before MPIJobs can request GPU/EFA resources.
- **Notable settings:** EFA tolerates `nvidia.com/gpu`.

### generate-efa-info-test.sh
- **What it is:** Bash generator for Kubeflow MPIJob that runs `fi_info -p efa`.
- **What it contains:** Env defaults (2 workers, 8 GPU, 32 EFA); writes `efa-info-test.yaml`.
- **Why it matters:** Validate EFA devices visible inside pods.
- **Notable settings:** Image `public.ecr.aws/hpc-cloud/nccl-tests:latest`; MPIJob v2beta1.

### generate-efa-nccl-test.sh
- **What it is:** Bash generator for NCCL all_reduce_perf MPIJob.
- **What it contains:** FI_/NCCL_ env; hugepages/memory requests; writes `efa-nccl-test.yaml`.
- **Why it matters:** Measure multi-node EFA bandwidth.
- **Notable settings:**
  - `INSTANCE_TYPE=p5e.48xlarge` (differs from eks.tf `p5.48xlarge`)
  - `EFA_PER_WORKER=32`, `GPU_PER_WORKER=8`
  - HostPath `/dev/shm`

### .gitignore
- **What it is:** Ignore generated MPIJob manifests.
- **What it contains:** `efa-info-test.yaml`, `efa-nccl-test.yaml`.
- **Why it matters:** Generated artifacts stay local.
- **Notable settings:** Two yaml filenames only.

### README.md
- **What it is:** Full validate path: MPI operator, info test, NCCL test, sample bandwidth logs.
- **What it contains:** Deploy MPI operator YAML; script usage; destroy.
- **Why it matters:** How to prove EFA/NCCL health on the cluster.
- **Notable settings:** Mentions optional ODCR block in eks.tf (commented in narrative).

---

## sso-iam-identity-center

### versions.tf
- **What it is:** aws + kubernetes providers.
- **What it contains:** No okta — uses AWS SSO APIs.
- **Why it matters:** Identity Center + Access Entries pattern.
- **Notable settings:** TF `>= 1.3`.

### variables.tf
- **What it is:** Admin/user Identity Store user configs.
- **What it contains:** family_name/given_name/email lists with defaults.
- **Why it matters:** Feeds `aws_identitystore_user` resources.
- **Notable settings:** Default example.com emails.

### main.tf
- **What it is:** EKS with API auth mode + Access Entries for SSO roles.
- **What it contains:** EKS `authentication_mode = "API"`; access entries for operators (ClusterAdminPolicy) and developers (ViewPolicy on default ns); VPC.
- **Why it matters:** Replaces aws-auth ConfigMap with Access Entries tied to SSO IAM roles.
- **Notable settings:**
  - `enable_cluster_creator_admin_permissions = true`
  - Developers also get `kubernetes_groups = ["eks-developers"]`
  - Principals from `data.aws_iam_roles.admin/user`

### sso.tf
- **What it is:** IAM Identity Center permission sets, users, groups, account assignments.
- **What it contains:** Permission sets EKSClusterAdmin/User; inline + managed policies; identitystore users/groups/memberships; account assignments.
- **Why it matters:** Creates IdP-side roles that Access Entries consume.
- **Notable settings:**
  - Session `PT1H`; PowerUserAccess / ViewOnlyAccess attachments
  - Groups `eks-operators` / `eks-developers`
  - Requires Identity Center enabled in account

### teams.tf
- **What it is:** Resolves reserved SSO IAM role ARNs + developers team namespace/RBAC via blueprints-teams.
- **What it contains:** `aws_iam_roles` name_regex for `AWSReservedSSO_EKSClusterAdmin_.*` / `User_.*`; `developers_team` module with quotas, limit ranges, network policy.
- **Why it matters:** Bridges SSO role ARNs into EKS access + namespace `development` isolation.
- **Notable settings:**
  - `create_iam_role = false`, `principal_arns = data.aws_iam_roles.user.arns`
  - NetworkPolicy ingress from default ns + 10.0.0.0/8 excepts

### outputs.tf
- **What it is:** kubectl + guided `aws configure sso` snippets for admin/user.
- **What it contains:** `configure_kubectl`, `configure_sso_admins`, `configure_sso_users`.
- **Why it matters:** End-user SSO profile setup after apply.
- **Notable settings:** Start URL uses identity store id + `.awsapps.com/start`.

### README.md
- **What it is:** Prerequisite Identity Center check; SSO configure examples; destroy order.
- **What it contains:** `aws identitystore list-instances`; password reset; destroy teams then eks then all.
- **Why it matters:** Documents Access Manager + SSO operational flow.
- **Notable settings:** May need re-associate ClusterAdminPolicy if creator access revoked before destroy.

## Data Flow Map

```
pattern folder
  ├─ versions/main providers + locals
  ├─ vpc (or inline module) → private subnets (+ tags)
  ├─ eks module → cluster + MNG/Fargate + addons/access
  ├─ sidecar files (helm/ecr/sso/okta/karpenter/teams)
  └─ optional YAML/scripts → post-apply workloads / validate
```

Cross-cutting ML GPU family (`aws-neuron-efa`, `ml-capacity-block`, `targeted-odcr`, `nvidia-gpu-efa`, `multi-node-vllm`):

```
VPC → EKS (enable_efa_support)
  → GPU/Neuron MNG (AMI + RAID0 + labels/taints + optional CBR/ODCR)
  → default MNG (addons)
  → device plugin Helm
  → (optional) LWS/MPIJob/vLLM manifests
```

## Related Files

| Path | Role |
|---|---|
| `/Users/k/Codes/GithubProjects/Terraform/terraform-aws-eks-blueprints-main/patterns/` | Source patterns |
| `3.sh` | Placeholder (no commands to auto-run) |

## Commands

See `3.sh` — no live CLI was run; listing-only helper for local browsing.


---

# SOURCE: agent/3-eks-blueprints-root-docs-github/3-eks-blueprints-root-docs-github.md

# EKS Blueprints Root Docs GitHub

```
need file inventory?
 → Root (README, license, tooling) → project identity + contribution gates
 → docs/ (MkDocs site) → what users learn and how patterns are published
 → .github/ (CI, templates, scripts) → how quality and publish are enforced
 unclear? → read file contents below by section
```

| Key point | Detail |
|---|---|
| What this is | Per-file catalog of non-image files under Root, `docs/`, and `.github/` in `terraform-aws-eks-blueprints-main` |
| Consumption model | Patterns are reference / copy-paste, not a Terraform module to consume as-is |
| Docs site | MkDocs Material; most pattern pages wrap `patterns/*/README.md` via `include-markdown` |
| CI focus | pre-commit, plan-examples, e2e apply/destroy, docs publish, link check, Scorecard, Dependabot |

## Summary

Amazon EKS Blueprints for Terraform is a pattern library (not an umbrella cluster module in v5). Root files define license, contribution, and local quality gates. `docs/` is the published MkDocs site (getting started, FAQ, migration, pattern pages, snippets). `.github/` owns issue/PR hygiene, workflows, and helper Python scripts for CI and docs build.

## Main content

## Root

### README.md

| Field | Detail |
|---|---|
| What it is | Project landing README for Amazon EKS Blueprints for Terraform |
| What it contains / does | Explains motivation (opinionated complete EKS clusters), consumption model (reference or copy-paste, not as a Terraform module), related projects (addon/addons/teams modules, GitOps, Data on EKS, Observability Accelerator, Karpenter Blueprints, GitLab CD component), Terraform caveats (bundled VPC, single-workspace + targeted apply, no module-style vars/outputs), support/feedback, security pointer, Apache-2.0 license |
| Why it matters | Primary onboarding and sets the non-module consumption contract |
| Notable details | Points to FAQ for kubernetes/helm/kubectl provider auth (static token vs `exec`); lists supporting modules `terraform-aws-eks-blueprint-addon(s)` and `terraform-aws-eks-blueprints-teams` |

### ADOPTERS.md

| Field | Detail |
|---|---|
| What it is | Self-reported adopters list |
| What it contains / does | Table of Organization, Description, Contacts, Link; invites PRs to add entries |
| Why it matters | Social proof and contact points for other implementers |
| Notable details | Alphabetical adopters include PITS Global Data Recovery Services, AlgoDx AB, Swyft Logistics; excluded from cspell in pre-commit |

### CODE_OF_CONDUCT.md

| Field | Detail |
|---|---|
| What it is | Code of conduct pointer |
| What it contains / does | Adopts Amazon Open Source Code of Conduct; FAQ link; `opensource-codeofconduct@amazon.com` |
| Why it matters | Community behavior baseline |
| Notable details | Thin wrapper; full text lives on aws.github.io |

### CONTRIBUTING.md

| Field | Detail |
|---|---|
| What it is | Contributing guidelines |
| What it contains / does | Bug/feature reporting tips; PR workflow (fork, focus change, tests, clear commits, watch CI); find `help wanted` issues; CoC; **security issues via AWS vulnerability page, not public GitHub issues**; licensing note |
| Why it matters | How external contributors interact safely and effectively |
| Notable details | Security path is explicit and non-negotiable for vulns |

### LICENSE

| Field | Detail |
|---|---|
| What it is | Full Apache License 2.0 text |
| What it contains / does | Standard Apache-2.0 terms (copyright/patent grants, redistribution, contribution terms, AS-IS warranty, liability) |
| Why it matters | Legal basis for use, redistribution, and contributions |
| Notable details | Matches README “Apache-2.0 Licensed” |

### NOTICE.txt

| Field | Detail |
|---|---|
| What it is | Apache NOTICE attribution file |
| What it contains / does | Copyright 2016–2022 Amazon.com, Inc. or affiliates; Apache-2.0 reference (`http://aws.amazon.com/apache2.0/`) |
| Why it matters | Required NOTICE companion under Apache-2.0 redistribution |
| Notable details | Short; copyright years end at 2022 while mkdocs copyright says 2024 |

### .gitignore

| Field | Detail |
|---|---|
| What it is | Git ignore rules |
| What it contains / does | Ignores IDE/OS junk, MkDocs `/site`, `.terraform`, lockfile, tfstate/tfplan, crash logs, `*.tfvars`, override tf files, terraformrc, `.tfsec`, `*.envrc`, `*kube-config.yaml`, `builds`, `__pycache__` |
| Why it matters | Keeps secrets, local state, and generated docs out of git |
| Notable details | Explicit comment that `.tfvars` often hold sensitive data |

### .pre-commit-config.yaml

| Field | Detail |
|---|---|
| What it is | Pre-commit hook config for local and CI quality |
| What it contains / does | Hooks: `cspell` (v9.0.1) with many path excludes; `pretty-format-yaml`; trailing whitespace / EOF / merge conflict / private key / AWS credentials; `pre-commit-terraform` (`terraform_fmt`, `terraform_docs`, `terraform_tflint` with selected rules, `terraform_validate` excluding `docs|modules`) |
| Why it matters | Enforces formatting, spelling, Terraform hygiene before merge |
| Notable details | TFLint limited to named rules only; validate skips `docs` and `modules` |

### cspell.config.yaml

| Field | Detail |
|---|---|
| What it is | CSpell dictionary wiring |
| What it contains / does | Defines `bpWords` dictionary from `./docs/cSpell_dict.txt` and enables it |
| Why it matters | Avoids false spellcheck failures on K8s/AWS jargon |
| Notable details | Companion word list lives under `docs/` even though config is at root |

### mkdocs.yml

| Field | Detail |
|---|---|
| What it is | MkDocs site configuration |
| What it contains / does | Site name Amazon EKS Blueprints for Terraform; Material theme (orange, Ember font, logos under `images/`); plugins `include-markdown`, `search`, `awesome-pages`; hook `.github/scripts/mkdocs-hooks.py`; `mike` version provider; markdown extensions (admonition, highlight, snippets, superfences, toc permalinks); docs from `docs/`; site URL `https://aws-ia.github.io/terraform-aws-eks-blueprints/` |
| Why it matters | Controls published documentation look, nav plugins, and build hooks |
| Notable details | Sticky nav tabs; copyright Amazon 2024 |

---

## docs

### docs/.pages

| Field | Detail |
|---|---|
| What it is | awesome-pages nav for docs root |
| What it contains / does | Order: Overview, Getting Started, Patterns, Snippets, v4 to v5 Migration, FAQ |
| Why it matters | Top-level docs navigation order |
| Notable details | Patterns/Snippets/v4-to-v5 are directories expanded by awesome-pages |

### docs/index.md

| Field | Detail |
|---|---|
| What it is | Docs home / Overview page |
| What it contains / does | Single `include-markdown` of `../README.md` |
| Why it matters | Keeps GitHub README and docs Overview in sync |
| Notable details | No extra body beyond the include |

### docs/getting-started.md

| Field | Detail |
|---|---|
| What it is | Getting started guide |
| What it contains / does | Prerequisites (awscli, kubectl, terraform); clone + `cd` into pattern; targeted apply VPC → EKS → full apply; `update-kubeconfig`; `kubectl get nodes`; destroy order (addons → eks → all); warnings for private clusters and resources created outside Terraform (e.g. Karpenter nodes) |
| Why it matters | Canonical first-run path for any pattern |
| Notable details | Points to Terraform Caveats for why targeted apply exists |

### docs/faq.md

| Field | Detail |
|---|---|
| What it is | Frequently asked questions |
| What it contains / does | Topics: VPC destroy timeouts (vpc-cni ENI leak cleanup order); leaked CloudWatch log groups (`create_cloudwatch_log_group` true/false tradeoffs); provider auth static token vs `exec()` with full HCL examples; stuck Terminating namespaces (orphan CRD resources, patch finalizers) |
| Why it matters | Day-2 failure modes users hit during apply/destroy |
| Notable details | Defaults examples to static tokens for ease; documents 15-minute token lifetime and `terraform refresh` |

### docs/cSpell_dict.txt

| Field | Detail |
|---|---|
| What it is | Custom spellcheck word list (~190 terms) |
| What it contains / does | Project jargon: agones, argocd, bottlerocket, karpenter, kubecost, irsa, efa, vllm, odcr, privatelink, etc. |
| Why it matters | Feeds `bpWords` for cspell so docs/patterns do not fail on domain terms |
| Notable details | Plain newline-separated words; referenced by root `cspell.config.yaml` |

### docs/_partials/destroy.md

| Field | Detail |
|---|---|
| What it is | Reusable destroy snippet |
| What it contains / does | Three `terraform destroy -target=...` commands (addons, eks, then all) plus link to getting-started destroy section |
| Why it matters | Shared teardown steps included by many pattern READMEs |
| Notable details | Included via `{% include-markdown %}` from pattern docs |

### docs/internal/ci.md

| Field | Detail |
|---|---|
| What it is | Internal CI setup notes for E2E |
| What it contains / does | Describes GitHub Actions using `configure-aws-credentials` + `setup-terraform`; CloudFormation for GitHub OIDC IAM role; attach `AdministratorAccess`; secret `ROLE_TO_ASSUME`; S3 backend for recoverability |
| Why it matters | How maintainers (or forks) wire AWS OIDC for e2e workflows |
| Notable details | Marked internal; not in top-level `.pages` nav (still in tree for maintainers) |

### docs/snippets/ipv4-prefix-delegation.md

| Field | Detail |
|---|---|
| What it is | Snippet: IPv4 prefix delegation on VPC CNI |
| What it contains / does | Explains raising pods-per-node; `before_compute = true` + `ENABLE_PREFIX_DELEGATION` / `WARM_PREFIX_TARGET`; verify via `kubectl describe ds aws-node` |
| Why it matters | Common IP density fix for dense workloads |
| Notable details | Warns wrong max-pods usually means CNI was not configured before nodes |

### docs/snippets/vpc-cni-custom-networking.md

| Field | Detail |
|---|---|
| What it is | Snippet: VPC CNI custom networking |
| What it contains / does | Secondary CIDRs, `AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG`, `ENIConfig` CRDs via `kubectl_manifest`, verification on aws-node env |
| Why it matters | Pattern for primary-CIDR exhaustion without redesigning the whole cluster |
| Notable details | Notes custom networking does not use primary ENI for pods (lower max pods) |

### docs/patterns/.pages

| Field | Detail |
|---|---|
| What it is | Patterns section nav |
| What it contains / does | Ordered list of pattern pages and subdirs (Auto Mode, GitOps, Machine Learning, Network, SSO variants, etc.) |
| Why it matters | Controls Patterns menu in published docs |
| Notable details | Titles differ slightly from some page front-matter titles |

### docs/v4-to-v5/.pages

| Field | Detail |
|---|---|
| What it is | Migration section nav |
| What it contains / does | Motivation → Cluster → Addons → Teams |
| Why it matters | Guides readers through v4→v5 migration docs |
| Notable details | Example TF lives under `example/` but is not listed in this `.pages` (linked from guides) |

### docs/v4-to-v5/motivation.md

| Field | Detail |
|---|---|
| What it is | Why v5 direction changed |
| What it contains / does | What worked (fast adoption, popular patterns); what failed (addon explosion, Terraform on-cluster limits, public API need, nested modules, competing cluster tools); v5 shifts to modular components + patterns-only repo; lists removals (cluster modules, KMS, EMR-on-EKS, irsa/helm-addon → addon module, teams → teams module, ArgoCD TF integration deferred); before/after repo trees |
| Why it matters | Explains why this repo is patterns, not an umbrella module |
| Notable details | Encourages `terraform-aws-eks` for cluster creation |

### docs/v4-to-v5/cluster.md

| Field | Detail |
|---|---|
| What it is | Cluster migration guide to EKS module v19.x |
| What it contains / does | Breaking changes (remove Blueprints cluster/KMS/EMR/teams modules); before (v4.32 `github.com/aws-ia/terraform-aws-eks-blueprints`) vs after (`terraform-aws-modules/eks/aws`) HCL; state/move guidance in longer body |
| Why it matters | Practical migration for cluster resources |
| Notable details | Points to `docs/v4-to-v5/example` for reference configs |

### docs/v4-to-v5/addons.md

| Field | Detail |
|---|---|
| What it is | Addons migration guide |
| What it contains / does | Marked under active development; skeleton before (`//modules/kubernetes-addons?ref=v4.32.1`) vs after (`aws-ia/eks-blueprints-addons/aws` `~> 1.0`); diff and placeholder state mv |
| Why it matters | Shows registry module path for addons in v5 |
| Notable details | Many sections still TODO placeholders |

### docs/v4-to-v5/teams.md

| Field | Detail |
|---|---|
| What it is | Teams migration guide |
| What it contains / does | Under active development; before embedded teams vs after `aws-ia/eks-blueprints-teams/aws` `~> 1.0`; diff + placeholder state mv |
| Why it matters | Points multi-tenancy users to standalone teams module |
| Notable details | TODO-heavy like addons guide |

### docs/v4-to-v5/example/README.md

| Field | Detail |
|---|---|
| What it is | Migration example folder title |
| What it contains / does | Single heading: `# Migration - v4 to v5` |
| Why it matters | Labels the companion TF example tree |
| Notable details | Minimal; real content is in `.tf` files |

### docs/v4-to-v5/example/main.tf

| Field | Detail |
|---|---|
| What it is | Shared supporting infra for migration example |
| What it contains / does | AWS provider, caller/AZ data, locals, VPC module (`~> 5.0`) with public/private subnets and k8s ELB tags |
| Why it matters | Common VPC used by v4 and v5 cluster examples |
| Notable details | Region hardcoded `us-west-2`; name `migration` |

### docs/v4-to-v5/example/v4.tf

| Field | Detail |
|---|---|
| What it is | Pre-migration (v4) cluster definition |
| What it contains / does | kubernetes provider with exec auth; `module.eks` from Blueprints `v4.32.1` with MNG, Fargate, self-managed NG, `map_roles` |
| Why it matters | Side-by-side “before” for migration |
| Notable details | Uses older output names like `eks_cluster_endpoint` / `eks_cluster_id` |

### docs/v4-to-v5/example/v5.tf

| Field | Detail |
|---|---|
| What it is | Post-migration (v5) cluster definition |
| What it contains / does | Same shape on `terraform-aws-modules/eks/aws` `~> 19.13` with `aws_auth_roles`, managed/fargate/self-managed groups, backwards-compat naming flags |
| Why it matters | Side-by-side “after” for migration |
| Notable details | Comments mark settings kept for backwards compatibility (IAM role names, KMS alias, log types) |

### docs/v4-to-v5/example/versions.tf

| Field | Detail |
|---|---|
| What it is | Terraform/provider version constraints for migration example |
| What it contains / does | TF `>= 1.0`; aws `>= 4.47`; kubernetes `>= 2.17` |
| Why it matters | Pins minimum tooling for the example |
| Notable details | No helm/kubectl providers declared here |

### Pattern docs pages (MkDocs wrappers)

Each file below is a short MkDocs page (YAML title + `include-markdown` of the pattern README). Content summarized is from the included README.

| Docs path | Included source | What the pattern is / does | Why it matters | Notable details |
|---|---|---|---|---|
| `patterns/agones-game-controller.md` | `patterns/agones-game-controller/README.md` | EKS + Agones for dedicated game servers; mentions GameLift FleetIQ | Gaming workload blueprint | Validate with sample gameserver + netcat UDP |
| `patterns/blue-green-upgrade.md` | `patterns/blue-green-upgrade/README.md` | Blue/green or canary migration across two EKS clusters via Route53 weighted routing, LBC, External DNS, ArgoCD apps-of-apps | Cluster cutover pattern | Stacks: environment, eks-blue, eks-green, shared module |
| `patterns/bottlerocket.md` | `patterns/bottlerocket/README.md` | Bottlerocket on MNG + Karpenter with Bottlerocket Update Operator for OS CVE patches | Hardened OS + automated patching | BRUPOP is patch-level only, not minor/major |
| `patterns/ecr-pull-through-cache.md` | `patterns/ecr-pull-through-cache/README.md` | ECR pull-through for Docker Hub, k8s, Quay, ECR; scan-on-push; addons use cached images | Faster/safer public image pulls | Needs `docker_secret` var for Docker Hub |
| `patterns/external-secrets.md` | `patterns/external-secrets/README.md` | External Secrets Operator with ClusterSecretStore/SecretStore (Secrets Manager + SSM) via IRSA | Secrets sync pattern | Includes `_partials/destroy.md` |
| `patterns/fargate-serverless.md` | `patterns/fargate-serverless/README.md` | Fully Fargate data plane; sample app; Fargate Fluent Bit logging ConfigMap | Serverless EKS dataplane | Validate Fargate node names + aws-logging CM |
| `patterns/fully-private-cluster.md` | `patterns/fully-private-cluster/README.md` | No internet; private endpoint; required VPC endpoints listed | Air-gapped / private-only clusters | Endpoint list includes ECR, STS, ELB, S3, etc. |
| `patterns/istio.md` | `patterns/istio/README.md` | EKS + Istio + ingress gateway (NLB); sample app; optional Kiali/Jaeger/Prometheus/Grafana | Service mesh starter | Requires ingress rollout restart due to istiod dependency issue |
| `patterns/karpenter.md` | `patterns/karpenter/README.md` | Karpenter controller on Fargate; includes highlighted TF/YAML from pattern files | Karpenter on serverless control nodes | Docs embed pattern `eks.tf` / `karpenter.tf` / yaml |
| `patterns/karpenter-mng.md` | `patterns/karpenter-mng/README.md` | Karpenter on tainted/labeled MNG; Pod Identity; SQS interruption queue | Karpenter with daemonset-friendly nodes | CoreDNS toleration avoids deadlock |
| `patterns/kubecost.md` | `patterns/kubecost/README.md` | Kubecost + AWS CUR billing integration; delayed CFN for crawler | Cost visibility on EKS | Needs `kubecost_token`; follow-up `run-me-in-24h/` |
| `patterns/multi-tenancy-with-teams.md` | `patterns/multi-tenancy-with-teams/README.md` | Teams isolation: team-red, team-blue, team-admin | Multi-tenant RBAC/namespace pattern | Validate section still TODO |
| `patterns/stateful.md` | `patterns/stateful/README.md` | Velero, EBS/EFS CSI, gp3 default SC, multi-volume + instance-store MNGs with CMK/gp3 | Stateful workload building blocks | Features optional; pick what you need |
| `patterns/sso-iam-identity-center.md` | `patterns/sso-iam-identity-center/README.md` | IAM Identity Center + EKS Access Entries/RBAC | AWS-native SSO into EKS | Uses `aws_ssoadmin_instances` data source |
| `patterns/sso-okta.md` | `patterns/sso-okta/README.md` | Okta OIDC IdP + Kubernetes RBAC | External IdP SSO | Uses kubectl oidc-login exec plugin |
| `patterns/eks-automode/eks-automode-custom-nodepools.md` | `patterns/eks-automode/automode-custom-nodepools/README.md` | EKS Auto Mode with custom NodeClass/NodePool (amd64/arm64/gpu); default pools disabled | Customize Auto Mode compute | YAML under `eks-automode-config/` |
| `patterns/gitops/gitops-getting-started-argocd.md` | `patterns/gitops/getting-started-argocd/README.md` | ArgoCD + GitOps Bridge (IaC metadata → Helm addons) | Intro GitOps on EKS | Optional fork of GitOps repos |
| `patterns/gitops/gitops-multi-cluster-hub-spoke-argocd.md` | `patterns/gitops/multi-cluster-hub-spoke-argocd/README.md` | Hub ArgoCD manages spoke clusters’ addons/workloads | Multi-cluster GitOps | Deploy hub then spokes; apps named `workloads-${env}` |
| `patterns/machine-learning/nvidia-gpu-efa.md` | `patterns/nvidia-gpu-efa/README.md` | `p5.48xlarge` + EFA + NVIDIA/EFA device plugins, RAID-0 NVMe | Multi-node GPU ML | Placement group + GPU taint/labels |
| `patterns/machine-learning/multi-node-vllm.md` | `patterns/multi-node-vllm/README.md` | Multi-node vLLM inference with LWS on `g6e.8xlarge` + EFA | Distributed inference | Includes Dockerfile for collective libs + ECR |
| `patterns/machine-learning/targeted-odcr.md` | `patterns/targeted-odcr/README.md` | Targeted ODCR via AZ-limited subnets, launch template capacity reservation, resource group | Guaranteed on-demand capacity | Screenshots copied into docs by mkdocs hook |
| `patterns/machine-learning/ml-container-cache.md` | `patterns/ml-container-cache/README.md` | Step Functions cache builder → EBS snapshot → mount at `/var/lib/containerd` | Faster large ML image starts | Claims ~5s vs ~6 min for large PyTorch image |
| `patterns/machine-learning/aws-neuron-efa.md` | `patterns/aws-neuron-efa/README.md` | `trn1.32xlarge` + Neuron + EFA plugins | Trainium/Inferentia-style ML | Neuron taint + RAID-0 NVMe |
| `patterns/machine-learning/ml-capacity-block.md` | `patterns/ml-capacity-block/README.md` | ML Capacity Block Reservation on MNG (`CAPACITY_BLOCK`) | Reserved ML capacity windows | AZ-restricted subnets + LT market options |
| `patterns/network/private-public-ingress.md` | `patterns/private-public-ingress/README.md` | Dual ingress-nginx (external + internal) with SG-backed NLBs | Split public/private ingress | Classes `ingress-nginx-external` / `ingress-nginx-internal` |
| `patterns/network/client-server-communication.md` | `patterns/vpc-lattice/client-server-communication/README.md` | VPC Lattice client↔server across VPCs via Gateway API Controller + external-dns | Service-to-service without classic peering complexity | Validate via Session Manager curl to `server.example.com` |
| `patterns/network/ipv6-eks-cluster.md` | `patterns/ipv6-eks-cluster/README.md` | IPv6 EKS networking | Dual-stack / IPv6 clusters | Pods/nodes show IPv6 addresses |
| `patterns/network/wireguard-with-cilium.md` | `patterns/wireguard-with-cilium/README.md` | Cilium chained with VPC CNI + WireGuard transparent encryption | Pod encryption overlay | Needs kernel 5.10+; NodeEncryption disabled in example |
| `patterns/network/privatelink-access.md` | `patterns/privatelink-access/README.md` | Access private EKS API via PrivateLink; SSM test from client EC2 | Private API access pattern | Targeted apply for eventbridge/nlb first |
| `patterns/network/aws-vpc-cni-network-policy.md` | `patterns/aws-vpc-cni-network-policy/README.md` | Native VPC CNI NetworkPolicy + Stars demo | NetworkPolicy without Calico/Cilium | Needs VPC CNI ≥ 1.14.0 |
| `patterns/network/cross-cluster-pod-communication.md` | `patterns/vpc-lattice/cross-cluster-pod-communication/README.md` | Secure multi-cluster Lattice with IAM auth, PCA TLS, Kyverno SigV4 sidecar, ExternalDNS | Cross-cluster with overlapping CIDRs | Blog-linked; bi-directional App1↔App2 |
| `patterns/network/tls-with-aws-pca-issuer.md` | `patterns/tls-with-aws-pca-issuer/README.md` | cert-manager + AWS Private CA issuer for TLS certs | Private PKI for cluster TLS | Validate Certificate Ready + TLS secret |

---

## .github

### .github/CODEOWNERS

| Field | Detail |
|---|---|
| What it is | CODEOWNERS file |
| What it contains / does | `* @aws-ia/internal-terraform-eks-admins` |
| Why it matters | Routes review ownership for all paths |
| Notable details | Single team owns everything |

### .github/dependabot.yml

| Field | Detail |
|---|---|
| What it is | Dependabot config |
| What it contains / does | Daily updates for `github-actions` ecosystem at `/` |
| Why it matters | Keeps Actions versions current |
| Notable details | Actions only (no npm/pip/terraform ecosystem entries here) |

### .github/PULL_REQUEST_TEMPLATE.md

| Field | Detail |
|---|---|
| What it is | PR description template |
| What it contains / does | Description; Motivation (`Resolves #`); test checklist (local test, docs update, `pre-commit run -a`); Additional Notes |
| Why it matters | Standardizes PR quality bar |
| Notable details | Warns to open an issue before significant work |

### .github/ISSUE_TEMPLATE/config.yml

| Field | Detail |
|---|---|
| What it is | Issue template config |
| What it contains / does | `blank_issues_enabled: false` |
| Why it matters | Forces structured issue forms |
| Notable details | No free-form blank issues |

### .github/ISSUE_TEMPLATE/bug_report.md

| Field | Detail |
|---|---|
| What it is | Bug report template |
| What it contains / does | Requires executable reproduction (`terraform init && apply`); search checkbox; cache clear steps; module/TF/provider versions; expected vs actual; screenshots |
| Why it matters | Makes bugs actionable for maintainers |
| Notable details | Mentions `examples/*` (historical naming; repo uses `patterns/`) |

### .github/ISSUE_TEMPLATE/feature_request.md

| Field | Detail |
|---|---|
| What it is | Feature request template |
| What it contains / does | Community Note (vote with reactions, no +1 noise); outcome, proposed solution, alternatives, context |
| Why it matters | Prioritizes features with signal, not comment spam |
| Notable details | Standard AWS terraform-module style community note |

### .github/ISSUE_TEMPLATE/question.md

| Field | Detail |
|---|---|
| What it is | Question issue template |
| What it contains / does | Search checkbox; question body; link to related example/module; context |
| Why it matters | Separates Q&A from bugs/features |
| Notable details | Asks for repo example link |

### .github/workflows/linkcheck.json

| Field | Detail |
|---|---|
| What it is | markdown-link-check config |
| What it contains / does | 5s timeout; retry on 429 (5×, 30s fallback); alive 200/206; special Accept-Encoding for help.github.com; ignore localhost/127.0.0.1 |
| Why it matters | Reduces flaky link CI failures |
| Notable details | Consumed by `markdown-link-check.yml` |

### .github/scripts/mkdocs-hooks.py

| Field | Detail |
|---|---|
| What it is | MkDocs build hook |
| What it contains / does | `on_page_markdown` (attempted path replaces; return markdown); `on_files` copies assets from pattern dirs into site (targeted-odcr screenshots, kubecost screenshot, ml-container-cache svg/png) |
| Why it matters | Makes pattern assets appear under docs URLs without duplicating into `docs/` |
| Notable details | `markdown.replace` results are not assigned back (no-op for markdown path rewrites) |

### .github/scripts/delete-log-groups.py

| Field | Detail |
|---|---|
| What it is | CI cleanup helper |
| What it contains / does | boto3 Logs client; deletes log groups prefixed `/aws/eks/` (up to 50 listed) in `AWS_DEFAULT_REGION` (default `us-west-2`) |
| Why it matters | Clears leaked EKS CW log groups before e2e runs |
| Notable details | Used by `e2e-parallel-full.yml` prereq job |

### .github/scripts/iam-policy-generator.py

| Field | Detail |
|---|---|
| What it is | IAM policy merger for e2e |
| What it contains / does | Reads all JSON policy objects from S3 bucket `BUCKET_NAME`; unions Action lists; prints Allow `Resource: "*"` skeleton policy |
| Why it matters | Builds aggregate IAM policy from iamlive captures across examples |
| Notable details | Needs `BUCKET_NAME` env; used post-deploy in e2e-full |

### .github/scripts/plan-examples.py

| Field | Detail |
|---|---|
| What it is | Discovers pattern directories for plan matrix |
| What it contains / does | Glob `patterns/**/main.tf`; exclude certain paths (appmesh-mtls, blue-green subdirs, istio-multi-cluster parts, privatelink-access); prints JSON array |
| Why it matters | Feeds `plan-examples.yml` matrix dynamically |
| Notable details | Skips paths matching `^.+/_` |

### .github/workflows/publish-docs.yml

| Field | Detail |
|---|---|
| What it is | Docs publish workflow |
| What it contains / does | On push to `main`: harden-runner; checkout; Python; pip install pinned mkdocs-material + include-markdown + awesome-pages; `mkdocs gh-deploy --force` |
| Why it matters | Publishes GitHub Pages docs site |
| Notable details | Pins plugin versions; contents write for gh-pages |

### .github/workflows/pre-commit.yml

| Field | Detail |
|---|---|
| What it is | Pre-commit CI on PRs |
| What it contains / does | Triggers on `**.tf`/`**.yml`/`**.yaml` to main; concurrency cancel; TF 1.3.10, terraform-docs v0.19.0, tflint v0.53.0; paths-filter for `*.tf`; composite pre-commit action when TF changed |
| Why it matters | Enforces same hooks as local pre-commit in CI |
| Notable details | Job name “Min TF pre-commit”; YAML-only changes may not run TF hooks if `src` filter false |

### .github/workflows/pr-title.yml

| Field | Detail |
|---|---|
| What it is | Semantic PR title validator |
| What it contains / does | `pull_request_target` opened/edited/synchronize; `amannn/action-semantic-pull-request`; subject must start uppercase; WIP allowed; no required scope |
| Why it matters | Keeps conventional/consistent PR titles |
| Notable details | Uses `pull_request_target` (runs in base context) |

### .github/workflows/plan-examples.yml

| Field | Detail |
|---|---|
| What it is | Manual terraform plan across patterns |
| What it contains / does | `workflow_dispatch` only; environment `EKS Blueprints Test`; only on `aws-ia/terraform-aws-eks-blueprints`; matrix from `plan-examples.py`; OIDC AWS us-west-2; terraform 1.0.0 init/plan per changed directory |
| Why it matters | Cheap validation that examples still plan |
| Notable details | Comments warn against checking out untrusted PR code for the python discovery step |

### .github/workflows/stale-issue-pr.yml

| Field | Detail |
|---|---|
| What it is | Stale issue/PR automation |
| What it contains / does | Daily cron + dispatch; stale after 30 days, close after 10 more; exempt `bug`/`enhancement`; custom messages |
| Why it matters | Keeps issue tracker from rotting |
| Notable details | Uses `actions/stale@main` |

### .github/workflows/e2e-parallel-full.yml

| Field | Detail |
|---|---|
| What it is | Full e2e apply/destroy matrix |
| What it contains / does | Manual dispatch with `TFDestroy` input (default true); prereq deletes `/aws/eks/` log groups; matrix of 7 patterns; uncomment remote backend; iamlive CSM capture; staged terraform apply/destroy targets; upload per-example policy JSON to S3; post job merges via `iam-policy-generator.py` |
| Why it matters | Real AWS validation of selected blueprints |
| Notable details | Patterns: agones, fargate, getting-started-argocd, ipv6, karpenter, multi-tenancy, stateful |

### .github/workflows/e2e-parallel-destroy.yml

| Field | Detail |
|---|---|
| What it is | Destroy-only e2e workflow |
| What it contains / does | Same pattern matrix as full e2e; OIDC; enable backend; staged destroy (addons → eks → all); no apply/iamlive |
| Why it matters | Cleanup stuck e2e state without re-applying |
| Notable details | Workflow name in file: `e2e-parallel-destroy-only` |

### .github/workflows/dependency-review.yml

| Field | Detail |
|---|---|
| What it is | PR dependency vulnerability review |
| What it contains / does | On pull_request; harden-runner; checkout; `dependency-review-action` (pinned SHAs) |
| Why it matters | Blocks known-vulnerable dependency bumps when required |
| Notable details | Comments explain required-check behavior |

### .github/workflows/scorecards.yml

| Field | Detail |
|---|---|
| What it is | OpenSSF Scorecard supply-chain analysis |
| What it contains / does | On branch protection, weekly Tuesday cron, push to main; scorecard-action SARIF; publish_results true; upload artifact + code scanning |
| Why it matters | Continuous supply-chain security score |
| Notable details | `permissions: read-all` default; security-events + id-token for upload/publish |

### .github/workflows/markdown-link-check.yml

| Field | Detail |
|---|---|
| What it is | Markdown link checker |
| What it contains / does | On push/PR to main when `**.md` changes; Node 20; `markdown-link-check@3.12.2`; runs on all `docs/**/*.md` with `linkcheck.json` |
| Why it matters | Prevents broken links in published docs |
| Notable details | Only scans `docs/`, not all repo markdown |

## Data flow map

```
Contributor / Maintainer
  │
  ├─ Root tooling
  │    README / LICENSE / NOTICE / CONTRIBUTING
  │    .pre-commit-config + cspell + .gitignore
  │
  ├─ docs/  ──mkdocs.yml + mkdocs-hooks.py──►  GitHub Pages
  │    index ← README
  │    getting-started / faq / snippets / v4-to-v5
  │    patterns/*.md ──include-markdown──► patterns/*/README.md
  │
  └─ .github/
       ISSUE/PR templates + CODEOWNERS + dependabot
       workflows:
         pre-commit / pr-title / link-check / dependency-review / scorecards
         publish-docs (main push)
         plan-examples (dispatch + plan-examples.py)
         e2e-full (delete-log-groups → apply+iamlive → S3 → iam-policy-generator)
         e2e-destroy (destroy only)
```

## Related files

| Path | Role |
|---|---|
| `/Users/k/Codes/GithubProjects/Terraform/terraform-aws-eks-blueprints-main/` | Source tree documented |
| `patterns/*/` | Actual Terraform pattern code included by many `docs/patterns/*.md` pages |
| `3.sh` | Companion command list for browsing this inventory |

## Commands

See [`3.sh`](./3.sh).


---

# SOURCE: agent/4-eks-blueprints-each-file-deep-dive/4-docs-files.md

# Docs Files Deep Dive

```
need to understand repo meta?
  README / CONTRIBUTING → how to consume and contribute
  docs/* → published site + FAQ + migration
  .github/* → CI, e2e, docs publish, issue templates
  unclear docs? → pattern README under patterns/ is source of truth
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| Scope | File-by-file deep dive for **Docs Files Deep Dive** |
| Source | terraform-aws-eks-blueprints-main |

## Summary

### docs/.pages

| Field | Detail |
|---|---|
| What it is | awesome-pages nav for docs root |
| What it contains / does | Order: Overview, Getting Started, Patterns, Snippets, v4 to v5 Migration, FAQ |
| Why it matters | Top-level docs navigation order |
| Notable details | Patterns/Snippets/v4-to-v5 are directories expanded by awesome-pages |

### docs/index.md

| Field | Detail |
|---|---|
| What it is | Docs home / Overview page |
| What it contains / does | Single `include-markdown` of `../README.md` |
| Why it matters | Keeps GitHub README and docs Overview in sync |
| Notable details | No extra body beyond the include |

### docs/getting-started.md

| Field | Detail |
|---|---|
| What it is | Getting started guide |
| What it contains / does | Prerequisites (awscli, kubectl, terraform); clone + `cd` into pattern; targeted apply VPC → EKS → full apply; `update-kubeconfig`; `kubectl get nodes`; destroy order (addons → eks → all); warnings for private clusters and resources created outside Terraform (e.g. Karpenter nodes) |
| Why it matters | Canonical first-run path for any pattern |
| Notable details | Points to Terraform Caveats for why targeted apply exists |

### docs/faq.md

| Field | Detail |
|---|---|
| What it is | Frequently asked questions |
| What it contains / does | Topics: VPC destroy timeouts (vpc-cni ENI leak cleanup order); leaked CloudWatch log groups (`create_cloudwatch_log_group` true/false tradeoffs); provider auth static token vs `exec()` with full HCL examples; stuck Terminating namespaces (orphan CRD resources, patch finalizers) |
| Why it matters | Day-2 failure modes users hit during apply/destroy |
| Notable details | Defaults examples to static tokens for ease; documents 15-minute token lifetime and `terraform refresh` |

### docs/cSpell_dict.txt

| Field | Detail |
|---|---|
| What it is | Custom spellcheck word list (~190 terms) |
| What it contains / does | Project jargon: agones, argocd, bottlerocket, karpenter, kubecost, irsa, efa, vllm, odcr, privatelink, etc. |
| Why it matters | Feeds `bpWords` for cspell so docs/patterns do not fail on domain terms |
| Notable details | Plain newline-separated words; referenced by root `cspell.config.yaml` |

### docs/_partials/destroy.md

| Field | Detail |
|---|---|
| What it is | Reusable destroy snippet |
| What it contains / does | Three `terraform destroy -target=...` commands (addons, eks, then all) plus link to getting-started destroy section |
| Why it matters | Shared teardown steps included by many pattern READMEs |
| Notable details | Included via `{% include-markdown %}` from pattern docs |

### docs/internal/ci.md

| Field | Detail |
|---|---|
| What it is | Internal CI setup notes for E2E |
| What it contains / does | Describes GitHub Actions using `configure-aws-credentials` + `setup-terraform`; CloudFormation for GitHub OIDC IAM role; attach `AdministratorAccess`; secret `ROLE_TO_ASSUME`; S3 backend for recoverability |
| Why it matters | How maintainers (or forks) wire AWS OIDC for e2e workflows |
| Notable details | Marked internal; not in top-level `.pages` nav (still in tree for maintainers) |

### docs/snippets/ipv4-prefix-delegation.md

| Field | Detail |
|---|---|
| What it is | Snippet: IPv4 prefix delegation on VPC CNI |
| What it contains / does | Explains raising pods-per-node; `before_compute = true` + `ENABLE_PREFIX_DELEGATION` / `WARM_PREFIX_TARGET`; verify via `kubectl describe ds aws-node` |
| Why it matters | Common IP density fix for dense workloads |
| Notable details | Warns wrong max-pods usually means CNI was not configured before nodes |

### docs/snippets/vpc-cni-custom-networking.md

| Field | Detail |
|---|---|
| What it is | Snippet: VPC CNI custom networking |
| What it contains / does | Secondary CIDRs, `AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG`, `ENIConfig` CRDs via `kubectl_manifest`, verification on aws-node env |
| Why it matters | Pattern for primary-CIDR exhaustion without redesigning the whole cluster |
| Notable details | Notes custom networking does not use primary ENI for pods (lower max pods) |

### docs/patterns/.pages

| Field | Detail |
|---|---|
| What it is | Patterns section nav |
| What it contains / does | Ordered list of pattern pages and subdirs (Auto Mode, GitOps, Machine Learning, Network, SSO variants, etc.) |
| Why it matters | Controls Patterns menu in published docs |
| Notable details | Titles differ slightly from some page front-matter titles |

### docs/v4-to-v5/.pages

| Field | Detail |
|---|---|
| What it is | Migration section nav |
| What it contains / does | Motivation → Cluster → Addons → Teams |
| Why it matters | Guides readers through v4→v5 migration docs |
| Notable details | Example TF lives under `example/` but is not listed in this `.pages` (linked from guides) |

### docs/v4-to-v5/motivation.md

| Field | Detail |
|---|---|
| What it is | Why v5 direction changed |
| What it contains / does | What worked (fast adoption, popular patterns); what failed (addon explosion, Terraform on-cluster limits, public API need, nested modules, competing cluster tools); v5 shifts to modular components + patterns-only repo; lists removals (cluster modules, KMS, EMR-on-EKS, irsa/helm-addon → addon module, teams → teams module, ArgoCD TF integration deferred); before/after repo trees |
| Why it matters | Explains why this repo is patterns, not an umbrella module |
| Notable details | Encourages `terraform-aws-eks` for cluster creation |

### docs/v4-to-v5/cluster.md

| Field | Detail |
|---|---|
| What it is | Cluster migration guide to EKS module v19.x |
| What it contains / does | Breaking changes (remove Blueprints cluster/KMS/EMR/teams modules); before (v4.32 `github.com/aws-ia/terraform-aws-eks-blueprints`) vs after (`terraform-aws-modules/eks/aws`) HCL; state/move guidance in longer body |
| Why it matters | Practical migration for cluster resources |
| Notable details | Points to `docs/v4-to-v5/example` for reference configs |

### docs/v4-to-v5/addons.md

| Field | Detail |
|---|---|
| What it is | Addons migration guide |
| What it contains / does | Marked under active development; skeleton before (`//modules/kubernetes-addons?ref=v4.32.1`) vs after (`aws-ia/eks-blueprints-addons/aws` `~> 1.0`); diff and placeholder state mv |
| Why it matters | Shows registry module path for addons in v5 |
| Notable details | Many sections still TODO placeholders |

### docs/v4-to-v5/teams.md

| Field | Detail |
|---|---|
| What it is | Teams migration guide |
| What it contains / does | Under active development; before embedded teams vs after `aws-ia/eks-blueprints-teams/aws` `~> 1.0`; diff + placeholder state mv |
| Why it matters | Points multi-tenancy users to standalone teams module |
| Notable details | TODO-heavy like addons guide |

### docs/v4-to-v5/example/README.md

| Field | Detail |
|---|---|
| What it is | Migration example folder title |
| What it contains / does | Single heading: `# Migration - v4 to v5` |
| Why it matters | Labels the companion TF example tree |
| Notable details | Minimal; real content is in `.tf` files |

### docs/v4-to-v5/example/main.tf

| Field | Detail |
|---|---|
| What it is | Shared supporting infra for migration example |
| What it contains / does | AWS provider, caller/AZ data, locals, VPC module (`~> 5.0`) with public/private subnets and k8s ELB tags |
| Why it matters | Common VPC used by v4 and v5 cluster examples |
| Notable details | Region hardcoded `us-west-2`; name `migration` |

### docs/v4-to-v5/example/v4.tf

| Field | Detail |
|---|---|
| What it is | Pre-migration (v4) cluster definition |
| What it contains / does | kubernetes provider with exec auth; `module.eks` from Blueprints `v4.32.1` with MNG, Fargate, self-managed NG, `map_roles` |
| Why it matters | Side-by-side “before” for migration |
| Notable details | Uses older output names like `eks_cluster_endpoint` / `eks_cluster_id` |

### docs/v4-to-v5/example/v5.tf

| Field | Detail |
|---|---|
| What it is | Post-migration (v5) cluster definition |
| What it contains / does | Same shape on `terraform-aws-modules/eks/aws` `~> 19.13` with `aws_auth_roles`, managed/fargate/self-managed groups, backwards-compat naming flags |
| Why it matters | Side-by-side “after” for migration |
| Notable details | Comments mark settings kept for backwards compatibility (IAM role names, KMS alias, log types) |

### docs/v4-to-v5/example/versions.tf

| Field | Detail |
|---|---|
| What it is | Terraform/provider version constraints for migration example |
| What it contains / does | TF `>= 1.0`; aws `>= 4.47`; kubernetes `>= 2.17` |
| Why it matters | Pins minimum tooling for the example |
| Notable details | No helm/kubectl providers declared here |

### Pattern docs pages (MkDocs wrappers)

Each file below is a short MkDocs page (YAML title + `include-markdown` of the pattern README). Content summarized is from the included README.

| Docs path | Included source | What the pattern is / does | Why it matters | Notable details |
|---|---|---|---|---|
| `patterns/agones-game-controller.md` | `patterns/agones-game-controller/README.md` | EKS + Agones for dedicated game servers; mentions GameLift FleetIQ | Gaming workload blueprint | Validate with sample gameserver + netcat UDP |
| `patterns/blue-green-upgrade.md` | `patterns/blue-green-upgrade/README.md` | Blue/green or canary migration across two EKS clusters via Route53 weighted routing, LBC, External DNS, ArgoCD apps-of-apps | Cluster cutover pattern | Stacks: environment, eks-blue, eks-green, shared module |
| `patterns/bottlerocket.md` | `patterns/bottlerocket/README.md` | Bottlerocket on MNG + Karpenter with Bottlerocket Update Operator for OS CVE patches | Hardened OS + automated patching | BRUPOP is patch-level only, not minor/major |
| `patterns/ecr-pull-through-cache.md` | `patterns/ecr-pull-through-cache/README.md` | ECR pull-through for Docker Hub, k8s, Quay, ECR; scan-on-push; addons use cached images | Faster/safer public image pulls | Needs `docker_secret` var for Docker Hub |
| `patterns/external-secrets.md` | `patterns/external-secrets/README.md` | External Secrets Operator with ClusterSecretStore/SecretStore (Secrets Manager + SSM) via IRSA | Secrets sync pattern | Includes `_partials/destroy.md` |
| `patterns/fargate-serverless.md` | `patterns/fargate-serverless/README.md` | Fully Fargate data plane; sample app; Fargate Fluent Bit logging ConfigMap | Serverless EKS dataplane | Validate Fargate node names + aws-logging CM |
| `patterns/fully-private-cluster.md` | `patterns/fully-private-cluster/README.md` | No internet; private endpoint; required VPC endpoints listed | Air-gapped / private-only clusters | Endpoint list includes ECR, STS, ELB, S3, etc. |
| `patterns/istio.md` | `patterns/istio/README.md` | EKS + Istio + ingress gateway (NLB); sample app; optional Kiali/Jaeger/Prometheus/Grafana | Service mesh starter | Requires ingress rollout restart due to istiod dependency issue |
| `patterns/karpenter.md` | `patterns/karpenter/README.md` | Karpenter controller on Fargate; includes highlighted TF/YAML from pattern files | Karpenter on serverless control nodes | Docs embed pattern `eks.tf` / `karpenter.tf` / yaml |
| `patterns/karpenter-mng.md` | `patterns/karpenter-mng/README.md` | Karpenter on tainted/labeled MNG; Pod Identity; SQS interruption queue | Karpenter with daemonset-friendly nodes | CoreDNS toleration avoids deadlock |
| `patterns/kubecost.md` | `patterns/kubecost/README.md` | Kubecost + AWS CUR billing integration; delayed CFN for crawler | Cost visibility on EKS | Needs `kubecost_token`; follow-up `run-me-in-24h/` |
| `patterns/multi-tenancy-with-teams.md` | `patterns/multi-tenancy-with-teams/README.md` | Teams isolation: team-red, team-blue, team-admin | Multi-tenant RBAC/namespace pattern | Validate section still TODO |
| `patterns/stateful.md` | `patterns/stateful/README.md` | Velero, EBS/EFS CSI, gp3 default SC, multi-volume + instance-store MNGs with CMK/gp3 | Stateful workload building blocks | Features optional; pick what you need |
| `patterns/sso-iam-identity-center.md` | `patterns/sso-iam-identity-center/README.md` | IAM Identity Center + EKS Access Entries/RBAC | AWS-native SSO into EKS | Uses `aws_ssoadmin_instances` data source |
| `patterns/sso-okta.md` | `patterns/sso-okta/README.md` | Okta OIDC IdP + Kubernetes RBAC | External IdP SSO | Uses kubectl oidc-login exec plugin |
| `patterns/eks-automode/eks-automode-custom-nodepools.md` | `patterns/eks-automode/automode-custom-nodepools/README.md` | EKS Auto Mode with custom NodeClass/NodePool (amd64/arm64/gpu); default pools disabled | Customize Auto Mode compute | YAML under `eks-automode-config/` |
| `patterns/gitops/gitops-getting-started-argocd.md` | `patterns/gitops/getting-started-argocd/README.md` | ArgoCD + GitOps Bridge (IaC metadata → Helm addons) | Intro GitOps on EKS | Optional fork of GitOps repos |
| `patterns/gitops/gitops-multi-cluster-hub-spoke-argocd.md` | `patterns/gitops/multi-cluster-hub-spoke-argocd/README.md` | Hub ArgoCD manages spoke clusters’ addons/workloads | Multi-cluster GitOps | Deploy hub then spokes; apps named `workloads-${env}` |
| `patterns/machine-learning/nvidia-gpu-efa.md` | `patterns/nvidia-gpu-efa/README.md` | `p5.48xlarge` + EFA + NVIDIA/EFA device plugins, RAID-0 NVMe | Multi-node GPU ML | Placement group + GPU taint/labels |
| `patterns/machine-learning/multi-node-vllm.md` | `patterns/multi-node-vllm/README.md` | Multi-node vLLM inference with LWS on `g6e.8xlarge` + EFA | Distributed inference | Includes Dockerfile for collective libs + ECR |
| `patterns/machine-learning/targeted-odcr.md` | `patterns/targeted-odcr/README.md` | Targeted ODCR via AZ-limited subnets, launch template capacity reservation, resource group | Guaranteed on-demand capacity | Screenshots copied into docs by mkdocs hook |
| `patterns/machine-learning/ml-container-cache.md` | `patterns/ml-container-cache/README.md` | Step Functions cache builder → EBS snapshot → mount at `/var/lib/containerd` | Faster large ML image starts | Claims ~5s vs ~6 min for large PyTorch image |
| `patterns/machine-learning/aws-neuron-efa.md` | `patterns/aws-neuron-efa/README.md` | `trn1.32xlarge` + Neuron + EFA plugins | Trainium/Inferentia-style ML | Neuron taint + RAID-0 NVMe |
| `patterns/machine-learning/ml-capacity-block.md` | `patterns/ml-capacity-block/README.md` | ML Capacity Block Reservation on MNG (`CAPACITY_BLOCK`) | Reserved ML capacity windows | AZ-restricted subnets + LT market options |
| `patterns/network/private-public-ingress.md` | `patterns/private-public-ingress/README.md` | Dual ingress-nginx (external + internal) with SG-backed NLBs | Split public/private ingress | Classes `ingress-nginx-external` / `ingress-nginx-internal` |
| `patterns/network/client-server-communication.md` | `patterns/vpc-lattice/client-server-communication/README.md` | VPC Lattice client↔server across VPCs via Gateway API Controller + external-dns | Service-to-service without classic peering complexity | Validate via Session Manager curl to `server.example.com` |
| `patterns/network/ipv6-eks-cluster.md` | `patterns/ipv6-eks-cluster/README.md` | IPv6 EKS networking | Dual-stack / IPv6 clusters | Pods/nodes show IPv6 addresses |
| `patterns/network/wireguard-with-cilium.md` | `patterns/wireguard-with-cilium/README.md` | Cilium chained with VPC CNI + WireGuard transparent encryption | Pod encryption overlay | Needs kernel 5.10+; NodeEncryption disabled in example |
| `patterns/network/privatelink-access.md` | `patterns/privatelink-access/README.md` | Access private EKS API via PrivateLink; SSM test from client EC2 | Private API access pattern | Targeted apply for eventbridge/nlb first |
| `patterns/network/aws-vpc-cni-network-policy.md` | `patterns/aws-vpc-cni-network-policy/README.md` | Native VPC CNI NetworkPolicy + Stars demo | NetworkPolicy without Calico/Cilium | Needs VPC CNI ≥ 1.14.0 |
| `patterns/network/cross-cluster-pod-communication.md` | `patterns/vpc-lattice/cross-cluster-pod-communication/README.md` | Secure multi-cluster Lattice with IAM auth, PCA TLS, Kyverno SigV4 sidecar, ExternalDNS | Cross-cluster with overlapping CIDRs | Blog-linked; bi-directional App1↔App2 |
| `patterns/network/tls-with-aws-pca-issuer.md` | `patterns/tls-with-aws-pca-issuer/README.md` | cert-manager + AWS Private CA issuer for TLS certs | Private PKI for cluster TLS | Validate Certificate Ready + TLS secret |

---

## Data flow map

```
Root README (contract)
  → docs/ (MkDocs site includes README + pattern READMEs)
  → .github/workflows (plan / e2e / publish-docs)
  → patterns/ (actual runnable HCL)
```

## Related files

| File | Role |
|------|------|
| Index | `4-eks-blueprints-each-file-deep-dive.md` |
| Commands | `4.sh` |

## Commands

See [4.sh](4.sh).
