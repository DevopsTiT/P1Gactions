# Transform 77 78 Plus 76 Example

```
#76 want a worked example?
 → mailservice last log 3.5h ago → minutes_behind 210
#77 bangauto _quote + pc Timeout exceeded (lookup on UUID)?
#78 same shape, channel = inswebauto + timeout_pct summarize?
#79 cut off — next screenshot
```

| Key point | Detail |
|---|---|
| #76 example | Workload `mailservice`, run-at 09:30, silent 210 minutes |
| #77 / #78 | Outer = channel `_quote` sends; lookup = pc quote `Timeout exceeded.` |
| Host in URL | Lookup uses path + `Timeout exceeded.` so `jp1` / `lp1` / `lpl` still match |
| #78 extra | One-row `requests` / `timed_out` / `timeout_pct` |

## Summary

**#76 example** shows how one quiet app becomes a report row. **#77** and **#78** are the same timeout-join pattern; only the channel path changes (`bangauto` vs `inswebauto`).

---

## #76 example (worked)

Assume the query runs at `2026-10-15T09:30:00+09:00`.

| Record | timestamp |
|---|---|
| 1 | 2026-10-14T22:10:00+09:00 |
| 2 | 2026-10-15T03:30:00+09:00 |
| 3 (newest) | 2026-10-15T06:00:00+09:00 |

| Step | What happens |
|---|---|
| `app` | `mailservice` |
| `last_seen_sec` | 12600 (09:30 − 06:00) |
| Keep? | 12600 > 3600 → yes |
| Behind | 210 minutes, 3.5 hours, 0.1 days |

**Result row:**

| app | last_event_jst | minutes_behind | hours_behind | days_behind |
|---|---|---|---|---|
| `mailservice` | `Thu Oct 15 06:00:00 2026` | 210 | 3.5 | 0.1 |

**Near miss:** `agrex` newest at 09:25 (300 seconds quiet) is dropped.

Full #77/#78 DQL and data-record #76 example: see companion `.dql` and CursorFiles copy.

## Data flow map

```
#76: mailservice last @06:00, run @09:30 → 210 min behind
#77/#78: channel _quote UUID lookup Timeout exceeded → list / timeout_pct
```

## Related files

| File | Role |
|---|---|
| `24-transform-77-78-plus-76-example.dql` | Queries |
| `23-transform-73-to-76-ebroker-esbv4-silent/` | #76 live |
| `24.sh` | Dual-write |

## Commands

See [24.sh](24.sh).
