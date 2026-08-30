# Dynatrace Dashboard STG Trial

```
Need L1 health dashboard?
  → Build in STG first (never invent tiles on prod)
  → STG has OneAgent?
       yes → deploy/reuse demo app + synthetic traffic
       no  → install OneAgent on STG host/container first
  → Do tiles show data?
       empty → fix management zone / entity filters / time range
       wrong → rename tags (env:stg) and re-filter
       good  → run L1 walkthrough with dummy failures
  → Ready for prod copy?
       checklist green → clone dashboard, swap MZ to prod
       not green → stay in STG until each of 11 sections has a sample signal
```

## Short takeaway

| Key point | Detail |
|-----------|--------|
| Goal | Prove the 11-section Dynatrace dashboard works in **STG with dummy traffic** before prod |
| Method | STG OneAgent + demo/sample app + synthetic monitors + intentional failures |
| Rule | Every tile must show a **known fake signal** at least once (healthy and broken) |
| Promote | Only after STG L1 walkthrough passes; then clone and retarget management zone |

## Summary

You already listed what the dashboard should show (overall health, hosts, processes, apps, top services, logs, DB, AWS, L1 actions, architecture). The first step is not production polish. Stand up the same layout in **staging**, drive **dummy/synthetic traffic** through an instrumented app, and confirm each tile lights up for healthy and unhealthy cases. That way L1 practice is safe and you learn which filters and management zones actually work.

## What this is and why STG first

A **Dynatrace dashboard** is a single screen of charts and status tiles so L1 can answer: “Is the system OK, and if not, where?”

**Staging (STG)** is a non-production environment. **Dummy data** here means controlled synthetic traffic and intentional faults (not fake CSV pasted into prod). You still use real Dynatrace signals from STG OneAgents — just not customer traffic.

Why this order matters:

| Approach | What it means | Why you care |
|----------|---------------|--------------|
| STG + OneAgent + synthetic | Real metrics from a throwaway app | Closest to prod behavior without customer risk |
| Custom metrics only | API pushes numbers with no hosts | Useful later for sparse AWS tiles; not enough alone for host/process health |
| Layout-only mock | Empty tiles or screenshots | OK for design review; fails L1 rehearsal |

## Your 11 sections → STG dummy plan

Map each TODO line to what you generate in STG and what “pass” looks like.

| # | Dashboard section | What to generate in STG | Pass criteria (dummy) |
|---|-------------------|-------------------------|------------------------|
| 1 | Overall Health (healthy / unhealthy / critical) | One healthy period, then break one dependency | Status flips when you inject failure |
| 2 | Active Problems (count, severity, duration) | Trigger a problem that lasts >15 min once | Problem appears with severity and duration |
| 3 | Host health (CPU, memory, disk; 3/7 day trend) | Stress CPU or fill disk briefly on STG host | Host tile shows spike; trend has history after a few days |
| 4 | Process health (unavailable / low instance count) | Stop one process or scale demo replicas to 0 | Process shows down / low instances quickly |
| 5 | Application health (availability, request time, response time, error rate) | Synthetic browser/HTTP + load script with 5xx mix | Error rate and latency move with the script |
| 6 | Top services by errors/latency + backends called | Call 2–3 backend stubs (slow + error) | Ranking shows the bad backend near the top |
| 7 | Log errors / exceptions | Log ERROR/EXCEPTION from demo app | Log tile or drill-down shows those lines |
| 8 | Database health (availability, connections, response time) | Point demo at STG DB or DB stub; add latency | DB metrics move; connection/latency visible |
| 9 | AWS health | Tag STG AWS resources; enable cloud integration for STG account/role | At least one AWS service tile has STG data (even quiet is OK if filter is correct) |
| 10 | L1 action required | Script scenarios: new critical, problem >15m, host not reporting, app/process unavailable | Each scenario maps to a clear tile + next click |
| 11 | Architecture / data-center level | Smartscape or custom topology for STG apps/hosts | L1 can see which DC/tier is affected |

## Recommended STG trial sequence (do in order)

### Phase A — Scope (30–60 min)

1. Name the dashboard: `L1-Health-STG` (keep prod name for later clone).
2. Create or reuse a **management zone** (filter of what Dynatrace is allowed to show) for STG only, e.g. tag `env:stg`.
3. Confirm STG hosts/containers have **OneAgent** (the Dynatrace agent that reports host, process, and often app data).
4. Pick one demo app (existing STG service or Dynatrace sample / simple HTTP API with a DB call).

### Phase B — Feed dummy traffic (same day)

1. Create **HTTP synthetic monitors** against STG URLs (availability + response time).
2. Run a small load script (even `curl` loop or k6) with mostly 200s and a controlled share of errors.
3. Add one slow backend stub and one erroring backend stub so “Top services” is not empty.
4. Generate ERROR logs from the demo app on purpose.

### Phase C — Inject L1 scenarios (same day or next)

Walk L1 through these **controlled** failures in STG only:

| Scenario | How to create dummy signal | What L1 should see |
|----------|----------------------------|--------------------|
| App unhealthy | Return 5xx from demo or block path | App health + error rate rise |
| Process unavailable | Stop process / kill pod | Process health down |
| Host not reporting | Stop OneAgent briefly on one STG host (with approval) | Host missing / not reporting |
| Problem >15 mins | Leave a failure running | Active Problems duration grows |
| DB slow | Add sleep / throttle on DB stub | DB response time rises |
| Critical new problem | Hard-down dependency | Overall Health → critical; L1 action tile lights |

### Phase D — Promote only after checklist

| Check | Ready? |
|-------|--------|
| All 11 sections have a filter that returns STG entities (not “no data” from wrong MZ) | |
| Healthy baseline looks green | |
| At least one full L1 drill completed with dummy failure | |
| No prod entities appear on `L1-Health-STG` | |
| Dashboard JSON/export saved for later Terraform or clone | |

Then: **clone** → rename to prod → change management zone / tags to prod. Do not rebuild from memory.

## Tile design tips (beginner-safe)

| Tip | What it means | Why you care |
|-----|---------------|--------------|
| One idea per tile | Host CPU is separate from App error rate | L1 does not guess what a mixed chart means |
| Same time range | Default last 2 hours for L1; trends 3/7 days on host tiles | Avoid “empty” when data is outside the window |
| Tag everything `env:stg` | Hosts, services, synthetics, AWS resources | Management zone stays clean |
| Link tiles to Problems | Click-through to Dynatrace Problem | Matches item 10 (L1 action required) |
| Mask PII in logs | STG still can have test PII-like strings | Matches your “Masking PII data” tab |

## Common mistakes

| Mistake | What happens | Fix |
|---------|--------------|-----|
| Building on prod first | Fake failures hit real users or noisy alerts | STG-only MZ and STG alert profiles |
| Empty “Top services” | No traffic between services | Add backend stubs + synthetic that calls them |
| Host trend empty on day 1 | 3/7 day charts need history | Accept thin trend on day 1; re-check after 3 days |
| AWS tile blank | Cloud integration not scoped to STG | Fix AWS connection / tags before calling the tile “done” |
| Mixing STG and prod on one board | L1 misreads severity | Separate dashboards and management zones |

## Data flow map

```
L1 opens L1-Health-STG
        |
        v
Management zone (env:stg) filters entities
        |
        +---> Synthetic monitors -------> App availability / latency
        |
        +---> Load + error script ------> Request rate, error rate, top services
        |
        +---> OneAgent on STG host -----> Host CPU/mem/disk, process health
        |
        +---> Demo app logs ------------> Log errors / exceptions
        |
        +---> STG DB or stub -----------> DB availability / connections / RT
        |
        +---> AWS STG integration ------> AWS health tiles
        |
        v
Davis / Problems engine
        |
        v
Overall Health + Active Problems + L1 action required tiles
        |
        v
(pass checklist) --> clone dashboard --> retarget MZ to prod
```

## Related files

| File | Purpose |
|------|---------|
| `8-dynatrace-dashboard-stg-dummy.md` | This plan |
| `8-dynatrace-dashboard-stg-dummy-tile-checklist.yaml` | Per-section STG pass/fail checklist |
| `8-dynatrace-dashboard-stg-dummy-follow.txt` | Chat-ready steps |
| `8.sh` | One-liner commands to copy |
| Prior notes | Dynatrace Terraform dashboard work under Daily Files `2026-07-25` / `2026-07-27` |

## Commands

See [`8.sh`](./8.sh). Review before running. Replace placeholders (`STG_URL`, `DT_ENV`, tags) with your values. Do not point synthetics or stress tools at production.
