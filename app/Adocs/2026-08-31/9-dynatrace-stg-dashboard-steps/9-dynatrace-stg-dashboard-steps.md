# Dynatrace STG Dashboard Steps

```
Start
  → Step 0: gather URLs, tags, demo app
  → Step 1: prove STG OneAgent data exists
  → Step 2: tag env:stg + management zone
  → Step 3: create empty L1-Health-STG dashboard
  → Step 4: add synthetic + dummy traffic
  → Step 5: build tiles 1–11 one by one
  → Step 6: inject STG-only failures (L1 drill)
  → Step 7: mark checklist pass
  → Step 8: export / clone for prod later
Blocked?
  → no entities → wrong filter/tag/time range
  → no synthetic → wrong URL or firewall
  → no problems → failure too short or auto-closed
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| Assumption | Dynatrace **SaaS** already sees STG hosts with **OneAgent** |
| Goal | Build `L1-Health-STG` and fill it with **controlled dummy traffic** |
| Order | Verify data → tag/MZ → dashboard shell → synthetics → tiles → failure drill → export |
| Promote | Only after all 11 sections pass in STG |

## Summary

This is the click-level runbook for your Dynatrace L1 dashboard trial. You already have OneAgent on STG. You will tag STG entities, create a staging-only dashboard, drive synthetic and demo traffic, build the 11 sections from your TODO list, then practice L1 failures in STG before any prod clone.

## Before you start (15 minutes)

Write these down. You will paste them into Dynatrace and curl.

| Item | What it is | Example placeholder |
|------|------------|---------------------|
| Dynatrace URL | Your SaaS environment URL | `https://abc12345.live.dynatrace.com` |
| STG app URL | Health endpoint of the demo/STG service | `https://stg-app.example.com/health` |
| STG API URL | Endpoint that calls backends | `https://stg-app.example.com/api/demo` |
| STG host name(s) | Hosts already showing in Dynatrace | `stg-app-01` |
| Tag | Environment label | `env:stg` |
| Dashboard name | Staging board only | `L1-Health-STG` |

Also decide:

| Decision | Recommended for first trial |
|----------|-----------------------------|
| Which app feeds the board | One existing STG service that already has traffic, or a tiny demo API behind OneAgent |
| Who gets paged | Nobody in prod. Mute or use STG-only alert profile for the drill |
| Time window for L1 tiles | Last **2 hours** default; host trends **3 days** or **7 days** |

---

## Step 0 — Confirm you are in the right Dynatrace environment

1. Open your Dynatrace SaaS URL in the browser.
2. Top-left / environment switcher: confirm you are in the **intended** environment (often one env holds both STG and prod entities, separated by tags/MZ).
3. Do **not** start building on a shared “prod-looking” dashboard. You will create a new one named `L1-Health-STG`.

---

## Step 1 — Prove STG OneAgent data already exists

**What this is:** OneAgent is the Dynatrace agent on the host/container. If it is healthy, Hosts and Processes already have metrics.

1. Left menu → **Hosts** (or **Infrastructure** → **Hosts**).
2. Search for your STG host name (example: `stg-app-01`).
3. Open the host.
4. Confirm you can see:
   - CPU
   - Memory
   - Disk
   - Network (nice to have)
5. On that host page, open **Processes** / process list.
6. Find the process for your STG app (Java, Node, nginx, etc.).
7. Confirm the process is **running** (not unavailable).

| Check | Pass means | If fail |
|-------|------------|---------|
| Host visible | You see the STG host | Wrong environment, or host renamed; ask platform team |
| CPU/mem charts not empty | Lines/points in last 2 hours | Expand time range; confirm OneAgent not stopped |
| Process listed | App process appears under the host | Restart app or confirm process group detection |

**Stop here if Step 1 fails.** Dashboard tiles will stay empty until OneAgent data is visible.

---

## Step 2 — Tag STG entities with `env:stg`

**What a tag is:** A label Dynatrace uses to filter “only staging.”

### 2a. Tag the host

1. Open the STG host from Step 1.
2. Find **Properties and tags** (or the tag pencil / **Add tag**).
3. Add tag:
   - Key: `env`
   - Value: `stg`
4. Save.

### 2b. Tag the process group / service (if shown separately)

1. From the host → open the app **process group**.
2. Add the same tag `env:stg` if it is not inherited.
3. Go to **Services** (or **Applications & Services** → **Services**).
4. Find the STG service name.
5. Add `env:stg` if missing.

### 2c. Optional but recommended — automatic tagging rule

If you have permission:

1. Go to **Settings** → **Tags** → **Manually applied tags** is for one-off; prefer **Automatically applied tags**.
2. Create a rule such as:
   - Rule name: `tag-env-stg`
   - Condition examples (pick what matches your estate):
     - Host name contains `stg`
     - Or cloud tags / Kubernetes namespace equals `stg`
   - Then apply tag `env:stg`

| Why you care | Without `env:stg`, the dashboard may mix prod hosts into “L1 Health” and L1 will trust the wrong picture. |

---

## Step 3 — Create a management zone for STG (recommended)

**What a management zone (MZ) is:** A Dynatrace filter that limits which entities a user or dashboard “sees.” Think of it as a glass wall around STG.

1. Go to **Settings** → **Preferences** → **Management zones**  
   (wording can be **Settings** → **Management zones** depending on version).
2. **Add management zone**.
3. Name: `MZ-STG` (or your team standard).
4. Add rule(s):
   - Entity selector / rule: entities with tag `env:stg`
   - Include hosts, services, process groups, apps as needed.
5. Save.
6. If your user needs it: ensure your account can **view** `MZ-STG`.

You will pin the dashboard to this MZ or filter every tile with `env:stg`.

---

## Step 4 — Create the empty dashboard shell

1. Left menu → **Dashboards** (classic) or **Dashboards & Notebooks** → **Dashboards**.
2. **Create dashboard** (or **Upload** later if you use JSON).
3. Name: `L1-Health-STG`.
4. Owner: you or the L1/SRE team.
5. Save once so you do not lose the empty board.
6. Open dashboard **settings** (gear):
   - Default timeframe: **Last 2 hours**
   - If available: default management zone / filter → `MZ-STG` or tag `env:stg`
7. Add a **Markdown** tile at the top with text like:

```text
L1 Health — STAGING ONLY
Tag filter: env:stg
Do not use for prod decisions.
Drill steps: Overall → Problems → Host/Process/App → Logs → DB/AWS
```

Layout sketch (top to bottom):

```
[ Markdown: STG only ]
[ 1 Overall Health ] [ 2 Active Problems ]
[ 3 Host health ............ ]
[ 4 Process health ] [ 5 Application health ]
[ 6 Top services .......... ] [ 7 Log errors ]
[ 8 Database ] [ 9 AWS ]
[ 10 L1 action required ............... ]
[ 11 Architecture / DC ................ ]
```

---

## Step 5 — Add synthetic monitoring (dummy availability traffic)

**What a synthetic monitor is:** Dynatrace’s robot that hits your URL on a schedule so availability and response time exist even when no human is testing.

1. Go to **Synthetic** (or **Digital Experience** → **Synthetic**).
2. **Create a synthetic monitor** → choose **HTTP monitor** (simplest for STG API/health).
3. Configure:
   - Name: `STG-app-health`
   - URL: your STG health URL (from Step 0)
   - Frequency: every **1** or **5** minutes for the trial
   - Locations: at least one location that can reach STG (private location if STG is internal)
4. Assertions:
   - HTTP status = `200`
   - Optional: response body contains `OK` / `healthy`
5. Tags: add `env:stg`
6. Save and wait for **2–3 successful runs** (open the monitor → executions).

| Check | Pass means | If fail |
|-------|------------|---------|
| Execution green | Status 200 | Firewall/DNS; use private synthetic location |
| Appears in Services/Synthetic | Monitor linked to your app | Wait a few minutes; confirm URL host matches app |

Optional second monitor:

- Name: `STG-app-api-demo`
- URL: `https://stg-app.example.com/api/demo`
- Same tag `env:stg`

---

## Step 6 — Generate extra dummy traffic (load + errors)

Synthetics alone may be too quiet for “Top services” and error-rate charts. Add a short manual load from your laptop or a STG bastion.

**Review these before running. Replace URLs. Never use prod URLs.**

```bash
# Health check
curl -sS -o /dev/null -w "%{http_code} %{time_total}\n" "https://STG_URL/health"

# Normal traffic burst
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do curl -sS -o /dev/null -w "%{http_code}\n" "https://STG_URL/api/demo"; done

# Controlled errors (only if your STG app supports a test flag)
curl -sS -o /dev/null -w "%{http_code}\n" "https://STG_URL/api/demo?force_error=1"
```

If you have no `force_error` flag:

1. Temporarily point one STG route at a backend that returns 500, **or**
2. Stop a dependent STG stub for a few minutes, **or**
3. Use a second demo endpoint that always fails (preferred for safety).

Also generate **log errors**:

1. Trigger an exception path in the STG app (test endpoint or bad input).
2. In Dynatrace: **Logs** → filter `env:stg` or host/service → confirm ERROR lines appear.
3. If logs are missing: confirm OneAgent log enrichment / log ingest is enabled for that process (ask platform if unsure).

Wait **5–10 minutes** so charts catch up before you judge tiles empty.

---

## Step 7 — Build dashboard tiles (sections 1–11)

Work top to bottom. After each tile, set the filter to **tag `env:stg`** or management zone `MZ-STG`.

### Tile 1 — Overall Health

1. On `L1-Health-STG` → **Edit** → **Add tile**.
2. Prefer a **Problems** / **Health** / **Markdown + Data explorer** tile that shows environment health.
3. Practical beginner option:
   - Add a **Problems** tile filtered to `env:stg`
   - Add a second tile: count of open problems (critical / open)
4. Goal: L1 sees healthy when problem count is 0; unhealthy/critical when open severity rises.

**Pass:** With no injected failure, board looks calm. After you inject a failure in Step 8, this area changes.

### Tile 2 — Active Problems

1. Add tile → **Problems** (list or chart).
2. Columns / fields to show if available:
   - Problem count
   - Severity
   - Duration
3. Filter: `env:stg`, open problems.
4. Optional: second chart “problems opened in last 24h” so “increased vs normal” is visible later.

**Pass:** At least the empty state works (0 problems). After drill, a problem row appears with duration.

### Tile 3 — Host health

1. Add tile → **Host** metrics or **Data explorer**.
2. Metrics:
   - CPU usage `%`
   - Memory usage `%`
   - Disk used `%` (or free %)
3. Filter: hosts with `env:stg`.
4. Duplicate one chart and set timeframe to **Last 3 days** or **Last 7 days** for trend (your TODO item 3).
5. Optional table tile: list STG hosts with CPU/mem/disk sparklines.

**Pass:** Charts show your STG host lines from Step 1 (not “No data”).

### Tile 4 — Process health

1. Add tile for **Process** availability / instance count, or pin the STG process group.
2. Show:
   - Process group state (running / unavailable)
   - Instance count (if multiple)
3. Filter: `env:stg`.

**Pass:** Process shows running now. Later in Step 8, stopping it flips the tile.

### Tile 5 — Application health

1. Add tiles from the **Service** or **Application**:
   - Availability (can use synthetic success rate)
   - Request count
   - Response time (P50/P90 if available)
   - Failure/error rate
2. Filter service/app with `env:stg`.
3. Pin the synthetic monitor success rate next to error rate.

**Pass:** After Step 5–6 traffic, request count and response time are non-zero.

### Tile 6 — Top services (errors / latency) + backends

1. Add a **table** or **Top N** tile:
   - Services sorted by **failure rate** or **error count**
   - Services sorted by **response time**
2. Add a second tile: **service flow** / **calls to** backends for your STG service (Smartscape service flow or “Throughput and response time by called service”).
3. Filter callers/callees under `env:stg`.

**Pass:** You can see which backend is slow or erroring. If empty, you still lack inter-service calls — add a stub backend and call it from the demo API.

### Tile 7 — Log errors / exceptions

1. Add a **Logs** tile or link tile to a saved log query.
2. Query idea (adapt to your log fields):

```text
status="ERROR" OR content="Exception"
```

3. Filter to STG host/service or `env:stg`.
4. Show last 50 error lines or a count of errors over time.

**Pass:** The intentional ERROR from Step 6 appears.

### Tile 8 — Database health

1. Find the DB in Dynatrace:
   - **Databases** view, or
   - Called service/database from your STG app service flow
2. Tag it `env:stg` if missing.
3. Add tiles:
   - DB availability / failed connections (what your edition shows)
   - Connection count (if available)
   - Response time / query time
4. If you only have a DB stub: still pin that stub service’s response time and error rate, and label the tile “DB / data store (STG stub)”.

**Pass:** Metric moves when you slow the DB/stub in Step 8.

### Tile 9 — AWS health

1. Confirm AWS integration exists: **Settings** → **Cloud and virtualization** → **AWS** (wording varies).
2. Confirm STG account/resources are included and tagged `env:stg` where possible.
3. Add tiles for the AWS services your STG app actually uses (examples):
   - ALB/NLB 5xx / target health
   - RDS CPU / connections
   - Lambda errors (only if used)
4. Filter aggressively to STG. Empty quiet metrics are OK if the filter is correct; wrong-account data is not OK.

**Pass:** Tile is scoped to STG and shows either real quiet metrics or clearly labeled “no STG AWS signals yet” in markdown — do not leave a prod account chart on this board.

### Tile 10 — L1 action required

Build a **checklist-style** row of tiles or a Problems filter for these cases:

| L1 trigger | How the tile should help |
|------------|--------------------------|
| New critical problems | Problems tile filtered severity = Critical, opened recently |
| Problems > 15 minutes | Problems list sorted by duration; L1 sees age |
| Hosts not reporting | Host availability / “hosts with OneAgent offline” style tile |
| Application unavailable | Synthetic success < threshold or service availability down |
| Process unavailable | Process group unavailable count > 0 |

Add a Markdown tile under them:

```text
L1 actions (STG drill)
1) Ack the Problem in Dynatrace
2) Open Overall Health → note severity
3) Host down? → Host tile → recent events
4) Process down? → Process tile
5) App errors? → App + Top services + Logs
6) DB/AWS? → tiles 8–9
7) Page on-call only if STG runbook says so (usually no page for drill)
```

**Pass:** Each trigger is either a dedicated tile or an obvious filter on the Problems tile.

### Tile 11 — Architecture / data-center level

1. Add a tile that opens **Smartscape** for the STG app, **or**
2. Add a custom **Markdown + image/link** to your STG architecture, **or**
3. Use a **Data explorer** / topology tile if your tenant has DC/AZ attributes (host property `availabilityZone`, DC name, etc.).
4. Filter hosts by DC/AZ + `env:stg` if you have more than one site.

**Pass:** L1 can answer “which tier / which DC looks sick?” without leaving the board for more than one click.

---

## Step 8 — L1 failure drill in STG only (dummy incidents)

Do these **one at a time**. Restore after each. Keep screenshots or notes for the checklist.

| Order | Action (STG only) | Watch tiles | Restore |
|-------|-------------------|-------------|---------|
| A | Stop generating errors; confirm board calm | 1, 2, 5 | — |
| B | Force 5xx or stop a backend stub for 10+ minutes | 1, 2, 5, 6, 10 | Start stub / disable force_error |
| C | Stop app process or scale replicas to 0 | 4, 5, 10 | Start process / scale up |
| D | Slow DB/stub (sleep or throttle) | 8, 6 | Remove throttle |
| E | Leave one problem open **>15 minutes** | 2, 10 | Fix root cause |
| F | (Optional, needs approval) Stop OneAgent briefly on one STG host | 3, 10 host not reporting | Start OneAgent |

**PagerDuty note:** For the drill, disable routing to prod on-call or use a STG test service. You do not want real pages from dummy failures.

---

## Step 9 — Acceptance checklist (must all pass)

Use the YAML checklist from seq 8, or this short form:

| # | Section | Pass? |
|---|---------|-------|
| 1 | Overall Health flips with failure | |
| 2 | Active Problems show count/severity/duration | |
| 3 | Host CPU/mem/disk visible (trend OK to be thin day 1) | |
| 4 | Process unavailable detectable | |
| 5 | App availability/latency/error rate move | |
| 6 | Top services / backends show the bad one | |
| 7 | Log ERROR/Exception visible | |
| 8 | DB/stub metrics move | |
| 9 | AWS tile scoped to STG | |
| 10 | L1 action row covers the five triggers | |
| 11 | Architecture/DC view usable | |
| — | No prod entities on this dashboard | |
| — | Markdown says STAGING ONLY | |

---

## Step 10 — Save, export, prepare prod clone (do not switch yet)

1. **Save** `L1-Health-STG`.
2. Export dashboard JSON (UI: dashboard menu → export / download JSON), or screenshot + tile list if export is restricted.
3. Store the export next to your notes (or later into Terraform `dynatrace_json_dashboard`).
4. Prod clone later:
   - Duplicate dashboard → rename `L1-Health-PROD`
   - Change MZ / tag filter from `env:stg` to `env:prod`
   - Re-point synthetics to prod URLs **only** when intentionally monitoring prod
   - Re-test with **read-only** observation first (no failure injection on prod)

---

## Data flow map

```
You (browser)
  → Dynatrace SaaS
       → Hosts/Services tagged env:stg
       → MZ-STG filters what L1-Health-STG shows
            ↑
STG OneAgent (already installed)
  → host CPU/mem/disk, process state, service metrics, logs
            ↑
STG app + backends/DB stub
            ↑
Synthetic HTTP monitor (every 1–5 min)
+ curl/load script (dummy bursts / errors)
            ↓
Problems / Davis
            ↓
Tiles 1–11 on L1-Health-STG
            ↓
(checklist pass) → export JSON → clone to prod MZ later
```

## Related files

| File | Purpose |
|------|---------|
| `9-dynatrace-stg-dashboard-steps.md` | This detailed runbook |
| `9-dynatrace-stg-dashboard-steps-follow.txt` | Chat-ready full steps |
| `9.sh` | One-liner commands |
| Seq 8 plan + checklist | `/Daily Files/2026-08-31/8-dynatrace-dashboard-stg-dummy/` |

## Commands

See [`9.sh`](./9.sh). Review before running. STG URLs only.
