# Replace Generic V2 With Current Board

```
Generic V2 - Overview     = Dynatrace preset template (example layout)
DashboardTestK - Multi-App = your current Must/Should-Watch board

Replace V2 with current for daily use?
  YES → use DashboardTestK as the main board
  KEEP V2 → optional reference only (do not maintain two mains)

Not a Dynatrace product “V2 → V3 upgrade”
```

| Key point | Detail |
| --- | --- |
| What “V2” is | Preset name **Generic V2 - Overview**, not an old Dynatrace version |
| What “current” is | Your **DashboardTestK - Multi-App** (Must-watch board) |
| Replace? | **Yes for daily ops** — one main board (current) |
| Keep V2? | Optional as a visual reference; avoid two competing mains |

## Summary

You are not upgrading software. You choose which **dashboard** is primary. Use **DashboardTestK** as the main all-apps / any-app board. Use Generic V2 only as a layout example. Fix the gaps below so current matches what you liked on V2.

## Side-by-side

| Area | Generic V2 | Your DashboardTestK (current) | Action |
| --- | --- | --- | --- |
| Service health | Honeycomb “All fine” | Honeycomb (purple cells) | Keep; retune metric/thresholds if colors look wrong |
| Host health | Honeycomb + red count | Honeycomb | Keep |
| Problems | Count tile | `161/564` style | Keep |
| Database | Green honeycomb / health | “Please pick a database” | Fix — see below |
| TCP Connectivity | Present on V2 | Missing on current | Optional: add tile from V2 pattern |
| Request + Last 10min | Chart + side list | Traffic/Errors/Latency charts | Current is OK; add Last 10min if you want V2 layout |
| GC | Infra column | On Must/Should JSON if imported fully | Add if tile missing on TestK |
| App choose | Tags / filter | Same idea: filter `app:<name>` | Keep |

## How to “replace” (practical)

1. Open **DashboardTestK - Multi-App** → set as favorite / shared main.
2. Optional: open **Generic V2 - Overview** → Export JSON once as backup/reference.
3. Do **not** delete V2 until TestK looks good for L1.
4. Stop editing two boards — only improve **DashboardTestK**.

## Fix “Please pick a database”

Classic **DATABASE** tile needs a chosen DB entity (or filter).

| Step | Action |
| --- | --- |
| 1 | Edit the Database tile |
| 2 | Pick a database **or** leave board filter empty and use a Data Explorer honeycomb on DB-related services instead |
| 3 | For any-app board: prefer a honeycomb/metric tile over a single fixed DB pick |

If the tile only supports one DB, replace it with Data Explorer (same as Service health) filtered by dashboard `app` tag when set.

## Make current closer to V2 (optional)

| Add to DashboardTestK | Why |
| --- | --- |
| TCP / Network health honeycomb | Matches V2 Overview row |
| Last 10min next to Traffic | Matches V2 request row |
| GC chart + Last 10min | Matches V2 Infrastructure column |

Your JSON `App-Must-Should-Watch-Classic.json` already includes most of this; re-import or copy missing tiles if TestK was built partially.

## Decision

| Goal | Do this |
| --- | --- |
| Daily main board | **DashboardTestK** (current) |
| Layout inspiration | Glance at Generic V2 |
| Any app select | Dashboard filter tag `app:<any>` on TestK |
| Two mains forever | Avoid |

## Related

- Current design JSON: `App-Must-Should-Watch-Classic.json` (seq 19 / Host copy)
- Full V2-style all-apps: `Main-All-Apps-Status-Classic.json` (seq 17)
