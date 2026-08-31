# Fix New Logs UI MDM Search

## Decision tree

```
Still No data / Invalid syntax?
  │
  ├─ New Logs bar shows "Invalid syntax"?
  │     summarize must be ONE line:
  │     summarize hit_count = count(), by: { dt.host_group.id }
  │     (not count  then  0. by: ... on next line)
  │
  ├─ Prefer New Logs experience (your chart already shows volume)
  │     Timeframe: Last 30 minutes first (same window where Classic worked)
  │
  ├─ Do NOT start with host-group + content together
  │     1) content-only → prove Grail sees cleansing lines
  │     2) then add host group
  │     3) then summarize
  │
  └─ Old "Logs and events" Advanced still empty for host group?
        Content-only in New Logs may still work — use that path
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Bug in your New Logs query | `summarize` broken → `count` without `()` and `by:` split → **Invalid syntax** |
| Why Advanced still empty | Likely host-group filter not matching Grail the way Classic does, or wrong combo; prove with **content-only** first |
| Best UI now | **New Logs experience** (Switch now) — your bar chart already shows traffic |
| First time window | **Last 30 minutes** (where you already saw address lines) |
| Search style | Start with `contains(content, "axacleansingservice")` then narrow |

---

## Summary

Fix the `summarize` syntax, use the **new Logs** UI with a **30-minute** window, and search **content first** (package/class name). Add `dt.host_group.id` only after you see rows. That avoids the Classic-vs-Grail host-group mismatch trap.

---

## Main content

### What went wrong on your two screens

| Screen | Problem |
| --- | --- |
| Old Advanced (No data) | Host group + content together returned 0 — host group may not match in that Grail path, or you never proved content-only |
| New Logs (Invalid syntax) | Query ended like `summarize hit_count = count` then a broken `0. by: { dt.host_group.id }` |

**Correct summarize (one pipeline step):**

```text
| summarize hit_count = count(), by: { dt.host_group.id }
```

### How to use the New Logs experience

| Step | Action |
| --- | --- |
| 1 | Open **Logs** (or click **Switch now** on the Grail banner) |
| 2 | Set timeframe to **Last 30 minutes** (top right) |
| 3 | Open the **DQL** / query bar at the top |
| 4 | Delete the broken query completely |
| 5 | Paste **one** of the queries below |
| 6 | Click **Run query** |
| 7 | Use visualization **Table** (or records list) |

Do not leave a second broken line like `0. by: { ... }` under the query.

### Working queries (copy one at a time)

#### Q1 — Content only (do this first)

If this returns rows, Grail has the MDM cleansing logs.

```text
fetch logs, from: now()-30m
| filter contains(content, "axacleansingservice")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

#### Q2 — Full class name

```text
fetch logs, from: now()-30m
| filter contains(content, "AXACleansingAddressBP")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

#### Q3 — Address Value pattern

```text
fetch logs, from: now()-30m
| filter contains(content, "address, Value =")
| fields timestamp, dt.host_group.id, host.name, content
| limit 20
```

#### Q4 — Count by host group (only after Q1–Q3 show rows)

```text
fetch logs, from: now()-30m
| filter contains(content, "axacleansingservice")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

#### Q5 — Add host group after you see the ID in Q1 results

Copy the exact `dt.host_group.id` value from a Q1 row (do not type from memory):

```text
fetch logs, from: now()-30m
| filter matchesValue(dt.host_group.id, "PASTE_EXACT_ID_FROM_Q1_ROW")
| filter contains(content, "axacleansingservice")
| summarize hit_count = count(), by: { dt.host_group.id }
```

#### Q6 — 24h count (after 30m works)

```text
fetch logs, from: now()-24h
| filter contains(content, "axacleansingservice")
| summarize hit_count = count(), by: { dt.host_group.id }
| sort hit_count desc
```

### If Q1 returns rows but host-group filter never does

| Meaning | What to do |
| --- | --- |
| Grail has content; `dt.host_group.id` on those lines may differ or be empty | Use Q4 — group by whatever ID appears |
| Classic used a UI dimension Classic maps differently | Prefer content + `host.name` from the record |
| Count by host instead | `summarize hit_count = count(), by: { host.name }` |

```text
fetch logs, from: now()-30m
| filter contains(content, "axacleansingservice")
| summarize hit_count = count(), by: { host.name, dt.host_group.id }
| sort hit_count desc
```

### Syntax rules (New Logs DQL)

| Rule | Example |
| --- | --- |
| One pipeline | `fetch ... \| filter ... \| summarize ...` |
| `count()` needs parentheses | `count()` not `count` |
| `by:` stays on same summarize | `summarize hit_count = count(), by: { dt.host_group.id }` |
| Prefer `contains` for CamelCase | `contains(content, "AXACleansingAddress")` |
| Match Classic time first | `now()-30m` then widen to `24h` |
| Sample before heavy summarize | `fields ... \| limit 20` |

### Easy filtering (no DQL) in New Logs

| Step | Action |
| --- | --- |
| 1 | New Logs → timeframe **Last 30 minutes** |
| 2 | Click **Easy filtering** (or Add filter) |
| 3 | Filter **content** / Log message **contains** `axacleansingservice` |
| 4 | Run |
| 5 | Open one record → copy `dt.host_group.id` and `host.name` from Fields |
| 6 | Add those as exact filters if needed |

---

## Data flow map

```
Classic UI ──sees──> AXACleansingAddressBP lines (30m)

New Logs (use this)
  1. Fix summarize syntax
  2. now()-30m
  3. contains("axacleansingservice") → limit 20
  4. summarize by dt.host_group.id
  5. only then matchesValue(exact id from results)

Old Advanced host-group-first ──often──> No data (skip this path)
```

---

## Related files

| File | Purpose |
| --- | --- |
| [25.sh](./25.sh) | Open this guide |
| [25-fix-new-logs-ui-mdm-search-follow.txt](./25-fix-new-logs-ui-mdm-search-follow.txt) | Chat-ready |
| Why phrase failed | `2026-08-31/24-why-dql-no-result-vs-classic/` |

---

## Commands

See [25.sh](./25.sh).
