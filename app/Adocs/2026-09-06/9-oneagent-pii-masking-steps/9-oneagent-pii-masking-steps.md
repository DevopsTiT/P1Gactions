# OneAgent PII Masking Step By Step

```
OneAgent mask your PII keys?
  │
  ├─ Logs collected by OneAgent? → YES continue
  │   (API/Fluent-only ingest → use OpenPipeline instead)
  ├─ Where? Settings → Collect and capture → Log monitoring
  │         → Configure log module → Sensitive data masking
  ├─ Scope? Prefer HOST_GROUP = your C_ALJ_BU_… PRD groups first
  ├─ Rules? Regex per JSON "key":"value" → replace with ***
  └─ Prove? Fake test log → see *** in Dynatrace (never real customer data)
```

| Question | Answer |
| --- | --- |
| What OneAgent masking does | Redacts log text **on the host** before upload |
| UI path | **Settings → Collect and capture → Log monitoring → Configure log module → Sensitive data masking** |
| Masking types | **STRING** (`***`) or **SHA-256** (hash) |
| Your keys | First-wave list (`policyHolderName`, `bankAccountNo`, …) |
| Official doc | https://docs.dynatrace.com/docs/analyze-explore-automate/logs/lma-log-ingestion/lma-log-ingestion-via-oa/lma-sensitive-data-masking |

## Summary

In Dynatrace, open **Sensitive data masking**, create rules with a **regex** that matches each PII JSON field, set replacement to `***`, and attach **matchers** so only your PRD host groups / process groups are affected. Test with fake data. OneAgent never sends the clear value to Grail when the rule matches.

---

## Before you start

| Check | Why |
| --- | --- |
| Logs come via **OneAgent** | This menu only masks OneAgent-captured logs |
| You have Settings permission | Need rights to change log monitoring settings |
| Start on **one** host group | e.g. tax payment PRD — expand later |
| Use **fake** PII for tests | Never inject real customer names/accounts |

---

## Step 0 — Open the right settings page

1. Log in to Dynatrace.
2. Click **Settings** (gear).
3. Go to:  
   **Collect and capture** → **Log monitoring** → **Configure log module** → **Sensitive data masking**
4. Decide **scope** (important):

| Scope | When to use |
| --- | --- |
| **Environment** | Applies everywhere (simple, broader blast radius) |
| **Host group** | Best start: only `C_ALJ_BU_…` PRD groups |
| **Host** | Single-server pilot |

**Recommended:** set rules at **Host group** for:

- `C_ALJ_BU_BAP_A_TAXPAYMENT_E_PRD` (exact id as in your tenant)
- then HULFT / middleware / infra groups

How to open host-group scope (typical UI):

1. Settings → top-left **Go to entity** / select host group  
   **or** open the host group → Settings for that entity  
2. Then **Log monitoring → Sensitive data masking**  
3. Rules created here apply to that host group’s OneAgents

---

## Step 1 — Create your first rule (email values)

Emails appear in `mail`, `email`, `EmailAddress1`.

1. On **Sensitive data masking**, click **New rule** / **Add rule**.
2. Fill:

| Field | Value |
| --- | --- |
| Rule name | `pii-mask-email-generic` |
| Active / Enabled | On |
| Masking type | **STRING** |
| Replacement | `***` |
| Search expression | `\b[\w\-\._]+?@[\w\-\._]+?\.\w{2,10}\b` |

3. **Matchers** (narrow scope) — examples:

| Attribute | Operator | Values |
| --- | --- | --- |
| `log.source` | MATCHES | your app log path / name (if known) |
| `dt.entity.process_group` | MATCHES | tax/payment process group |
| `host.tag` | MATCHES | `env:prd` (if you tag hosts) |

If matchers are required and you want “all logs on this host group”, use the host-group scope and add a matcher that still matches your apps (or follow UI: empty/all as allowed).

4. Click **Save and close**.

5. Wait a few minutes for OneAgent to pick up config.

---

## Step 2 — Create JSON key rules (your PII fields)

OneAgent matches **text with regex**. For JSON logs, mask `"key":"value"`.

### Pattern template (copy for each key)

**Search expression** (capture the value only — one capture group):

```regex
"policyHolderName"\s*:\s*"(.*?)"
```

| Field | Value |
| --- | --- |
| Rule name | `pii-mask-policyHolderName` |
| Masking type | **STRING** |
| Replacement | `***` |
| Search expression | `"policyHolderName"\s*:\s*"(.*?)"` |

**Result in log:** `"policyHolderName":"***"`  
(Dynatrace replaces the **capture group** / matched sensitive part per docs behavior — verify with a test log; if the whole match is replaced, adjust to keep the key visible.)

### Alternative (replace whole key+value)

```regex
"policyHolderName"\s*:\s*"[^"]*"
```

Replacement string (if UI replaces full match): `"policyHolderName":"***"`

---

## Step 3 — Rules to create for your first-wave keys

Create **one rule per key** (or batch in waves). Use the same regex shape:

`"KEYNAME"\s*:\s*"(.*?)"`

### Wave A — identity (do these first)

| Rule name | Search expression |
| --- | --- |
| `pii-mask-policyHolderName` | `"policyHolderName"\s*:\s*"(.*?)"` |
| `pii-mask-policyHolderNameKana` | `"policyHolderNameKana"\s*:\s*"(.*?)"` |
| `pii-mask-policyOwnerNameKana` | `"policyOwnerNameKana"\s*:\s*"(.*?)"` |
| `pii-mask-policyOwnerDateOfBirth` | `"policyOwnerDateOfBirth"\s*:\s*"(.*?)"` |
| `pii-mask-policyHolderBirthDate` | `"policyHolderBirthDate"\s*:\s*"(.*?)"` |
| `pii-mask-subscriberDOB` | `"subscriberDOB"\s*:\s*"(.*?)"` |
| `pii-mask-insuredBirthDate` | `"insuredBirthDate"\s*:\s*"(.*?)"` |
| `pii-mask-insuredPersonKanjiName` | `"insuredPersonKanjiName"\s*:\s*"(.*?)"` |
| `pii-mask-insuredPersonKanaName` | `"insuredPersonKanaName"\s*:\s*"(.*?)"` |
| `pii-mask-insuredName` | `"insuredName"\s*:\s*"(.*?)"` |
| `pii-mask-insuredNameKana` | `"insuredNameKana"\s*:\s*"(.*?)"` |
| `pii-mask-contractPersonKanjiName` | `"contractPersonKanjiName"\s*:\s*"(.*?)"` |
| `pii-mask-contractPersonKanaName` | `"contractPersonKanaName"\s*:\s*"(.*?)"` |
| `pii-mask-holderName` | `"holderName"\s*:\s*"(.*?)"` |
| `pii-mask-holderNameKana` | `"holderNameKana"\s*:\s*"(.*?)"` |
| `pii-mask-FirstName` | `"FirstName"\s*:\s*"(.*?)"` |
| `pii-mask-LastName` | `"LastName"\s*:\s*"(.*?)"` |
| `pii-mask-employeeName` | `"employeeName"\s*:\s*"(.*?)"` |
| `pii-mask-requesterName` | `"requesterName"\s*:\s*"(.*?)"` |

### Wave B — contact + bank

| Rule name | Search expression |
| --- | --- |
| `pii-mask-EmailAddress1` | `"EmailAddress1"\s*:\s*"(.*?)"` |
| `pii-mask-mail` | `"mail"\s*:\s*"(.*?)"` |
| `pii-mask-email-key` | `"email"\s*:\s*"(.*?)"` |
| `pii-mask-telephoneNumber` | `"telephoneNumber"\s*:\s*"(.*?)"` |
| `pii-mask-policyNotificationTelNo` | `"policyNotificationTelNo"\s*:\s*"(.*?)"` |
| `pii-mask-HomeNumber` | `"HomeNumber"\s*:\s*"(.*?)"` |
| `pii-mask-holderTel` | `"holderTel"\s*:\s*"(.*?)"` |
| `pii-mask-bankAccountNo` | `"bankAccountNo"\s*:\s*"(.*?)"` |
| `pii-mask-bankOwnerNameKana` | `"bankOwnerNameKana"\s*:\s*"(.*?)"` |
| `pii-mask-depositorName` | `"depositorName"\s*:\s*"(.*?)"` |
| `pii-mask-depositorNameKana` | `"depositorNameKana"\s*:\s*"(.*?)"` |
| `pii-mask-PostalSavingsPassbookNo` | `"PostalSavingsPassbookNo"\s*:\s*"(.*?)"` |

### Wave C — address

| Rule name | Search expression |
| --- | --- |
| `pii-mask-subscriberAdress1` | `"subscriberAdress1"\s*:\s*"(.*?)"` |
| `pii-mask-subscriberAdress2` | `"subscriberAdress2"\s*:\s*"(.*?)"` |
| `pii-mask-subscriberAdress3` | `"subscriberAdress3"\s*:\s*"(.*?)"` |
| `pii-mask-subscriberAdress4` | `"subscriberAdress4"\s*:\s*"(.*?)"` |
| `pii-mask-subscriberZipCode` | `"subscriberZipCode"\s*:\s*"(.*?)"` |
| `pii-mask-holderKadress1` | `"holderKadress1"\s*:\s*"(.*?)"` |
| `pii-mask-holderAddress` | `"holderAddress"\s*:\s*"(.*?)"` |
| `pii-mask-holderAddress1` | `"holderAddress1"\s*:\s*"(.*?)"` |
| `pii-mask-holderKaddress` | `"holderKaddress"\s*:\s*"(.*?)"` |
| `pii-mask-holderZipCode` | `"holderZipCode"\s*:\s*"(.*?)"` |
| `pii-mask-policyNotificationAddress` | `"policyNotificationAddress"\s*:\s*"(.*?)"` |
| `pii-mask-PrimaryAddress` | `"PrimaryAddress"\s*:\s*"(.*?)"` |
| `pii-mask-AddressLine1` | `"AddressLine1"\s*:\s*"(.*?)"` |
| `pii-mask-PostalCode` | `"PostalCode"\s*:\s*"(.*?)"` |
| `pii-mask-PolicyAddress` | `"PolicyAddress"\s*:\s*"(.*?)"` |

### Wave D — beneficiaries + remaining names

Same pattern for:

`deathBeneficiaryName`, `deathBeneficiaryNameKana`, `maturityBeneficiaryName`, `maturityBeneficiaryNameKana`, `benefitBeneficiaryName`, `benefitBeneficiaryNameKana`, `designatedRepresentativeName`, `designatedRepresentativeNameKana`, `cancerBeneficiaryName`, `DisplayName`, `FirstNameKanji`, `LastNameKanji`, `given_name`, `family_name`, `name`, `oldName`, `oldNameKana`, `oldBirthDate`, `oneGenAgoName`, `twoGenAgoName`, `initialEmployeeName`, `employeeNameKana`, …

Full key file: `../6-dynatrace-log-pii-identify-prevent/pii-keys-blocklist.txt`

---

## Step 4 — Optional phone number generic rule

Besides key-based rules, add a JP-style mobile pattern (careful with false positives):

| Field | Value |
| --- | --- |
| Rule name | `pii-mask-jp-mobile` |
| Search expression | `0[789]0-?\d{4}-?\d{4}` |
| Replacement | `***` |
| Matchers | Same host group / process group |

---

## Step 5 — Test (required)

1. On a host in the scoped host group, write a **fake** log line your OneAgent collects, for example:

```text
{"msg":"test","policyHolderName":"TEST_NAME","bankAccountNo":"0000000","EmailAddress1":"fake@example.com"}
```

2. Wait 2–5 minutes.
3. Dynatrace → **Logs** → search `TEST_NAME` or `fake@example.com`.

| Result | Meaning |
| --- | --- |
| You find `***` / no clear name | Rule works |
| You still see `TEST_NAME` | Wrong scope, regex, or log not via OneAgent |

4. Also search the **key** `"policyHolderName"` — value must not be cleartext.

---

## Step 6 — Rule order and ops tips

| Tip | Detail |
| --- | --- |
| Order | Rules run in list order; put specific JSON-key rules before very broad regex |
| Scope wins | Host rule > host group > environment (more specific overrides) |
| SHA-256 vs STRING | Use **STRING `***`** for privacy demos; SHA-256 if you must correlate same value without showing it |
| One capture group | Dynatrace allows **max one** `(...)` group per expression |
| Escaping | In UI, paste regex as shown; test each rule |
| Not OneAgent? | Log Ingest API / Fluent Bit → mask in **OpenPipeline**, not this menu |

---

## Step 7 — Rollout checklist

| # | Action | Done? |
| --- | --- | --- |
| 1 | Open Sensitive data masking on **one** PRD host group | |
| 2 | Add email generic rule | |
| 3 | Add Wave A identity key rules | |
| 4 | Fake-data test passes | |
| 5 | Add Wave B contact/bank | |
| 6 | Add Wave C address | |
| 7 | Add Wave D beneficiaries / remaining | |
| 8 | Repeat host groups (HULFT, middleware, infra) | |
| 9 | Weekly DQL scan for regressions | |

---

## Investigation

UI path and rule schema from Dynatrace docs: Sensitive data masking in OneAgent (`builtin:logmonitoring.sensitive-data-masking-settings`). Keys = your first-wave PII list.

---

## Result

Click path: **Settings → Collect and capture → Log monitoring → Configure log module → Sensitive data masking** → New rule → regex `"key"\s*:\s*"(.*?)"` → replacement `***` → matcher/host-group scope → save → fake test.

---

## Data flow map

```
App writes log file / stdout
  → OneAgent Log module
  → Sensitive data masking rules (your regex)
  → Masked content only
  → Dynatrace / Grail
```

---

## Related files

| File | Purpose |
| --- | --- |
| `9-oneagent-pii-masking-steps.md` | This guide |
| `9-oneagent-pii-regex-waves.txt` | Copy-paste rule expressions |
| Blocklist | `../6-dynatrace-log-pii-identify-prevent/pii-keys-blocklist.txt` |
| Doc | https://docs.dynatrace.com/docs/analyze-explore-automate/logs/lma-log-ingestion/lma-log-ingestion-via-oa/lma-sensitive-data-masking |

## Commands

See [`9.sh`](./9.sh).
