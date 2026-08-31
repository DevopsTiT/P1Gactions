# DQL Show Address Log Lines

## Decision tree

```
Want to SEE log lines that may contain address text (not counts)?
  │
  ├─ Use fields + limit (no summarize)
  │
  ├─ Start broad → then narrower
  │     axacleansingservice
  │     AXACleansingAddress / AddressKana
  │     address, Value =
  │     Type = address
  │
  └─ Always limit 20–50
        Treat content as sensitive — do not export bulk
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Goal | Show log **text** that looks like address PII |
| Pattern | `fetch` → `filter` → `fields ... content` → `limit` |
| Do not use | `summarize` / `count()` (that only counts) |
| Safe default | `limit 20` (raise only if needed) |
| Your example line | Has `AXACleansingAddressBP` and `AddressKana` |

---

## Summary

To find address-like logs, filter on cleansing / address words and **display** `timestamp`, host group, host, and `content`. Start with the package name, then tighten to `AddressKana`, `address, Value =`, or `Type = address`. Keep a small `limit` so you do not pull thousands of personal records.

---

## Main content

### Where to run

Logs and Events → **Advanced** (or New Logs DQL bar) → paste → Run → Table.

### A) Same style as your screenshot (cleansing + show lines)

Use your working host group (copy from Attributes if needed):

```text
fetch logs, from: now()-30m
| filter matchesValue(dt.host_group.id, "C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP")
| filter contains(content, "axacleansingservice")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

If that host group fails, drop the host-group line and search content only:

```text
fetch logs, from: now()-30m
| filter contains(content, "axacleansingservice")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

### B) Address cleansing class (like your sample)

```text
fetch logs, from: now()-30m
| filter contains(content, "AXACleansingAddress")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

### C) AddressKana (exact token from your sample)

```text
fetch logs, from: now()-30m
| filter contains(content, "AddressKana")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

### D) `address, Value =` (clear address parameter)

```text
fetch logs, from: now()-30m
| filter contains(content, "address, Value =")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

### E) `Type = address` (REQ PARAM style from earlier samples)

```text
fetch logs, from: now()-30m
| filter contains(content, "Type = address")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

### F) Several address words in one filter (still shows lines)

```text
fetch logs, from: now()-30m
| filter matchesRegex(content, "(?i)(AddressKana|AddressKanji|AXACleansingAddress|address\\s*,\\s*Value\\s*=|Type\\s*=\\s*address|PERSON_ADDRESS|OFFICE_ADDRESS|kanjiFullAddress|holderAddress)")
| fields timestamp, dt.host_group.id, host.name, content
| limit 30
```

### G) MDM only + address words (show lines)

```text
fetch logs, from: now()-30m
| filter contains(dt.host_group.id, "CUSTMDMGM")
| filter matchesRegex(content, "(?i)(AddressKana|AXACleansingAddress|address\\s*,\\s*Value\\s*=|Type\\s*=\\s*address)")
| fields timestamp, dt.host_group.id, host.name, content
| limit 30
```

### H) Widen time (if 30m is thin)

Change only the first line:

```text
fetch logs, from: now()-24h
```

Keep `limit 20` unless you truly need more.

### Optional: sort newest first

If your tenant supports it:

```text
fetch logs, from: now()-30m
| filter contains(content, "AddressKana")
| sort timestamp desc
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

### What you will see

| Column | Meaning |
| --- | --- |
| `timestamp` | When the log was written |
| `dt.host_group.id` | Which app group |
| `host.name` | Which server |
| `content` | Full log text (may include address / kana — sensitive) |

### Safety

| Rule | Why |
| --- | --- |
| Always use `limit` | Stops dumping thousands of addresses |
| Do not bulk-export `content` | Spreads PII |
| For tickets, describe pattern only | e.g. “AddressKana / address, Value = in axacleansingservice” |
| Prefer screenshots redacted | Hide the Value text |

---

## Data flow map

```
fetch logs (30m or 24h)
   → filter address-like words in content
   → fields timestamp, host group, host, content
   → limit 20
   = SHOW lines (not counts)
```

---

## Related files

| File | Purpose |
| --- | --- |
| [28.sh](./28.sh) | Open this guide |
| [28-dql-show-address-log-lines-follow.txt](./28-dql-show-address-log-lines-follow.txt) | Chat-ready |
| Count queries (if needed later) | seq 22 / 26 |

---

## Commands

See [28.sh](./28.sh).
