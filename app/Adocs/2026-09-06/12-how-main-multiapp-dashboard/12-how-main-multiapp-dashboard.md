# How Main Multi-App Dashboard

```
Dynatrace.txt need
  │
  ├─ One main board (multi apps) — not one board per app
  │     → Create ONE dashboard + variable $app
  │
  ├─ Select EIP → multi servers + logs + errors
  │     → Same board; filter every tile by $app == EIP
  │
  └─ How to do it
        Tag hosts/services → Import JSON → Pick EIP → Verify tiles
```

| Key point | Detail |
| --- | --- |
| What you want | One dashboard for all apps; picking EIP only **filters** |
| What you do not want | Separate EIP / API / Payment dashboards |
| Fast path | Import `Main-MultiApp-Health-Dashboards.json`, then tag entities |
| EIP click result | Multi hosts table + Windows/Linux CPU + Error Logs + Exceptions |

## Summary

Your note means: build **one** Dynatrace board with an **app** dropdown (`All` / `EIP` / `API` / `Payment`). Choosing **EIP** must refresh the same tiles so you see that app’s many servers, logs, and errors — not open another dashboard. Tagging (or clear names) makes the filter work.

## Investigation

| Need from Dynatrace.txt | How we implement it |
| --- | --- |
| One main Dashboard, multi apps | Single JSON with variable `app` |
| Instead of multi dashboards | Do not clone the board per app |
| Select eip → multi servers | Hosts table filtered by name/tag containing EIP |
| Logs, errors display | Error Logs + Exception + Errors KPI use same `$app` filter |

## Result — step by step

### What this is

A **dashboard variable** is a dropdown at the top of the board. Every chart reads `$app`. When `$app` is `All`, tiles show everything. When `$app` is `EIP`, tiles keep only EIP-related entities.

### Why it matters

L1 watches one screen. Switching app is one click. You avoid maintaining five nearly identical boards.

### Step 0 — Prerequisites (do once)

| Step | Action | Pass means |
| --- | --- | --- |
| 0.1 | OneAgent (or OTel) on EIP / API / Payment hosts | Hosts and services appear in Dynatrace |
| 0.2 | Tag services and hosts | `app:eip`, `app:api`, `app:payment` |
| 0.3 | Prefer names that include EIP / API / Payment | Name filter works even before tags |
| 0.4 | Log ingest on for those hosts | Error Logs tile can fill |

How to tag (UI idea):

1. Dynatrace → host or service → **Settings / Tags**
2. Add tag key `app`, value `eip` (lowercase is fine; dashboard matches case-insensitive on names)
3. Repeat for every EIP server and EIP service

### Step 1 — Import the one main board

**File:** `Main-MultiApp-Health-Dashboards.json` (this folder)

1. Open Dynatrace → **Dashboards** (new Dashboards app)
2. **Create dashboard** (or **Upload** / **Import** if your tenant shows it)
3. Open **Edit** → **Dashboard JSON** / **Code** (wording varies)
4. Paste the full JSON from the file → **Save**
5. Rename to e.g. `Main-MultiApp-Health`

If JSON import is blocked:

1. Create empty dashboard
2. Add variable `app` type list: `All,EIP,API,Payment` (default `All`)
3. Add tiles top to bottom using the queries inside the JSON (Problems → KPIs → Hosts → Logs → DB)

### Step 2 — Use it like your note says

| You select | What the board does |
| --- | --- |
| `app = All` | Whole estate: problems, servers, logs, errors |
| `app = EIP` | **Same** tiles, filtered: EIP multi servers + EIP logs + EIP errors |
| `app = API` / `Payment` | Same pattern for those apps |

**Do not** create `EIP-Health`, `API-Health`, `Payment-Health` clones.

### Step 3 — Verify EIP works

With `app = EIP`, check:

| Tile | Expect |
| --- | --- |
| Open problems / Problems / AI Root Cause | EIP-related problems (or empty if none open) |
| Requests / Errors / Response Time | EIP services only |
| Servers / Hosts (multi) | **Several** EIP hosts (CPU + mem + OS) |
| Windows CPU / Linux CPU / Memory | EIP hosts split by OS on **this** board |
| Error Logs / Exception Traces | ERROR / Exception lines for EIP |

If tiles are empty when EIP is selected:

| Likely cause | Fix |
| --- | --- |
| Host/service name has no `EIP` | Rename or add tag `app:eip`, then tighten DQL to tags if needed |
| No OneAgent on those servers | Install / enable monitoring |
| No log ingest | Enable log monitoring for the host group |
| Wrong timeframe | Set Last 2h or Last 24h |

### Step 4 — Optional harden later

| Improvement | Why |
| --- | --- |
| Filter by tag `app:eip` instead of name contains | More stable than hostname spelling |
| Management Zone for PRD vs STG | Avoid mixing environments |
| Add more values to `app` CSV | New apps stay on the **same** board |

### Happy path vs mistake

| Path | Outcome |
| --- | --- |
| One board + `$app` filter | Matches Dynatrace.txt |
| One board per app | What your note says **not** to do |

## Data flow map

```
User opens Main-MultiApp-Health
  │
  ├─ picks app=All
  │     → all problems / hosts / logs / errors
  │
  └─ picks app=EIP
        → same tiles
        → filter name/tag contains EIP
        → multi EIP servers
        → EIP error logs + exceptions
        → EIP request errors chart
```

## Related files

| File | Purpose |
| --- | --- |
| `Main-MultiApp-Health-Dashboards.json` | Import this |
| `12.sh` | Open path reminders |
| Sibling `3-dynatrace-main-multiapp-need/` | Earlier need mapping |
| Sibling `1-dynatrace-dashboard-layout-build/` | Row-by-row layout meaning |

## Commands

See [`12.sh`](12.sh). Review and run yourself; do not assume Dynatrace UI changes until you import in the tenant.
