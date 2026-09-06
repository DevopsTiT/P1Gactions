# Dynatrace Log PII Identify And Prevent

```
Someone pushes logs to Dynatrace — is there PII?
  │
  ├─ 1 SCAN now (DQL) → search your pii-keys in last 24h/7d
  ├─ 2 CLASSIFY hits → real PII vs false positive
  ├─ 3 CONTAIN → OpenPipeline mask/drop + OneAgent masking
  ├─ 4 STOP SOURCE → app must not log those JSON keys
  ├─ 5 CLEANUP if already in Grail → Sensitive Data Center / approved delete
  └─ 6 RULE forever → key blocklist + pipeline + code review checklist
```

| Question | Answer |
| --- | --- |
| What you asked | Check if PII is in Dynatrace logs; prepare how to identify / avoid / prevent |
| Keyword source | Your `pii keys.txt` (insurance/bank/name/address fields) |
| Host scope example | Your PRD host groups (`C_ALJ_BU_…`) |
| Best prevent | **Do not log** those keys → then **OpenPipeline** + **OneAgent** mask |
| Query-time mask only? | **Not enough** — raw may still sit in Grail |

## Summary

Treat log push as a **data pipeline**: anything in the log line can land in Dynatrace **Grail**. Use your keyword list to **scan** for PII already stored, then enforce **rules** so those fields are stripped or masked **before** storage. App fix is strongest; OpenPipeline is the central safety net for all ingest paths.

---

## 1. What is PII here (beginner)

| Term | Meaning |
| --- | --- |
| PII | Data that identifies a person (name, DOB, address, phone, email, bank account…) |
| Your keys | JSON / API field names like `policyHolderName`, `subscriberDOB`, `bankAccountNo` |
| Grail | Dynatrace store for ingested logs |
| OpenPipeline | Rules that run **at ingest** (mask/drop) before Grail |
| OneAgent masking | Redact on the host **before** send |

If a log contains `"policyHolderName":"山田太郎"`, that is PII in Dynatrace even if the key looks “technical.”

---

## 2. How to check NOW — is PII already in Dynatrace?

### Step A — Notebook / Logs DQL (scan)

Use your host groups (from your editor) and keyword list.

```text
fetch logs, from: now()-24h
| filter in(dt.host_group.id, {
    "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BAS",
    "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_AF",
    "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD",
    "C_ALJ_BU_MIDDLEWARE-SHARED-PROD"
  })
| filter
    matchesPhrase(content, "policyHolderName") or
    matchesPhrase(content, "policyOwnerNameKana") or
    matchesPhrase(content, "subscriberDOB") or
    matchesPhrase(content, "bankAccountNo") or
    matchesPhrase(content, "insuredPersonKanjiName") or
    matchesPhrase(content, "mail") or
    matchesPhrase(content, "EmailAddress1") or
    matchesPhrase(content, "telephoneNumber") or
    matchesPhrase(content, "policyNotificationTelNo")
| fields timestamp, dt.host_group.id, host.name, log.source, content
| sort timestamp desc
| limit 100
```

**How to read results**

| Result | Meaning | Next |
| --- | --- | --- |
| 0 rows | No hit for those phrases in scope/time | Widen time or add more keys; still deploy prevent rules |
| Rows with key + value | **PII likely present** | Contain + fix app + cleanup process |
| Key name only, value masked | Better, but confirm mask is at ingest not only UI | Keep rules |

Full key list for copy/paste: [`pii-keys-blocklist.txt`](./pii-keys-blocklist.txt)  
Longer DQL template: [`pii-scan.dql`](./pii-scan.dql)

### Step B — Classify each hit

| Class | Example | Action |
| --- | --- | --- |
| Clear PII | Name, DOB, address, tel, email, bank account | Mask/drop + stop logging |
| Sensitive business | Policy numbers, product codes | Follow your data class policy (often restrict) |
| False positive | Word `mail` in “email server up” | Tighten to JSON `"mail":` pattern |

Safer phrase shapes for JSON:

```text
matchesPhrase(content, "\"policyHolderName\"")
matchesPhrase(content, "\"subscriberDOB\"")
```

### Step C — If PII already stored

| Action | Tool |
| --- | --- |
| Confirm scope | DQL count by `log.source` / host group |
| Stop new ingest | OpenPipeline + app change |
| Cleanup existing | Sensitive Data Center / approved retention delete (org process) |
| Notify | Privacy / security per your incident process |

**DQL mask in a notebook does not delete Grail data.**

---

## 3. How to PREVENT (future rules) — defense in depth

```
App logger (do not emit pii keys)
  → OneAgent sensitive data masking
  → OpenPipeline (remove fields / replacePattern / drop)
  → Grail (should be clean)
  → DQL display mask (last safety net only)
```

| Layer | Rule idea | Prevents |
| --- | --- | --- |
| **1 App / API** | Deny-list: never log keys in `pii-keys-blocklist.txt` | PII never leaves app |
| **2 OneAgent** | Sensitive data masking (email, custom regex for `"bankAccountNo"\s*:\s*"[^"]+"`) | Raw not sent |
| **3 OpenPipeline** | `fieldsRemove` for structured attrs; DQL `replacePattern` on `content` | Central policy all channels |
| **4 Ingest allow-list** | Only approved log sources for PRD host groups | Shrink blast radius |
| **5 Governance** | PR checklist + periodic DQL scan job | Catches regressions |

Official: [Mask sensitive data in logs](https://docs.dynatrace.com/docs/analyze-explore-automate/logs/lma-use-cases/methods-of-masking-sensitive-data)

---

## 4. OpenPipeline rule patterns (use your keys)

**Navigation:** Settings → Process and contextualize → **OpenPipeline** → Logs → Pipelines → Processing

### Rule type A — Remove structured fields

If logs are JSON attributes:

```text
fieldsRemove
  policyHolderName,
  policyHolderNameKana,
  subscriberDOB,
  bankAccountNo,
  telephoneNumber,
  mail,
  EmailAddress1,
  insuredPersonKanjiName,
  contractPersonKanjiName
```

(Extend with full blocklist.)

### Rule type B — Mask inside `content` string (JSON in line)

Matching condition example (limit to your apps first):

```text
matchesValue(dt.host_group.id, "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD")
```

DQL processor sketch (mask value after a key):

```text
fieldsAdd content = replacePattern(content, "LD:key '\"policyHolderName\"\\s*:\\s*\"' LD:val '\"'", "\"policyHolderName\":\"***\"")
```

Repeat per high-risk key, or one broader pattern for `"<key>":"<value>"` for the blocklist family (`Name`, `Kana`, `Address`, `Tel`, `DOB`, `mail`, `bankAccount`).

### Rule type C — Drop whole record

If a log source is known to dump full policy payloads:

```text
# Drop record processor when:
matchesPhrase(content, "\"policyHolderName\"") and matchesPhrase(log.source, "policy-dump")
```

Use sparingly — you lose troubleshooting context; prefer field remove/mask.

### Rule type D — OneAgent (capture-time)

1. Settings → Log monitoring → Sensitive data masking (OneAgent)  
2. Enable built-in **email** (and payment card if relevant)  
3. Add custom rules for `"bankAccountNo"`, `"subscriberDOB"`, phone patterns  
4. Scope to PRD process groups / host groups  

---

## 5. Operating RULES (what to write in the runbook)

| # | Rule | Owner |
| --- | --- | --- |
| R1 | Any new log field matching `*Name*`, `*Kana*`, `*Address*`, `*Tel*`, `*DOB*`, `*mail*`, `*bank*` must be on blocklist or approved | App + Security |
| R2 | No full request/response body logging in PRD for insurance/payment APIs | App |
| R3 | OpenPipeline mask rules required before new host group joins Dynatrace log ingest | Platform |
| R4 | Weekly DQL scan with `pii-scan.dql` on PRD host groups; ticket if hits > 0 | SRE |
| R5 | Dashboard / notebook queries that show `content` must use masked views for shared demos | All |
| R6 | Finding PII in Grail = privacy incident process (contain → erase per policy → RCA) | Security |

---

## 6. Keyword categories (from your pictures)

| Category | Example keys | Risk |
| --- | --- | --- |
| Names (Kanji/Kana) | `policyHolderName`, `insuredPersonKanjiName`, `employeeNameKana` | High |
| Birth date | `subscriberDOB`, `policyHolderBirthDate`, `insuredBirthDate` | High |
| Address / zip | `subscriberAdress1`, `holderAddress`, `PostalCode` | High |
| Contact | `mail`, `EmailAddress1`, `telephoneNumber`, `policyNotificationTelNo` | High |
| Bank | `bankAccountNo`, `bankCode`, `depositorNameKana` | High |
| Beneficiaries | `deathBeneficiaryName`, `cancerBeneficiaryName` | High |
| Staff / org | `salesPerson1`, `personInCharge` | Medium–High (often personal) |
| Product codes only | `basicProductCoverageCode`, `contractDate` | Usually lower — confirm with privacy |

Exact spellings from your file (including typos like `subscriberAdress1`, `holderKadress1`) are kept in the blocklist — scanners must match **real log keys**.

---

## Investigation

Built from user `pii keys.txt` screenshots + existing Daily Files `2026-08-28/1-dynatrace-logs-pii-filter` + host-group filter visible in user’s DQL editor.

---

## Result

1. **Scan now** with DQL + blocklist on your PRD host groups.  
2. **Prevent** with app deny-list + OpenPipeline + OneAgent.  
3. **Govern** with weekly scan and R1–R6 rules.  
4. Do not rely on query-only masking for compliance.

---

## Data flow map

```
App emits log (may include pii keys)
        │
        ├─ BAD: raw → Dynatrace ingest → Grail (PII stored)
        │
        └─ GOOD:
              App strips keys
                → OneAgent masks leftovers
                → OpenPipeline removes/masks
                → Grail clean
                → Analyst DQL (optional display mask)
```

---

## Related files

| File | Purpose |
| --- | --- |
| `pii-keys-blocklist.txt` | Deduped keys from your examples |
| `pii-scan.dql` | Detection query template |
| `6-openpipeline-pii-rules.yaml` | Rule checklist for implementers |
| Prior deep dive | `Daily Files/2026-08-28/1-dynatrace-logs-pii-filter/` |

## Commands

See [`6.sh`](./6.sh) — open docs / files only; run DQL in Dynatrace UI yourself.
