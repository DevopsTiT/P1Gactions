# Working Pd Workflow Yaml

```
Need a working workflow file?
  → Upload 1-open-*.yaml (Problem → PagerDuty)
  → Upload 2-close-*.yaml (Problem closed → resolve PD)
  → Replace __PD_ROUTING_KEY__
  → Keep servicenowstg ON for ServiceNow
  → Activate both → test
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| Working files | Two YAML files in this folder (open + close) |
| SNOW | Classic notification `servicenowstg` (not in these files) |
| Only edit | `__PD_ROUTING_KEY__` (same value in both files) |
| Allowlist | `events.pagerduty.com` |

## Summary

These are upload-ready Dynatrace Workflow YAML files for PagerDuty. ServiceNow stays on your classic Problem notification. Replace the PD routing key, allowlist the host, Activate, then test.

---

## Investigation

Matches chosen architecture: classic SNOW notification + PD workflow (seq 10/11). Schema uses filterQuery, categories map, position y ≥ 1.

## Result

| Upload order | File |
| --- | --- |
| 1 | `1-open-problem-to-pagerduty.workflow.yaml` |
| 2 | `2-close-problem-resolve-pagerduty.workflow.yaml` |

---

## How to use (UI)

1. Dynatrace → **Workflows** → **Upload** / Import.  
2. Select `1-open-problem-to-pagerduty.workflow.yaml`.  
3. Open task `create-pagerduty-incident` → replace `__PD_ROUTING_KEY__`.  
4. **Save** → **Activate**.  
5. Upload `2-close-problem-resolve-pagerduty.workflow.yaml` → same routing key → Activate.  
6. **Settings → External requests** → add `events.pagerduty.com`.  
7. Keep **servicenowstg** ON for SNOW.  
8. Test: open Problem → PD alert + SNOW ITOM event; close Problem → PD resolves.

---

## Data flow map

```
Problem OPEN  → open YAML → PagerDuty trigger
             → servicenowstg → SNOW ITOM
Problem CLOSE → close YAML → PagerDuty resolve
             → servicenowstg → SNOW ITOM update
```

## Related files

| Path | Why |
| --- | --- |
| YAML in this folder | Working upload files |
| `../10-classic-snow-notification-pd-workflow/` | Notification YAML backup |
| `../9-ago-snow-pd-parallel-workflow/` | If you want SNOW Connection INC instead |
| `12.sh` | Paths |

## Commands

See `12.sh` in this folder.
