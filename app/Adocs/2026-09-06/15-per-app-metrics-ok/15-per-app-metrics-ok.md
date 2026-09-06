# Per-App Metrics OK

```
Same metrics for each app?
  YES → filter by app tag / MZ on the SAME board
  NO  → do not invent different metric keys per app
  NO  → do not clone one Classic board per app
```

| Question | Answer |
| --- | --- |
| OK for each app? | **Yes** — same metric keys |
| How | Dashboard filter (or tile filter) tag `app:eip` / `app:api` / `app:payment` |
| What changes | Which entities appear — not which metrics you use |

## Summary

Your table is the **standard** set. For EIP (or any app), keep those metrics and narrow entities with tags. One main board + filter is enough.

## How per-app works

| Tile / metric | Per-app meaning |
| --- | --- |
| Host health `builtin:host.availability.state` | Only hosts tagged for that app |
| Service health / Failure / Request / 99th RT | Only services tagged for that app |
| CPU / Mem / Disk | Only that app’s hosts (disk still splits by disk) |
| GC `builtin:tech.jvm.memory.gc.suspensionTime` | JVM processes on that app’s hosts / PGIs |

## Happy path

1. Tag hosts + services: `app:eip`, `app:api`, `app:payment`
2. Keep **one** Generic V2–style board (all apps when filter empty)
3. Set Dashboard filter → `app:eip` when you want EIP only
4. Clear filter → back to all apps

## Caveats (still OK, just know them)

| Caveat | What it means |
| --- | --- |
| Missing tags | Filter looks empty — fix tags, not metrics |
| GC empty | App has no JVM / metric not collected — normal for some stacks |
| Disk paths | Still host+disk; filter hosts by app tag |
| Honeycomb counts | Drop when filtered (e.g. 277 → EIP-only count) — expected |

## Do / Don’t

| Do | Don’t |
| --- | --- |
| Reuse this metric table for every app | Create EIP-only / API-only metric lists |
| One board + dashboard filter | One full Classic clone per app |
| Tag consistently | Filter by fragile hostname substrings only |

## Related file

Import board: `../14-main-all-apps-status/Main-All-Apps-Status-Classic.json` (same metrics; filter for each app).
