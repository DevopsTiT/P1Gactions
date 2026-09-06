# Dynatrace PII Prevent Step By Step

```
Prevent PII in Dynatrace logs (your key list)
  │
  ├─ Step 1 App     → stop logging blocklist keys + no full body in PRD
  ├─ Step 2 OneAgent → mask email / DOB / bank / phone before send
  ├─ Step 3 OpenPipeline → fieldsRemove + mask "key":"value" in content
  ├─ Step 4 Verify   → DQL scan = 0 hits on C_ALJ_BU_… host groups
  └─ Step 5 Runbook  → R1–R6 standing rules + weekly scan
```

| Question | Answer |
| --- | --- |
| Goal | Keep your listed PII keys out of **Grail** (or store only `***`) |
| Keys in scope | Your high-risk list only (no product/contract metadata wave) |
| Order | **App first**, then OneAgent, then OpenPipeline, then weekly scan |
| Real example below | Tax/payment JSON log containing `policyHolderName` + `bankAccountNo` |

## Summary

Prevention is layered. The app should never emit fields like `policyHolderName` or `subscriberDOB`. OneAgent and OpenPipeline catch leftovers. Weekly DQL proves the control still works on your `C_ALJ_BU_…` PRD host groups.

---

## Real example (before / after)

**Bad log line (do not allow in PRD):**

```json
{
  "msg": "policy update",
  "policyHolderName": "山田太郎",
  "policyHolderNameKana": "ヤマダタロウ",
  "subscriberDOB": "1980-01-15",
  "bankAccountNo": "1234567",
  "telephoneNumber": "09012345678",
  "EmailAddress1": "taro@example.com"
}
```

**Good log line (safe for Dynatrace):**

```json
{
  "msg": "policy update",
  "policyId": "POL-10086",
  "result": "OK",
  "durationMs": 42
}
```

If a leftover still arrives, OpenPipeline / OneAgent should turn values into `***` before Grail.

---

## Step 1 — App layer (strongest)

### 1.1 Put the deny-list in the service

Use your list (names, DOB, address, bank, phone, email, beneficiaries, employee names…).  
Store it next to the logger as `pii-keys-blocklist.txt` (same keys as Daily Files blocklist).

### 1.2 Java / Spring example (structured logging)

```java
// Pseudocode — redact before log
Set<String> PII_KEYS = loadBlocklist("pii-keys-blocklist.txt");

Map<String, Object> safe = new LinkedHashMap<>();
for (var e : payload.entrySet()) {
  if (PII_KEYS.contains(e.getKey())) {
    continue; // never log the key at all
    // or: safe.put(e.getKey(), "***");
  } else {
    safe.put(e.getKey(), e.getValue());
  }
}
log.info("policy update {}", objectMapper.writeValueAsString(safe));
```

### 1.3 Node.js example

```javascript
const piiKeys = new Set(fs.readFileSync("pii-keys-blocklist.txt", "utf8")
  .split("\n").map(s => s.trim()).filter(s => s && !s.startsWith("#")));

function scrub(obj) {
  if (!obj || typeof obj !== "object") return obj;
  const out = Array.isArray(obj) ? [] : {};
  for (const [k, v] of Object.entries(obj)) {
    if (piiKeys.has(k)) continue;
    out[k] = typeof v === "object" ? scrub(v) : v;
  }
  return out;
}

logger.info("policy update", scrub(req.body));
```

### 1.4 PRD rule for API bodies

| Do | Do not |
| --- | --- |
| Log `policyId`, status, latency, error code | Log full request/response JSON in PRD |
| Log correlation id | Log `policyHolderName`, `bankAccountNo`, addresses |

**Acceptance:** Code review rejects any new log of a blocklist key without Security approval.

---

## Step 2 — OneAgent sensitive data masking

**What this is:** Redact on the host **before** logs leave for Dynatrace.

### 2.1 UI path

1. Dynatrace → **Settings**
2. Search **Sensitive data masking** (Log monitoring / OneAgent)
3. Open **OneAgent** masking rules for logs

### 2.2 Enable built-in email

| Setting | Value |
| --- | --- |
| Email addresses | **On** |
| Scope | Your PRD process groups / host groups (`C_ALJ_BU_…`) if scoping exists |

Catches `EmailAddress1`, `mail`, `email` values that look like emails.

### 2.3 Add custom rules (real patterns)

Create regex rules that match JSON `"key":"value"` for high-risk keys.

| Rule name | Match idea (illustrative regex) | Replace with |
| --- | --- | --- |
| mask-policyHolderName | `"policyHolderName"\s*:\s*"[^"]*"` | `"policyHolderName":"***"` |
| mask-subscriberDOB | `"subscriberDOB"\s*:\s*"[^"]*"` | `"subscriberDOB":"***"` |
| mask-bankAccountNo | `"bankAccountNo"\s*:\s*"[^"]*"` | `"bankAccountNo":"***"` |
| mask-telephoneNumber | `"telephoneNumber"\s*:\s*"[^"]*"` | `"telephoneNumber":"***"` |
| mask-holderName | `"holderName"\s*:\s*"[^"]*"` | `"holderName":"***"` |

Repeat for the rest of your first-wave keys (Kana names, addresses, beneficiary names, etc.), or group by pattern families (`*Name*`, `*Address*`, `*Tel*`, `*DOB*`, `*mail*`, `*bank*`).

### 2.4 Test on one host group first

1. Pick `C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD` (or your exact id)
2. Emit a **synthetic** test log with fake PII (never real customer data)
3. Confirm in Dynatrace that values show as `***` (or key absent)

---

## Step 3 — OpenPipeline (central safety net)

**Path:** Settings → Process and contextualize → **OpenPipeline** → **Logs** → Pipelines → **Processing**

### 3.1 Route only your PRD host groups first

Matching condition example:

```text
in(dt.host_group.id, {
  "C_ALJ_BU_OS_A_INFRA_E_PRD_T_BAS",
  "C_ALJ_BU_BAP_A_HULFT_E_PRD_T_AF",
  "C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD",
  "C_ALJ_BU_MIDDLEWARE-SHARED-PROD"
})
```

### 3.2 Processor A — `fieldsRemove` (if JSON attributes exist)

When Dynatrace has already parsed attributes:

```text
fieldsRemove
  policyHolderName,
  policyHolderNameKana,
  policyOwnerNameKana,
  subscriberDOB,
  bankAccountNo,
  telephoneNumber,
  EmailAddress1,
  mail,
  email,
  insuredPersonKanjiName,
  contractPersonKanjiName,
  holderName,
  holderAddress,
  depositorName,
  deathBeneficiaryName,
  FirstName,
  LastName,
  PostalCode,
  HomeNumber
```

Extend with every key from your first-wave list that appears as a **field**, not only inside `content`.

### 3.3 Processor B — mask inside `content` string

When the whole JSON is one string field `content`:

1. Add **DQL** processor  
2. Same matching condition as 3.1  
3. Use `replacePattern` / replace for each critical key  

Example idea (one key):

```text
fieldsAdd content = replacePattern(
  content,
  "LD:k '\"policyHolderName\"\\s*:\\s*\"' LD:v '\"'",
  "\"policyHolderName\":\"***\""
)
```

Do the same for `subscriberDOB`, `bankAccountNo`, `telephoneNumber`, then roll out remaining keys in batches (names → addresses → bank → beneficiaries).

### 3.4 Processor C — optional drop

Only if a source is known to dump full policy payloads and cannot be fixed quickly:

- Drop record when `matchesPhrase(content, "\"policyHolderName\"")` **and** `log.source` is the bad dumper  
- Prefer mask/remove over drop when you still need ops signal

### 3.5 Save + sample test

Use OpenPipeline **sample data** with the “bad JSON” from the top of this doc. Confirm output is scrubbed, then **Save**.

---

## Step 4 — Verify (prove it works)

### 4.1 Positive test (fake data only)

1. App/host emits fake payload with blocklist keys  
2. Wait 1–5 minutes  
3. Run scan DQL (see `pii-scan.dql`)  

**Pass:** no clear-text values; keys absent or `***`.

### 4.2 Negative / regression scan (weekly)

```text
fetch logs, from: now()-7d
| filter in(dt.host_group.id, { /* your four C_ALJ_BU_… groups */ })
| filter matchesPhrase(content, "\"policyHolderName\"")
    or matchesPhrase(content, "\"bankAccountNo\"")
    or matchesPhrase(content, "\"subscriberDOB\"")
| limit 50
```

**Pass:** 0 rows with real values.  
**Fail:** open ticket → contain (tighten pipeline) → fix app → privacy process if Grail held real PII.

---

## Step 5 — Standing rules (runbook paste)

| ID | Rule | How you enforce |
| --- | --- | --- |
| R1 | New Name/Kana/Address/Tel/DOB/mail/bank fields → blocklist or approval | PR checklist |
| R2 | No PRD full-body API logging for insurance/payment | Code review + logging config |
| R3 | OpenPipeline mask required before new PRD host group log ingest | Platform change gate |
| R4 | Weekly DQL scan on `C_ALJ_BU_…` | Calendar + ticket on hits |
| R5 | Shared demos use masked views only | Dashboard / notebook policy |
| R6 | Confirmed PII in Grail = privacy incident | Contain → erase per policy → RCA |

---

## Suggested rollout order (practical)

| Day | Action |
| --- | --- |
| Day 1 | App scrub for top 20 keys (`policyHolder*`, `subscriber*`, `bankAccountNo`, phones, emails) |
| Day 1 | OneAgent email on + 5 custom JSON mask rules |
| Day 2 | OpenPipeline route + fieldsRemove + content mask for same top 20 |
| Day 3 | Expand to full first-wave list (your list above) |
| Day 4 | Verify with fake traffic + 24h scan |
| Weekly | R4 scan; never add Related/product keys until privacy says so |

---

## Investigation

Keys = user-provided first-wave list. Steps map to Dynatrace OneAgent masking + OpenPipeline processing and prior Daily Files PII guidance.

---

## Result

Follow **App → OneAgent → OpenPipeline → Verify → R1–R6**. Start with tax/payment host group and the top identity/bank keys, then expand to the full first-wave list you pasted.

---

## Data flow map

```
App scrub(blocklist)
  → OneAgent mask (email + custom JSON)
  → OpenPipeline (fieldsRemove + replacePattern)
  → Grail (clean)
  → Weekly DQL scan (detect regressions)
```

---

## Related files

| File | Purpose |
| --- | --- |
| `8-dynatrace-pii-prevent-steps.md` | This step-by-step |
| `../6-dynatrace-log-pii-identify-prevent/pii-keys-blocklist.txt` | First-wave keys |
| `../6-dynatrace-log-pii-identify-prevent/pii-scan.dql` | Detection query |
| Official | https://docs.dynatrace.com/docs/analyze-explore-automate/logs/lma-use-cases/methods-of-masking-sensitive-data |

## Commands

See [`8.sh`](./8.sh).
