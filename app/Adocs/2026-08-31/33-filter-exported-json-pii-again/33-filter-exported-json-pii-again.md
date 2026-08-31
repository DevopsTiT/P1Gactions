# Filter Exported JSON PII Again

## Decision tree

```
Exported Dynatrace results to JSON — still noisy?
  │
  ├─ Prefer cleaner export first?
  │     Re-run DQL with Value= + not CleansingResult (seq 32)
  │     Then export fewer rows
  │
  ├─ Already exported JSON file?
  │     Second pass with jq or Python on content text
  │     KEEP: address/phone/name Value patterns
  │     DROP: CleansingResult / cleansing counters
  │
  └─ Need only metadata for ticket (safer)?
        Keep timestamp + host group + host.name + matched keyword
        Do NOT save full content with real addresses
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Yes, you can filter again | Treat export as a file; filter each record’s `content` string |
| Best tools | `jq` (fast) or small Python script (easier to read) |
| Keep | Lines with `Value =` + PII field, or JP labels |
| Drop | `CleansingResult`, pure service counters |
| Safety | Prefer redacted output; do not commit raw PII JSON to git |

---

## Summary

Export is only a snapshot. You can filter that JSON again locally the same way as DQL: keep value-like PII text, drop cleansing noise. Prefer tightening DQL before export when possible.

---

## Investigation

| What is in the export | Meaning |
| --- | --- |
| Array/list of log records | Usually fields like `timestamp`, `dt.host_group.id`, `host.name`, `content` |
| `content` | Often one big **string** (log line), sometimes with JSON-looking pieces inside |
| Noise rows | `CleansingResult`, `AXACleansingServiceBP` without `Value =` |
| Useful rows | `address, Value =`, `AddressKana`, `phoneNumber, Value =`, Person/Address field dumps |

Exact JSON shape depends on how you export (UI download vs API). Filter on the **`content`** field either way.

---

## Result — how to filter again

### Step 0 — safer DQL before export (optional but best)

Use seq 32 query B, then export. Less junk in the file.

### Step 1 — save export

Example path (change to yours):

```text
~/Downloads/dt-pii-export.json
```

### Step 2a — `jq` keep real PII-like rows

```bash
jq '[ .[] | select( (.content // .["content"] // "") | test("address, Value =|AddressKana|AddressKanji|person_fullname|given_name, Value =|family_name, Value =|holderName, Value =|phoneNumber, Value =|phone_number, Value =|mobileNumber, Value =|emailAddress, Value =|birthDate, Value =|myNumber, Value =|住所|電話番号|郵便番号|氏名"; "i") ) | select( (.content // "") | test("CleansingResult|cleansingResult") | not ) ]' ~/Downloads/dt-pii-export.json > ~/Downloads/dt-pii-filtered.json
```

If the file wraps records under a key (common):

```bash
jq '[ .records[]? // .data[]? // .[] | select( (.content // .["content"] // "") | test("address, Value =|AddressKana|person_fullname|phoneNumber, Value =|住所|電話番号"; "i") ) | select( (.content // "") | test("CleansingResult|cleansingResult") | not ) ]' ~/Downloads/dt-pii-export.json > ~/Downloads/dt-pii-filtered.json
```

### Step 2b — Python (clearer; handles more shapes)

See `33-filter-dt-json-pii.py`. Run:

```bash
python3 "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/33-filter-exported-json-pii-again/33-filter-dt-json-pii.py" ~/Downloads/dt-pii-export.json ~/Downloads/dt-pii-filtered.json
```

### Step 3 — safer redacted summary (for tickets)

```bash
python3 "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/33-filter-exported-json-pii-again/33-filter-dt-json-pii.py" ~/Downloads/dt-pii-export.json ~/Downloads/dt-pii-redacted.json --redact
```

Redacted mode keeps timestamp / host group / host / which keyword matched — **not** full address text.

---

## Data flow map

```
Dynatrace table
  → (optional) tighter DQL (seq 32)
  → Export JSON
  → jq or Python second filter on content
       KEEP Value=/AddressKana/phone…
       DROP CleansingResult
  → filtered.json  OR  redacted.json (ticket-safe)
```

---

## Related files

| File | Purpose |
| --- | --- |
| `33-filter-exported-json-pii-again-follow.txt` | Paste-ready commands |
| `33-filter-dt-json-pii.py` | Second-pass filter script |
| `33.sh` | One-liners |
| Seq 32 | Better DQL before export |

Commands: see `33.sh`.
