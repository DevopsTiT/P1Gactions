# Clone EMMA PRD Dashboard to STG

```
Have PRD reference "KTA - TH EMMA PRD"?
  → Do NOT edit the PRD board
  → Clone / duplicate → rename L1 or KTA-TH-EMMA-STG
  → Retarget every tile filter from PRD → STG (MZ / tags / entity names)
  → Skip or stub Mobile if permission denied in STG
  → Feed STG traffic (synthetic + curl) until Request count / Top lists fill
  → Run failure drill → checklist → keep STG board for L1 practice
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| Reference | Existing prod dashboard **KTA - TH EMMA PRD** (preset owner `jenne.pang@axa.com`) |
| Your job | **Clone the layout**, point filters at **STG**, prove tiles with dummy STG traffic |
| Do not | Change the PRD dashboard itself, or inject failures on PRD |
| Sticky issue on ref | Mobile tiles show **Permission denied** / No data — expect the same in STG unless RUM access exists |

## Summary

Your screenshots are a working L1-style board for EMMA Thailand production. Use them as the visual and tile template. Create a STG copy with the same sections (Overview, Web Services, Infrastructure, Mobile if allowed), then swap entity filters to staging so you can practice safely with OneAgent + synthetic dummy traffic.

## What the PRD reference contains (from your screenshots)

### Header

| Field | Value on reference |
|-------|--------------------|
| Dashboard name | `KTA - TH EMMA PRD` |
| Preset owner | `jenne.pang@axa.com` |
| Timeframe shown | Last 2 hours |
| Tags on board | No tags applied (filters are likely inside tiles / MZ) |
| Management zone hint in UI | `AGO_RG_ESG_PRD` (top-right context on one shot) |

### Section A — Overview

| Tile | What it shows on PRD | STG clone target |
|------|----------------------|------------------|
| Service health | Honeycomb, “All fine”, count ~61 | Same tile type, STG services only |
| Host health | Honeycomb, “All fine”, count ~45 | Same tile type, STG hosts only |
| Problems | Count `0` (green when calm) | STG problems only |
| Network status | Talkers / Processes / Volume (e.g. 4.34 Mbit/s), 45 Hosts | STG hosts network |

### Section B — Mobile (right column)

| Tile | PRD state | STG note |
|------|-----------|----------|
| Mobile app `[KTA_TH_EMMA_PRD] TH EMMA MOBILE` | **Permission denied** | May stay denied in STG; add Markdown “RUM not in scope for STG trial” if no access |
| User Sessions | `0` | Needs mobile RUM; skip for first STG trial unless you have a STG mobile app |
| User by City / Crashes by City / User Apdex | No data | Same — optional later |

### Section C — Web Services, Requests, Response time & Failures

| Tile | What it shows | Why it matters for STG dummy data |
|------|---------------|-----------------------------------|
| Request count (stacked chart) | Traffic by service/process (Netty, VersionApi, myaxa-middleware, api-push-notification, …) | Needs synthetic + curl against **STG** APIs |
| Top list Last 10min (request volume) | Ranked services (e.g. Netty 871, VersionApi 546, …) | Same services must exist or be stubbed in STG |
| Failure rate (HTTP 5xx errors) | Spikes by API/controller | Force controlled 5xx in STG to prove the tile |
| Top list Last 10min (failure %) | Controllers at 0.00% when healthy | Inject error → non-zero row |
| 99th% response time | Latency spikes (red chart) | Slow stub in STG to prove ranking |
| Top list Last 10min (latency) | e.g. DividendOnDepositApi 9.4s (red) | Your “Top services by latency” TODO |

### Section D — Infrastructure

| Tile | What it shows | STG clone target |
|------|---------------|------------------|
| Garbage collection time | JVM GC % over time (SpringBoot / KTAXA processes) | STG JVM processes with OneAgent |
| CPU usage % (chart) | Host/process CPU, can show high plateaus | STG hosts/processes |
| CPU usage % (top list + Last 1 min) | Ranked processes (telehealth-middleware, api-telehealth-experience, api-cases, …) | Filter to STG process names |
| Memory used % (last 7 days) | Multi-day trend | Accept thin history on day 1 in STG |
| Memory used % (current + Last 1 min lists) | Ranked memory consumers | STG processes |
| Disk used % (last 7 days) | Disk trend (visible on lower part of infra shots) | STG hosts |

### Service / process names seen on PRD (for naming awareness)

These are **prod names**. In STG you will see STG equivalents or fewer services — do not expect the same Top-10 list on day one.

| Examples from screenshots |
|---------------------------|
| Netty listeners on various ports |
| VersionApi, myaxa-middleware |
| api-push-notification, api-process-claims, api-process-dividend-on-deposit, api-pos-service |
| Controllers: PolicyLoanController, DividendOnDepositApi/Controller, ClaimHistoryApi, PaymentApi, … |
| Infra: telehealth-middleware, api-telehealth-experience, api-cases, api-customer-*, SpringBoot KTAXA Thailand processes |

## Map reference → your 11-point TODO

| Your TODO | Closest tile(s) on EMMA PRD | STG action |
|-----------|-----------------------------|------------|
| 1 Overall Health | Service health + Host health honeycombs | Clone both; filter STG |
| 2 Active Problems | Problems tile | Clone; STG MZ |
| 3 Host health | Host health + CPU/Memory/Disk (+ 7d memory/disk) | Clone infra block |
| 4 Process health | CPU/Memory top lists by process; honeycomb host/service | Add process unavailable if not already a dedicated tile |
| 5 Application health | Request count + Failure rate + 99th% RT | Needs STG traffic |
| 6 Top services | Last 10min lists for volume / 5xx / latency | Same lists, STG entities |
| 7 Log errors | **Not visible on these screenshots** | Add Logs tile on STG board (gap) |
| 8 Database health | **Not visible on these screenshots** | Add DB/stub tiles (gap) |
| 9 AWS health | **Not visible on these screenshots** | Add later if STG AWS in scope |
| 10 L1 action required | Problems + honeycombs + failure/latency tops | Add Markdown L1 checklist tile |
| 11 Architecture / DC | **Not visible** | Add Smartscape link / Markdown |

## Step-by-step: clone PRD layout to STG

### Step 1 — Open the reference (read-only)

1. In Dynatrace, open dashboard **KTA - TH EMMA PRD**.
2. Do **not** click Edit and save changes on PRD.
3. Note timeframe **Last 2 hours** and that Mobile shows permission denied.

### Step 2 — Duplicate the dashboard

1. On the PRD dashboard menu (⋯ or dashboard settings) choose **Duplicate** / **Clone** / **Save as** (wording varies).
2. New name options (pick one team standard):
   - `KTA - TH EMMA STG` (matches naming style), or
   - `L1-Health-STG` (matches earlier trial plan)
3. Owner: you or STG/L1 team (not only the PRD preset owner).
4. Save.

If Duplicate is blocked by permissions:

1. Ask the preset owner or an admin to duplicate for you, **or**
2. Rebuild manually using the tile inventory tables above (same order top→bottom).

### Step 3 — Change board-level context to STG

1. Open the **STG copy** in Edit mode.
2. Set default timeframe: **Last 2 hours** (same as PRD).
3. Apply management zone / filter for STG, for example:
   - `MZ-STG`, or
   - tag `env:stg`, or
   - your real STG MZ name (if EMMA STG uses something like `AGO_RG_ESG_STG` — use the real STG zone, not PRD).
4. Add Markdown at the top:

```text
STAGING COPY of KTA - TH EMMA PRD
For L1 practice + dummy traffic only.
Do not use for prod decisions.
```

### Step 4 — Retarget every Overview tile

For each Overview tile (Service health, Host health, Problems, Network status):

1. Open tile config (pencil / Configure).
2. Replace PRD entity selectors / MZ / tags with STG.
3. Confirm counts drop to **STG-sized** numbers (often much smaller than 61 services / 45 hosts).
4. Save tile.

| Check | Good | Bad |
|-------|------|-----|
| Host health count | Matches STG host inventory | Still shows ~45 like PRD (filter not changed) |
| Problems | 0 when STG calm | Shows prod problems |

### Step 5 — Retarget Web Services tiles

For **Request count**, **Failure rate (HTTP 5xx)**, **99th% response time**, and each **Last 10min** top list:

1. Edit tile → filter to STG services / process groups / request names.
2. Remove hard-coded PRD service names if the tile pins specific entities.
3. Prefer “auto Top N by metric” filtered by STG MZ so new STG services appear without editing the tile every week.
4. Save.

Then feed dummy data (STG URLs only):

```bash
curl -sS -o /dev/null -w "%{http_code} %{time_total}\n" "https://STG_URL/health"
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do curl -sS -o /dev/null -w "%{http_code}\n" "https://STG_URL/api/demo"; done
curl -sS -o /dev/null -w "%{http_code}\n" "https://STG_URL/api/demo?force_error=1"
```

Also create HTTP synthetic `STG-app-health` against STG (see seq 9).

**Pass:** Request count is not flat empty; Top lists show STG service names.

### Step 6 — Retarget Infrastructure tiles

For GC time, CPU charts/lists, Memory (incl. last 7 days), Disk (last 7 days):

1. Filter hosts/processes to STG.
2. Keep **last 7 days** tiles even if history is short — they fill as STG runs.
3. Confirm process names are STG (or shared naming with STG suffix).

**Pass:** CPU/Memory lists show STG processes you expect (not the full PRD Top-10).

### Step 7 — Mobile section decision

| If you have… | Do this |
|--------------|---------|
| No STG mobile RUM / permission denied | Leave tiles, add Markdown “Mobile RUM out of scope for STG trial”, or hide/remove Mobile row |
| STG mobile app + access | Retarget app id from `[KTA_TH_EMMA_PRD]` to STG mobile app id |

Do not block the whole STG trial on Mobile if PRD already shows Permission denied.

### Step 8 — Add the gaps (tiles PRD screenshots did not show)

On the STG board only, add:

| Gap | Tile to add |
|-----|-------------|
| Log errors (TODO 7) | Logs tile / saved query for ERROR/Exception in STG |
| Database (TODO 8) | DB or stub latency/connections |
| AWS (TODO 9) | Only if STG AWS integration is in scope |
| L1 action Markdown (TODO 10) | Checklist under Problems |
| Architecture (TODO 11) | Smartscape link for STG EMMA |

### Step 9 — STG failure drill (never on PRD)

Same drill as seq 9, against STG only: 5xx → process stop → slow stub → problem >15 min. Watch Service/Host honeycombs, Problems, Failure rate, 99th% RT, CPU lists.

### Step 10 — Acceptance before calling STG trial done

| Check | Pass? |
|-------|-------|
| Board is a copy, PRD unchanged | |
| Name clearly says STG | |
| Overview honeycombs/problems use STG filter | |
| Request count / Top lists show STG traffic after dummy load | |
| Failure rate and 99th% RT react to injected STG fault | |
| Infra CPU/Memory/Disk scoped to STG | |
| Mobile either works or explicitly marked out of scope | |
| Gaps 7–11 added or consciously deferred with Markdown | |
| No prod-only MZ left on the STG board | |

## Data flow map

```
PRD reference (read-only)
  KTA - TH EMMA PRD
        |
        | duplicate / save as
        v
STG copy (editable)
  KTA - TH EMMA STG  (or L1-Health-STG)
        |
        | retarget MZ/tags/entities → STG
        v
STG OneAgent + STG services/hosts
        ^
        |
Synthetic + curl dummy traffic (STG URLs only)
        |
        v
Overview / Web Services / Infra tiles light up
        |
        +--> add Logs / DB / L1 Markdown / Arch (gaps)
        |
        v
L1 drill in STG → checklist pass
```

## Related files

| File | Purpose |
|------|---------|
| `10-emma-prd-clone-to-stg.md` | This clone guide from your screenshots |
| `10-emma-prd-clone-to-stg-tile-map.yaml` | Machine-readable tile inventory |
| `10-emma-prd-clone-to-stg-follow.txt` | Chat-ready steps |
| `10.sh` | Commands |
| Seq 8–9 | STG dummy plan + detailed Dynatrace steps |

## Commands

See [`10.sh`](./10.sh). STG URLs only. Never run failure drills against PRD.
