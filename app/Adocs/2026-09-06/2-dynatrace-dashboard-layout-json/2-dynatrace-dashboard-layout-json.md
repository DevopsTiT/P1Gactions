# Dynatrace Dashboard Layout JSON Import

```
Which JSON to import?
  │
  ├─ Dashboards (new UI / Notebooks app) → App-Health-Layout-Dashboards.json  ★ preferred
  ├─ Dashboards Classic / Config API     → App-Health-Layout-Classic.json
  └─ Empty tiles after import?
        → fix DQL metric names for your tenant
        → tag services app:eip|api|payment
        → confirm logs/problems ingested
```

| Question | Answer |
| --- | --- |
| Preferred file | `App-Health-Layout-Dashboards.json` |
| Why preferred | Has **`$app`** variable = All / EIP / API / Payment (matches Row 1) |
| Classic file | `App-Health-Layout-Classic.json` — same 11-row layout via Config API |
| Layout | Matches your DASHBOARD LAYOUT VISUAL (11 rows) |

## Summary

Two importable JSONs implement your layout picture. Use the **new Dashboards** file first: it includes the application selector variable and live DQL tiles for Problems, KPIs, hosts, logs, and DB/deps. Classic JSON works for older tenants / Terraform `dynatrace_json_dashboard`.

---

## Files

| File | Import target |
| --- | --- |
| [`App-Health-Layout-Dashboards.json`](./App-Health-Layout-Dashboards.json) | **Dashboards** (document JSON, version 21) |
| [`App-Health-Layout-Classic.json`](./App-Health-Layout-Classic.json) | **Dashboards Classic** or `POST /api/config/v1/dashboards` |

---

## Import — new Dashboards (preferred)

1. Dynatrace → **Dashboards** (not Classic)
2. **Create new dashboard** (empty)
3. Open menu → **Download / Upload** or **Edit JSON** (wording varies)
4. Paste / upload **entire** contents of `App-Health-Layout-Dashboards.json`
5. Save → rename to `App-Health-Layout` if needed
6. Top variable **app**: try `All`, then `EIP` / `API` / `Payment`

### If Edit JSON rejects the file

| Error | Fix |
| --- | --- |
| Missing `type` on tile | You pasted Classic JSON into new Dashboards — use `App-Health-Layout-Dashboards.json` |
| Query error / blank chart | Open tile → fix metric key for your Grail version |
| Problems tile empty | No ACTIVE Davis problems, or field names differ — adjust DQL in tile 3–5 |
| Logs empty | Log ingest not enabled for those hosts/services |

---

## Import — Classic

### UI

1. **Dashboards Classic** → **Upload** / import dashboard  
2. Select `App-Health-Layout-Classic.json`  
3. Open board → set dashboard filter / MZ if you have one  
4. Refine Windows vs Linux CPU filters on the two host tiles (Classic starts with all hosts)

### API (review before run)

```bash
# Replace ENV_ID and TOKEN — needs ReadConfig + WriteConfig
curl -sS -X POST "https://ENV_ID.live.dynatrace.com/api/config/v1/dashboards" \
  -H "Authorization: Api-Token TOKEN" \
  -H "Content-Type: application/json" \
  -d @"/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-06/2-dynatrace-dashboard-layout-json/App-Health-Layout-Classic.json"
```

---

## Row coverage checklist

| Visual row | New Dashboards tile IDs | Classic tiles |
| --- | --- | --- |
| 1 App selector | variable `app` + markdown `1` | Markdown instructions |
| 2 Critical header | markdown `2` | HEADER |
| 3 Problems / Root Cause / Alert Summary | data `3` `4` `5` | OPEN_PROBLEMS + Markdown ×2 |
| 4 App perf header | markdown `6` | HEADER |
| 5 Requests / Errors / Response Time | data `7` `8` `9` | DATA_EXPLORER ×3 |
| 6 Infra header | markdown `10` | HEADER |
| 7 Win CPU / Linux CPU / Memory | data `11` `12` `13` | DATA_EXPLORER ×3 |
| 8 Logs header | markdown `14` | HEADER |
| 9 Error Logs / Exception Traces | data `15` `16` | Markdown links (Classic limit) |
| 10 DB header | markdown `17` | HEADER |
| 11 DB / Queries / External | data `18` `19` `20` | DATA_EXPLORER ×3 |

---

## After import — make filters real

| Action | Why |
| --- | --- |
| Tag services `app:eip`, `app:api`, `app:payment` | Name/`$app` contains filter works better with consistent names/tags |
| Rename chips in variable CSV if needed | Match real product names |
| Narrow DB tiles to real DB service names | Name contains sql/db/jdbc is a starter heuristic |
| Split Win/Linux using real `osType` values in your tenant | entityAttr values differ by agent version |

---

## Investigation

Built from layout visual + Dynatrace document schema v21 + classic Config API tile models used in your Terraform `dynatrace_json_dashboard` module.

---

## Result

Import **`App-Health-Layout-Dashboards.json`** into new Dashboards to satisfy the picture (including Row 1 selector). Use Classic JSON only if your team still lives on Dashboards Classic / Terraform classic JSON.

---

## Data flow map

```
JSON file
  → Dashboards import / Edit JSON
  → Variable $app
  → DQL tiles (Problems → KPIs → Hosts → Logs → DB)
  → L1 screen matches 11-row visual
```

---

## Related files

| File | Purpose |
| --- | --- |
| `App-Health-Layout-Dashboards.json` | New Dashboards import |
| `App-Health-Layout-Classic.json` | Classic / API import |
| `2.sh` | Open paths / sample curl |
| Layout build guide | `../1-dynatrace-dashboard-layout-build/` |

## Commands

See [`2.sh`](./2.sh).
