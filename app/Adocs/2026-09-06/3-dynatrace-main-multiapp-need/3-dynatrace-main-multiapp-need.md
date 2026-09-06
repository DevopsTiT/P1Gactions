# Main Multi-App Dashboard Need

```
Dynatrace.txt need?
  │
  ├─ One main board for multi apps (not many boards) → YES ($app filter)
  ├─ Select EIP → multi servers + logs + errors → YES
  ├─ Windows + Linux hosts on same board → YES
  ├─ All = monitor everything; EIP = filter only → YES (no EIP-only board)
  └─ AI root cause right away → YES (Davis row first)
```

| Dynatrace.txt line | How this dashboard satisfies it |
| --- | --- |
| One main Dashboard, multi apps, instead of multi dashboards | **One** import: `Main-MultiApp-Health-Dashboards.json` |
| Select eip → multi servers, logs, errors display | Variable `app=EIP` filters hosts table + logs + error tiles |
| One dashboard has more host / Windows / Linux | Servers table + Windows CPU + Linux CPU + Memory |
| Main monitor everything; EIP dedicated = only filter | `All` = everything; `EIP` = same tiles, filtered — **no second board** |
| AI root cause right away; avoid repetitive all apps | Davis open-count + Problems + **AI Root Cause** row at top |

## Summary

Your notes ask for **one main board** that covers every app, and when you pick **EIP** it should narrow to that app’s servers, logs, and errors — not open a second dashboard. This JSON does that with variable `$app`, puts **Davis AI root cause** at the top for fast detection, and keeps **Windows + Linux** on the same screen.

---

## Import (preferred)

**File:** [`Main-MultiApp-Health-Dashboards.json`](./Main-MultiApp-Health-Dashboards.json)

1. Dynatrace → **Dashboards** (new)
2. Create dashboard → **Edit JSON** / Upload
3. Paste this file → Save
4. Name it e.g. `Main-MultiApp-Health`
5. Use **app**: `All` (everything) or `EIP` / `API` / `Payment` (filter only)

---

## Behavior when you select EIP

| Area | What you should see |
| --- | --- |
| Open problems / Problems / AI Root Cause | Only problems related to EIP (title / entities) |
| Requests / Errors / Response Time | EIP services |
| Servers / Hosts (multi) | **Multiple** EIP hosts with CPU/mem/OS |
| Windows CPU / Linux CPU / Memory | EIP hosts split by OS |
| Error Logs / Exception Traces | EIP-related ERROR / Exception lines |
| DB / External | EIP-related backends |

`All` removes the name filter so the **same** tiles show the whole estate.

---

## Prerequisite (so filters work)

| Action | Why |
| --- | --- |
| Tag hosts + services `app:eip`, `app:api`, `app:payment` | Stable filtering |
| Include EIP/API/Payment in entity **names** when possible | `$app` uses `contains(name, …)` |
| OneAgent + log ingest | Servers / logs tiles light up |
| Do **not** clone this board per app | That recreates the “multi dashboards” problem you want to avoid |

---

## Investigation

Mapped each line of `Dynatrace.txt` (Notepad++) to dashboard design. Updated prior layout JSON: added open-problem single value, multi-host table, stronger top markdown (one board / filter-only), case-insensitive app filter.

---

## Result

Import **`Main-MultiApp-Health-Dashboards.json`**. Use **`All`** for global watch; switch to **`EIP`** to filter servers/logs/errors — still one dashboard.

---

## Data flow map

```
app=All  → all Problems + all hosts + all logs (quick detect everything)
app=EIP  → same tiles, filtered to EIP servers / logs / errors / RCA
        → Windows CPU + Linux CPU still on THIS board
Davis row (top) → open count → problems → AI root cause
```

---

## Related files

| File | Purpose |
| --- | --- |
| `Main-MultiApp-Health-Dashboards.json` | Import this |
| Prior layout JSON | `../2-dynatrace-dashboard-layout-json/` (layout visual only) |
| `3.sh` | Open JSON path |

## Commands

See [`3.sh`](./3.sh).
