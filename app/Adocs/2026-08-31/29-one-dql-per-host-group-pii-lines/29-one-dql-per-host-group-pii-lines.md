# One DQL Per Host Group PII Lines

## Decision tree

```
Need one DQL per host group that SHOWS name/address PII lines?
  Open 29-one-dql-per-host-group-pii-lines.dql
  Run ONE block at a time (01, 02, 03…)
  Empty on C_ALI_… ?
    Try 01b (ALJ/DATAENGLF) or fragment template below
  Want each server (host.name) not host group?
    Use “per host.name” template at bottom
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Deliverable | **One show-lines DQL per host group** (name + address PII words) |
| File | `29-one-dql-per-host-group-pii-lines.dql` |
| Output | `timestamp`, `dt.host_group.id`, `host.name`, `content` — **limit 20** |
| Not included | `summarize` / hit counts |
| PII words | contains: AddressKana, AXACleansingAddress/PersonName, address Value, holderName, given_name, etc. |
| Filter style | **contains OR list only** (no matchesRegex / no `\s`) |

---

## Summary

Each query pins one Magaki-related host group, filters log text for name/address-like patterns, and returns up to 20 matching lines. Run them one by one. If an exact `C_ALI_BU_...` ID fails, use the fragment template or the MDM `C_ALJ_BU_DATAENGLF_...` variant (01b).

---

## Main content

### How to run

| Step | Action |
| --- | --- |
| 1 | Open the `.dql` file |
| 2 | Copy **one** block only (from `fetch` to `limit 20`) |
| 3 | Paste into Logs → Advanced → Run |
| 4 | Table view — read `content` carefully (sensitive) |
| 5 | Time range is **last 24 hours** (`now()-24h`) |

### Host groups included

| # | App | Host group ID in file |
| --- | --- | --- |
| 01 | MDM APP | `C_ALI_BU_DATAENGI_A_CUSTMDMGM_E_PRD_T_APP` |
| 01b | MDM APP Excel variant | `C_ALJ_BU_DATAENGLF_A_CUSTMDMGM_E_PRD_T_APP` |
| 02 | MDM middleware | `C_ALI_BU_MIDLWARE_A_CUSTMDMGM_E_PRD_T_APP` |
| 03 | HR | `C_ALI_BU_HR_A_PSOFTHRMG_E_PRD_T_APP` |
| 04–05 | EIP APP/DB | `..._EIP_E_PRD_T_APP` / `_DB` |
| 06 | HULFT | `..._HULFT_E_PRD_T_APP` |
| 07 | FTP SSTB | `..._FTPSSBTB_E_PRD_T_APP` |
| 08 | DFS | `..._DFS_E_PRD_T_APP` |
| 09 | IWFM | `..._IWFM_E_PRD_T_APP` |
| 10 | UDM | `..._UDM_E_PRD_T_APP` |
| 11–12 | ETL batch | APP + DB |
| 13–14 | Filenet | APP + DB |
| 15 | LoadRunner | `..._LOADRUNNR_E_PRD_T_APP` |
| 16–17 | Tax | APP + DB |
| 18 | Policy ODS | `..._POLICYODS_E_PRD_T_DB` |
| 19 | BICCIPSIM | `..._BICCIPSIM_E_PRD_T_DB` |
| 20–21 | DAMPOSHIN | BCCALC + CANWEB DB |
| 22 | HATS | shared-product HATS APP |

### Template (any host group)

```text
fetch logs, from: now()-24h
| filter matchesValue(dt.host_group.id, "PASTE_EXACT_HOST_GROUP_ID")
| filter (
    contains(content, "AddressKana")
    or contains(content, "address, Value =")
    or contains(content, "person_fullname")
    or contains(content, "Type = address")
    or contains(content, "holderName")
    or contains(content, "given_name")
    or contains(content, "family_name")
  )
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

### Fragment template (when Excel ID is wrong)

```text
fetch logs, from: now()-24h
| filter contains(dt.host_group.id, "PASTE_FRAGMENT")
| filter (
    contains(content, "AddressKana")
    or contains(content, "address, Value =")
    or contains(content, "person_fullname")
    or contains(content, "holderName")
    or contains(content, "given_name")
    or contains(content, "family_name")
  )
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

Fragment examples: `CUSTMDMGM`, `HULFT`, `FILENET`, `PSOFTHRMG`, `ETLPCBTCH`, `EIP_`.

### Per server (`host.name`) — if you meant each host machine

```text
fetch logs, from: now()-24h
| filter matchesValue(host.name, "PASTE_HOST_NAME")
| filter (
    contains(content, "AddressKana")
    or contains(content, "address, Value =")
    or contains(content, "person_fullname")
    or contains(content, "holderName")
    or contains(content, "given_name")
    or contains(content, "family_name")
  )
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

Example host from your MDM runs: `CEAA2116.piprivmgmt.intraxa`.

### Safety

| Rule | Why |
| --- | --- |
| `limit 20` | Caps how much PII you load |
| One host group per run | Keeps review focused |
| Do not bulk-export | Spreads name/address data |

---

## Data flow map

```
Pick host group block from .dql
   → filter PII name/address regex
   → fields content
   → limit 20
   = sample lines for that group only
```

---

## Related files

| File | Purpose |
| --- | --- |
| [29-one-dql-per-host-group-pii-lines.dql](./29-one-dql-per-host-group-pii-lines.dql) | All per-group queries |
| [29-one-dql-per-host-group-pii-lines-follow.txt](./29-one-dql-per-host-group-pii-lines-follow.txt) | Chat-ready |
| [29.sh](./29.sh) | Open files |

---

## Commands

See [29.sh](./29.sh).
