# Keep Snow Notification Working

```
Keep ServiceNow notify from Dynatrace?
  │
  ├─ 1 Leave classic Problem notification ON (servicenowstg)
  ├─ 2 Keep URL + user + password valid
  ├─ 3 ITOM ON (your pic); ITSM OFF if workflow also creates INC
  ├─ 4 Allowlist silvastg.service-now.com
  ├─ 5 Do not replace it with a Workflow Connection task
  └─ 6 Test: open a Problem → check SNOW event/INC
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What “keep notification” means | Classic **Problem notifications** stays ON and healthy |
| Your config | `servicenowstg` → `https://silvastg.service-now.com` |
| Your toggles | ITSM **OFF**, ITOM **ON** (events to SNOW) |
| Workflow role | PagerDuty only — do not delete the classic SNOW notification |

## Summary

To keep notifying ServiceNow, leave **Settings → Problem notifications → servicenowstg** enabled, credentials valid, host allowlisted, and alerting profile matching your Problems. Workflows for PagerDuty do not replace this — they run beside it.

---

## Investigation

You chose classic notification (pic) instead of Workflow ServiceNow Connection. Pack `../10-classic-snow-notification-pd-workflow/` has YAML backup.

## Result

Follow the checklist below. Do not turn the notification OFF when you activate PD workflows.

---

## 1) What keeps SNOW notified

| Piece | Role |
| --- | --- |
| Problem notification `servicenowstg` | Pushes Dynatrace Problems to ServiceNow |
| Alerting profile (e.g. Default) | Which Problems are sent |
| URL + username/password | Auth to silvastg |
| ITOM ON | Creates/updates SNOW **events** |
| External requests allowlist | Dynatrace may call silvastg |

```
Dynatrace Problem
  → alerting profile matches
  → servicenowstg notification ON
  → HTTPS to silvastg.service-now.com
  → ServiceNow ITOM event
```

---

## 2) UI — keep it (do these)

### A) Confirm notification is ON

1. Dynatrace → **Settings** → **Integration** → **Problem notifications**.  
2. Find **servicenowstg**.  
3. Toggle must be **ON** (green).  
4. Open it and confirm:

| Field | Keep as |
| --- | --- |
| Notification type | ServiceNow |
| Display name | `servicenowstg` |
| OnPremise URL | `https://silvastg.service-now.com` |
| Username | `Tech_DynatraceJP_WS` |
| Password | Set / Change if expired |
| Send incidents (ITSM) | **OFF** (your choice) |
| Send events (ITOM) | **ON** |
| Alerting profile | Default (or the profile you need) |

5. **Save** if you change anything.

### B) Keep allowlist

1. **Settings** → **External requests**.  
2. Ensure `silvastg.service-now.com` is listed.  
3. **Save**.

### C) Keep SNOW account healthy

| Check | Why |
| --- | --- |
| Password not expired | Notification fails with 401 |
| Roles still present | `web_service_admin`, `x_dynat_ruxit.Integration` (per UI hint) |
| Instance reachable | silvastg staging up |

### D) Keep Workflow from replacing it

| Do | Do not |
| --- | --- |
| Upload **PD-only** workflows | Delete `servicenowstg` |
| Leave classic notification ON | Add `snow-create-incident` unless you want workflow-owned ITSM INC |
| Test PD + SNOW separately | Assume Connection is required for ITOM events |

---

## 3) If you also use Workflows (recommended split)

| Channel | Owner |
| --- | --- |
| ServiceNow | Classic notification `servicenowstg` |
| PagerDuty | Workflow open + close (PD-only YAML) |

YAML backup + PD workflows: `../10-classic-snow-notification-pd-workflow/`

---

## 4) When ITSM vs ITOM matters

| Toggle | What SNOW gets | Keep if |
| --- | --- | --- |
| ITOM ON | Events | You want event notify (your pic) |
| ITSM ON | Incidents | You want classic INC (generic DT fields) |
| Both OFF | Nothing from this notification | Broken “keep notify” |

Your current choice (**ITSM OFF / ITOM ON**) **keeps SNOW notified** via events.

If later you turn ITSM ON **and** run Connection Create Incident → duplicate INC risk.

---

## 5) Test that notification still works

1. Create or wait for a Problem that matches the alerting profile.  
2. In Dynatrace: Problem exists.  
3. In ServiceNow silvastg: look for new/updated **ITOM event** (not necessarily INC).  
4. If missing:

```
Notification ON?
  → Password / roles OK?
  → Allowlist OK?
  → Alerting profile matches Problem?
  → SNOW instance up?
```

---

## 6) Optional: keep as code (backup)

Use files from seq 10 (do not need to re-apply if UI is already correct):

- `servicenowstg-problem-notification.settings.json`  
- `servicenowstg-problem-notification.monaco.yaml`  

Replace `__SNOW_PASSWORD__` and `__ALERTING_PROFILE_ID__` only if you deploy via API/Monaco.

---

## Data flow map

```
You keep servicenowstg ON
  → Problem fires
  → Dynatrace calls silvastg
  → SNOW ITOM event
  → (optional) PD workflow pages on-call
```

## Related files

| Path | Why |
| --- | --- |
| `../10-classic-snow-notification-pd-workflow/` | Notification YAML + PD-only workflows |
| `../9-ago-snow-pd-parallel-workflow/` | Alternative: Workflow owns ITSM INC |
| `11.sh` | Reminders |

## Commands

See `11.sh` in this folder.
