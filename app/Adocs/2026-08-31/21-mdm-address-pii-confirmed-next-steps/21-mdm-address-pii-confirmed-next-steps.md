# MDM Address PII Confirmed Next Steps

## Decision tree

```
Saw address / Japanese text in MDM cleansing logs?
  │
  ├─ YES — this is a confirmed PII finding (not just inventory noise)
  │
  ├─ STOP spreading raw values
  │     Do not paste full content into chat, tickets, or email
  │     Screenshot only redacted fields (class name + host group)
  │
  ├─ COUNT how big the leak is (no more browsing random lines)
  │     summarize hit_count by host / log.source / class name
  │
  ├─ SCOPE the fix
  │     App change (stop logging Value= address)  ← best
  │     OneAgent sensitive-data masking on host
  │     OpenPipeline replacePattern at ingest
  │
  └─ RE-CHECK
        Re-run count query — hits should drop or show masked tokens
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| What you found | **Customer address** (and related cleansing params) logged in clear text |
| Where | Host group `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP` (Customer MDM) |
| Which code area | `jp.co.axa.mdm.ws.composite.axacleansingservice` — address cleansing BPs |
| Severity | Real PII in production logs — treat as a data-protection finding |
| Do not do next | Keep scrolling raw lines or export thousands of records |
| Do next | Count volume → pin host/file → mask / stop logging → re-verify |

---

## Summary

Your Dynatrace log viewer shows MDM **address cleansing** services writing request parameters that include an **address Value** (Japanese text). That is personally identifiable information in logs. Inventory already showed this host group as the noisiest. You have now confirmed a real leak pattern. Switch from browsing to **counting and fixing**.

---

## Main content

### What the screen is telling you (plain English)

| Piece on screen | Meaning |
| --- | --- |
| Status mostly INFO | App is logging normal activity, not only errors — so volume can be huge |
| Class names like `AXACleansingAddressBP` | Business process that cleans / normalizes addresses |
| `compositeTxn.CleansingService` | Transaction wrapper around cleansing |
| Text containing `address, Value = ...` | The sensitive part — actual address data in the log body |
| `dt.host_group.id` = `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP` | Confirms Customer MDM production APP group |
| “1K of 37xx records” (order of thousands) | Many matching lines in a short window — not a one-off |

**PII here** = address text (and often nearby name/ID fields in the same cleansing flow). Even if some characters look masked with `?`, Japanese name/address fragments in the same line still count as sensitive.

### Immediate hygiene (do this before more queries)

| Action | Why |
| --- | --- |
| Stop pasting full `content` into Slack/Teams/chat | Spreads PII outside Dynatrace access control |
| In tickets, write only: host group + class name + “address Value logged” | Enough for app owners without leaking data |
| Prefer count queries over opening more log lines | Reduces how much PII you personally view |
| Limit samples to **10** if you must confirm masking later | Caps exposure |

### Next DQL — count the address leak (copy-ready)

Run in **Logs and Events → Advanced**. These queries **count**; they do not dump addresses.

**A) How many address-style lines in MDM (24h)?**

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesPhrase(content, "axacleansingservice")
| filter matchesPhrase(content, "address")
| summarize hit_count = count()
```

**B) Which host and log file produce them?**

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesPhrase(content, "axacleansingservice")
| filter matchesPhrase(content, "address")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

**C) Which cleansing class is loudest?**

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesPhrase(content, "AXACleansingAddress")
| summarize hit_count = count(), by: { host.name }
| sort hit_count desc
```

**D) Broader: any `address, Value` pattern in MDM**

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP")
| filter matchesRegex(content, "(?i)address\\s*,\\s*Value\\s*=")
| summarize hit_count = count(), by: { host.name, log.source }
| sort hit_count desc
```

### How to talk to the app owner (ticket text you can reuse)

Use this style (no raw address):

```text
Finding: Customer MDM production logs include address request parameters in clear text.
Host group: C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP
Component: jp.co.axa.mdm.ws.composite.axacleansingservice (AXACleansingAddress* / CleansingService)
Evidence: Dynatrace Logs — INFO lines with "address, Value =" under cleansing BP classes
Ask: Stop logging full address Value at INFO; log only request id / status; or mask before write.
```

### Fix options (best → backup)

| Option | What it is | When to use |
| --- | --- | --- |
| 1. App / logger change | Do not log full address `Value` at INFO | Best — stops PII at the source |
| 2. OneAgent sensitive-data masking | Mask on the host before send to Dynatrace | Fast control while app fix is pending |
| 3. OpenPipeline `replacePattern` | Mask or drop at ingest before Grail | Central control for many hosts |
| 4. DQL display mask only | Hides in one query view | **Not enough** — data still stored |

Detail for options 2–3 lives in:

`2026-08-28/1-dynatrace-logs-pii-filter/`

Example masking direction (pattern idea — tune with Magaki / platform owner):

| Target | Mask idea |
| --- | --- |
| `address, Value = ...` | Replace value after `Value =` with `***` |
| Japanese address/name blocks next to cleansing params | Regex replace continuous Kanji/Kana runs in those lines |

### After masking — prove it

| Check | Pass if |
| --- | --- |
| Re-run count query A or D | `hit_count` drops a lot, **or** remaining lines show masked tokens only |
| Optional sample `limit 5` | You see `***` / redacted — not readable addresses |
| Master Query 1 (column L pack) | MDM row’s keyword / related hits trend down |

### Also check nearby (same MDM family)

| Look for | Why |
| --- | --- |
| Name / kana fields in same cleansing service | Same logger often dumps multiple params |
| `C_ALI_BU_MIDLWARE_A_CUSTMDMGM_E_PRD_T_APP` | Middleware twin of MDM |
| Filenet / HR groups from inventory | Same “payload in INFO log” habit |

Use Master Query 1 from the 2026-08-28 column L pack after you finish MDM scoping.

---

## Data flow map

```
MDM app (axacleansingservice)
   logs INFO: address, Value = <PII>
        |
        v
OneAgent → (should mask here) → OpenPipeline → Grail
        |
        v
Dynatrace Logs UI  ← you confirmed leak here
        |
        +--> Count by host/file (DQL)
        +--> Ticket app owner (no raw PII)
        +--> Mask / stop logging
        +--> Re-count to verify
```

---

## Related files

| File | Purpose |
| --- | --- |
| [21.sh](./21.sh) | Open related guides |
| [21-mdm-address-pii-confirmed-next-steps-follow.txt](./21-mdm-address-pii-confirmed-next-steps-follow.txt) | Chat-ready |
| Find PII next | `2026-08-31/20-find-pii-next-after-inventory/` |
| Masking stack | `2026-08-28/1-dynatrace-logs-pii-filter/` |
| Full PII DQL pack | `2026-08-28/19-dql-pii-all-queries-column-l/` |

---

## Commands

See [21.sh](./21.sh). DQL is UI-only — run in Dynatrace yourself.
