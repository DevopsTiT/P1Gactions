# Working Snow Pd Workflow Yaml

```
Need SNOW tasks + PD?
  → Upload 1-open (prepare → SNOW + PD parallel → cross-link)
  → Upload 2-close (search INC → resolve SNOW + resolve PD)
  → Map Connection to silvastg
  → Keep classic ITSM OFF
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Working files | Open + close YAML with **ServiceNow tasks** and PagerDuty |
| SNOW tasks (open) | `create-servicenow-incident`, `cross-link-snow-pd` |
| SNOW tasks (close) | `search-snow-incident`, `resolve-snow-incident` |
| Classic notification | Keep `servicenowstg` ITOM if you want events; **ITSM OFF** |

## Summary

These workflows include ServiceNow Connection tasks and PagerDuty in parallel. Upload both YAML files, map the Connection, set the PD key and assignMap sys_ids, Activate, then test.

---

## Investigation

User asked for SNOW tasks in addition to the PD-only working files (seq 12).

## Result

| Upload | File |
| --- | --- |
| OPEN | `1-open-problem-to-snow-pagerduty.workflow.yaml` |
| CLOSE | `2-close-problem-resolve-snow-pd.workflow.yaml` |

Path: `Daily Files/2026-09-17/13-working-snow-pd-workflow-yaml/`

---

## Task list

### OPEN

| Task | Action |
| --- | --- |
| prepare-payload | JS — caller, biz service, assign, P3/P4, DT link, app, L1–L3, runbook |
| create-servicenow-incident | `snow-create-incident` (Connection) |
| create-pagerduty-incident | JS → PagerDuty (parallel) |
| cross-link-snow-pd | `snow-comment-on-incident` with PD dedup_key |

### CLOSE

| Task | Action |
| --- | --- |
| prepare-close-ids | JS — problemId + dedupKey |
| search-snow-incident | `snow-search-incidents` by correlation_id |
| resolve-snow-incident | `snow-resolve-incident` |
| resolve-pagerduty | JS resolve |

---

## Before Activate

1. **Connection** to `https://silvastg.service-now.com` (user like `Tech_DynatraceJP_WS` or OAuth).  
2. Classic **servicenowstg**: **Send incidents ITSM = OFF** (workflow creates INC). ITOM optional.  
3. Allowlist: `silvastg.service-now.com` + `events.pagerduty.com`.  
4. Replace `__PD_ROUTING_KEY__` and `__SNOW_*_SYS_ID__` / edit `assignMap`.  
5. Upload → map Connection on all SNOW tasks → Activate both.  
6. Test open + close.

---

## Data flow map

```
Problem OPEN
  prepare → SNOW Create INC ──┐
           PD trigger ────────┴→ comment PD key on INC
Problem CLOSE
  search INC → resolve SNOW
  resolve PD (same dedup_key)
```

## Related files

| Path | Why |
| --- | --- |
| YAML in this folder | Working upload files with SNOW tasks |
| `../12-working-pd-workflow-yaml/` | PD-only (no SNOW tasks) |
| `13.sh` | Paths |

## Commands

See `13.sh` in this folder.
