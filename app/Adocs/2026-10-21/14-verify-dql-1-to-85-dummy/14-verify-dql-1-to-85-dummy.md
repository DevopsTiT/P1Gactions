# Verify DQL 1 To 85 Dummy

```
Need to prove a #1–#85 DQL without live logs?
 → Open matching block in 14-verify-01-30 / 31-60 / 61-85 (or all)
 → Run only that Verify #N block in Notebook
 → Pass = ≥1 row (or expected summarize row)
 → Then run the real fetch logs query for that number
 #10?
 → SKIP (never had Splunk/DQL)
 Lookup queries (#72, #77–#80)?
 → Dummy proves outer filters + UUID parse only (no live lookup fetch)
```

| Key point | Detail |
|---|---|
| What you get | One **dummy verify** DQL per query #1–#85 |
| How dummy works | `data record(...)` with sample fields from the match-examples pack, then the same pipeline (without `fetch logs`) |
| Style vs afterBind | Same idea as `fieldsAdd dummy = "…"` — invent the row, then filter/parse |
| Source of samples | `2026-10-15/17-dql-1-to-85-match-examples/` |

## Summary

Run each `Verify #N` block alone in a Dynatrace Notebook. If the dummy passes, your filters and parse logic are sound. If it fails, fix the DQL before blaming missing live logs.

## Files

| File | Contents |
|---|---|
| `14-verify-01-30.dql` | Verify #1–#30 |
| `14-verify-31-60.dql` | Verify #31–#60 |
| `14-verify-61-85.dql` | Verify #61–#85 |
| `14-verify-1-to-85-all.dql` | All 85 in one file |
| `14-verify-index.md` | Status table for every number |

## How to run one verify

1. Open the part file (or the all file).  
2. Copy **only** from `// Verify #N` through the blank line before the next `// Verify`.  
3. Paste into Notebook → Run.  
4. Expect ≥1 row (see comments for special cases).

## Special cases

| # | What the dummy does |
|---|---|
| 10 | SKIP — no DQL existed |
| 3, and any multi-record sample | Several `record(...)` rows so `count > 1` / groups can fire |
| 21 | Fake CPU arrays — timeseries math without metrics ingest (`percent` should be **23**) |
| 72, 77–80 | Lookup to live `fetch` removed; proves outer filters + UUID `parse` |
| 81 | Expiry math dummy (`days_left < 30`) without sslcert lookup file |
| 12, 44–49, 53, 56 | Same pipeline as their twin (#11, #38–#43, #55) |

## Repeats (same verify logic as twin)

| This # | Uses DQL from |
|---|---|
| 12 | 11 |
| 44 | 38 |
| 45 | 39 |
| 46 | 40 |
| 47 | 41 |
| 48 | 42 |
| 49, 53 | 43 |
| 56 | 55 |

## Example — Verify #2 (afterBind style)

```
data record(
    timestamp: toTimestamp("2026-10-15T09:12:34.567+09:00"),
    host.name: "ip-10-20-3-15.ap-northeast-1.compute.internal",
    k8s.pod.name: "pc2-batch-inssuite-prod-7f9c4d6b8-x2k8p",
    content: "… Exception occured for job … during afterBind_Adj process …"
  )
| filter startsWith(host.name, "pc2-batch-inssuite-prod-")
    or startsWith(k8s.pod.name, "pc2-batch-inssuite-prod-")
| filter contains(content, "Exception occured for job", caseSensitive:false)
    and contains(content, "during afterBind_Adj process", caseSensitive:false)
| sort timestamp desc
| fields timestamp, host.name, k8s.pod.name, content
```

(Your older `fetch logs \| fieldsAdd dummy = "…"` style also works for simple phrase checks; these files use `data record` so host/pod filters can be tested too.)

## Data flow map

```
match-examples sample fields
  → data record(...) dummy row(s)
  → same filters / parse / summarize as main DQL
  → pass? → trust logic → run real fetch logs #N
  → fail? → fix DQL (case, parse, field names)
```

## Related files

| File | Role |
|---|---|
| `../2026-10-15/16-dql-1-to-85-line-by-line/` | Main DQL explained |
| `../2026-10-15/17-dql-1-to-85-match-examples/` | Sample lines used here |
| `../13-verify-item3-gmo-orderid-dummy-dql/` | Hand-written #3 verify |
| `14.sh` | Copy to Adocs / Files |

## Commands

See [14.sh](./14.sh).
