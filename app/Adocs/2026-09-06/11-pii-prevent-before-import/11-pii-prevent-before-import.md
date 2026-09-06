# PII Prevent Before Log Import

```
No important PII in Dynatrace yet
  │
  ├─ Wait for real logs then scrub?
  │     → Too late: PII already in Grail / backups / shares
  │
  └─ Install gates NOW with your keyword list
        │
        ├─ Gate A App logger deny-list (blocklist keys)
        ├─ Gate B OneAgent Sensitive data masking (regex on keys)
        ├─ Gate C OpenPipeline fieldsRemove + content mask
        ├─ Gate D Fake JSON test → prove *** before go-live
        └─ Gate E Weekly DQL scan when real traffic starts
```

| Key point | Detail |
| --- | --- |
| Your situation | Important data is **not** in Dynatrace yet — best time to lock the door |
| What the keyword list is for | A **standing blocklist**, not a cleanup script for old logs |
| Goal | Future imported logs must not store raw PII values for those keys |
| Order | App deny → OneAgent mask → OpenPipeline remove/mask → fake test → weekly scan |
| Do not wait for | Production log volume before creating rules |

## Summary

You do not need existing PII in Dynatrace to prevent future PII. Treat `pii-keys-blocklist.txt` as a contract: apps must not emit those keys; Dynatrace must mask or drop them if they appear. Install OneAgent and OpenPipeline rules **before** host groups start shipping real policy logs. Prove with fake JSON that contains the keys; when real import starts, run the DQL scan.

## Investigation

| Check | What it means | Why you care |
| --- | --- | --- |
| Empty / low-value tenant today | Little or no real customer PII stored yet | Masking rules can be turned on with almost no cleanup debt |
| Keyword list exists | Names, DOB, address, phone, email, bank, staff keys | You already know which JSON field names are forbidden |
| Import not live yet | Host groups / log sources will grow later | Gates must be ready on day zero of import |
| Product/contract keys excluded | Premium, dates, product codes stay for ops | Do not over-mask until privacy approves |

## Result — what to do now (no real PII required)

### What this is

**PII** = personal data that can identify a person (name, birthday, phone, bank account).  
**Blocklist** = list of JSON **key names** that must never keep raw values in Dynatrace.  
**Grail** = Dynatrace storage where logs land after ingest. Once PII is there, cleanup is harder than blocking at the door.

### Why it matters

If you wait until “important” logs arrive, the first bad deploy can dump `policyHolderName` / `bankAccountNo` into Grail. Setting rules on an empty tenant means the first real line is already masked or dropped.

### Happy path (do this before import)

| Step | Action | Pass look like |
| --- | --- | --- |
| 1 | Copy blocklist into each app repo next to the logger | Developers see the deny list in code review |
| 2 | App: never log blocklist keys (omit key or write `***`) | Unit test fails if a forbidden key appears in log payload |
| 3 | OneAgent: Sensitive data masking for Wave A + B keys (start with top 20) | Fake log shows `"policyHolderName":"***"` |
| 4 | OpenPipeline: `fieldsRemove` for same keys + content regex mask | Same fake line still safe if OneAgent missed it |
| 5 | Send **fake** JSON only (never real customer data) | DQL finds keys only with `***` or zero raw values |
| 6 | Turn on real log import for host groups | Weekly scan stays clean |

### Gate A — App (strongest, use keywords as deny-list)

1. Keep `pii-keys-blocklist.txt` in the service (same list as this folder).
2. Before `log.info`, strip every key in the blocklist from maps / JSON.
3. Ban logging full request/response bodies in PRD.
4. Add a CI check: sample log fixtures must not contain raw blocklist keys.

**Good log for Dynatrace:**

```json
{
  "msg": "policy update",
  "policyId": "POL-10086",
  "result": "OK",
  "durationMs": 42
}
```

**Forbidden before import (even in test envs that ship to Dynatrace):**

```json
{
  "msg": "policy update",
  "policyHolderName": "山田太郎",
  "bankAccountNo": "1234567",
  "EmailAddress1": "taro@example.com"
}
```

### Gate B — OneAgent (safety net before bytes leave the host)

UI path:

`Settings → Collect and capture → Log monitoring → Configure log module → Sensitive data masking`

| Setting | Value |
| --- | --- |
| Scope | Prefer host-group (e.g. `C_ALJ_BU_…`) when apps are known; else environment for early lock |
| Masking type | STRING |
| Replacement | `***` |
| Search expression | `"KEY"\s*:\s*"(.*?)"` for each blocklist key |

Start with top keys: `policyHolder*`, `subscriber*`, `bankAccountNo`, phones, emails.  
Full regex list: `11-oneagent-pii-regex-waves.txt`.

Also enable generic email pattern if available in your tenant rules.

### Gate C — OpenPipeline (second net at ingest)

For the Logs pipeline that will receive future import:

| Rule type | Purpose |
| --- | --- |
| `fieldsRemove` | Drop attributes named like blocklist keys if they are separate fields |
| Content mask | Same `"KEY"\s*:\s*"(.*?)"` → replace capture with `***` |

Use `11-openpipeline-pii-rules.yaml` as the checklist of keys/rules. Apply top 20 first, then expand to full first-wave list after fake test passes.

### Gate D — Prove with fake traffic (do this while tenant is empty)

1. Write one fake log file or API log line that **intentionally** contains blocklist keys with dummy values (`TEST_USER`, `0000000`, `fake@example.com`).
2. Ingest only that fake line into a non-prod host group (or a dedicated test host).
3. Confirm in Logs/DQL: values are `***` or keys are gone.
4. Only then allow real application log paths.

Never use real customer data to “test” masking.

### Gate E — When real import starts

| Cadence | Action |
| --- | --- |
| First 24h | Run `pii-scan.dql` against new host groups |
| Weekly | Same scan; any raw hit = open incident + fix app + tighten rules |
| New app onboard | Must attach blocklist + masking scope before log enablement |

Standing rules:

| Rule | Meaning |
| --- | --- |
| R1 | Blocklist keys never logged raw in app |
| R2 | OneAgent masking on for those keys |
| R3 | OpenPipeline remove/mask on for those keys |
| R4 | Weekly DQL scan |
| R5 | No Related/product keys until privacy says so |
| R6 | New host group = gates before go-live |

### Common mistakes

| Mistake | What happens | Fix |
| --- | --- | --- |
| “No data yet, so skip Dynatrace rules” | First import dumps PII | Install OneAgent + OpenPipeline **now** |
| Only rely on app scrub | One bad release leaks | Keep Gate B + C |
| Mask all keys including product metadata | Ops loses useful fields | Stick to first-wave PII list |
| Test with real names/accounts | Creates the PII you wanted to avoid | Fake values only |
| Enable log ingest before rules | Race condition on day one | Rules first, then enable source |

## Data flow map

```
Future app log (JSON)
  │
  ▼
[Gate A] App logger
  omit / *** blocklist keys
  │
  ▼
[Gate B] OneAgent Sensitive data masking
  regex on "key":"value" → ***
  │
  ▼
[Gate C] OpenPipeline
  fieldsRemove + content mask
  │
  ▼
Grail (safe logs only)
  │
  ▼
[Gate E] DQL weekly scan (pii-scan.dql)
  raw hit? → fix app + tighten rules
```

## Related files

| File | Purpose |
| --- | --- |
| `pii-keys-blocklist.txt` | Keyword deny-list for apps and reviews |
| `11-oneagent-pii-regex-waves.txt` | OneAgent search expressions |
| `11-openpipeline-pii-rules.yaml` | OpenPipeline rule checklist |
| `pii-scan.dql` | Future verification query |
| `11.sh` | Optional check / path reminders (run yourself) |
| Sibling `8-dynatrace-pii-prevent-steps/` | Full prevent steps with examples |
| Sibling `9-oneagent-pii-masking-steps/` | Click-path for OneAgent UI |

## Commands

See [`11.sh`](11.sh). Review and run locally when needed; do not assume production changes until you execute them in your tenant UI.
