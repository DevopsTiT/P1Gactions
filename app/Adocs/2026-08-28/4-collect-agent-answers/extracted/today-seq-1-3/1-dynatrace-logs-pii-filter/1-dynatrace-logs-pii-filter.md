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
