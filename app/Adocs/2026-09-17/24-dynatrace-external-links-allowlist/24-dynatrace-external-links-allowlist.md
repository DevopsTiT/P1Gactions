# Dynatrace External Links Allowlist

```
Workflow fails with "host not allowed" / blocked outbound?
  │
  ├─ Calling ServiceNow? → allow silvastg.service-now.com
  ├─ Calling PagerDuty fetch? → allow events.pagerduty.com
  └─ Only putting a URL in ticket text? → no allowlist needed for that host
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What this is | Dynatrace **External requests** allowlist (hosts Workflows / apps may call outbound) |
| Why you care | Without the host listed, Connector and JS `fetch` fail even if credentials are correct |
| Must grant for this pack | `silvastg.service-now.com` and `events.pagerduty.com` |
| How to enter | Hostname only (no `https://`, no path) |

## Summary

For the ServiceNow Connector + PagerDuty architecture, grant two outbound hosts in Dynatrace. ServiceNow is for Connector Table API calls. PagerDuty is for the JavaScript `fetch` to Events API. Runbook or Problem URLs stored as text do not need allowlisting unless Dynatrace itself fetches them.

---

## Investigation

User asked which external links must be granted in Dynatrace for this design. Based on seq 19–23 workflows: Connector → SNOW instance host; JS → `events.pagerduty.com`. Classic notification also uses the same SNOW host when ITOM stays ON.

## Result

Grant the two hosts below. Optional hosts only if you add more `fetch` targets later.

---

## 1) What “external link / allowlist” means

| Concept | What it means | Why you care |
| --- | --- | --- |
| External requests | Dynatrace setting that lists which **outside hostnames** Workflows and some integrations may call | Security control so scripts cannot call arbitrary internet hosts |
| Grant / allowlist | Add the hostname so outbound HTTPS is permitted | Missing entry = task error even with valid password/key |
| Not the same as Connection | Connection stores SNOW URL + credentials | Allowlist only answers “is this host allowed to be contacted?” |

Where (UI wording varies slightly by version):

| Step | What to do |
| --- | --- |
| 1 | Open **Settings** |
| 2 | Find **External requests** (sometimes under Workflows / outbound / allow outbound) |
| 3 | **Add** each hostname |
| 4 | **Save** |

---

## 2) Hosts you must grant for this architecture

| Hostname to grant | Who needs it | What call uses it |
| --- | --- | --- |
| `silvastg.service-now.com` | ServiceNow Connector (`snow-create-incident`, comment, search, resolve) and optional classic notification | `https://silvastg.service-now.com/api/now/v2/table/incident` … |
| `events.pagerduty.com` | JS tasks `create-pagerduty-incident` / `resolve-pagerduty` | `POST https://events.pagerduty.com/v2/enqueue` |

### Fake examples (same shape as yours)

| Field | Fake / example value |
| --- | --- |
| SNOW allowlist entry | `silvastg.service-now.com` |
| PD allowlist entry | `events.pagerduty.com` |
| Full SNOW URL in Connection | `https://silvastg.service-now.com` (Connection uses full URL; allowlist uses host only) |

---

## 3) How to write the entry (common mistakes)

| Do | Do not |
| --- | --- |
| `silvastg.service-now.com` | `https://silvastg.service-now.com` |
| `events.pagerduty.com` | `https://events.pagerduty.com/v2/enqueue` |
| Host only | Path, query string, or trailing slash as the allowlist value |
| One host per outbound system | Guessing IP instead of hostname (use the DNS name Dynatrace will call) |

| Mistake | What happens |
| --- | --- |
| Allowlist has `https://...` | Entry may not match; outbound still blocked |
| Only allowlisted SNOW, forgot PD | INC works, PagerDuty `fetch` fails |
| Only allowlisted PD, forgot SNOW | PD works, Connector create/search fails |
| Typo `silvastage` vs `silvastg` | Intermittent or always-fail outbound |

---

## 4) What you do NOT need to allowlist (for this pack)

| URL that appears in tickets / PD | Allowlist needed? | Why |
| --- | --- | --- |
| Dynatrace Problem URL | No | Dynatrace already owns that; you only put the string in description |
| Confluence runbook URL (`confluence.example/...`) | No | Stored as text in INC/PD; workflow does not `fetch` it |
| PagerDuty web UI (`*.pagerduty.com` app pages) | No | Humans open the UI; workflow only calls `events.pagerduty.com` |

Add a host only if a Workflow task (Connector or `fetch`) will **call** that host.

---

## 5) Optional / later hosts

| If you add this later | Grant this host |
| --- | --- |
| JS REST directly to another SNOW URL | That SNOW hostname |
| Slack / Teams / webhook `fetch` | That webhook hostname |
| Different PD region endpoint (rare) | Whatever host your Events API URL uses |

For the current Connector + PD pack, **only the two required hosts** above.

---

## 6) Checklist before Activate

| Check | Example |
| --- | --- |
| External requests includes SNOW | `silvastg.service-now.com` |
| External requests includes PD | `events.pagerduty.com` |
| Connection URL host matches allowlist | Connection = `https://silvastg.service-now.com` |
| Classic notification host matches | `servicenowstg` URL same instance host |
| After change | Re-run a test Problem / workflow execution |

---

## 7) Failure symptoms

| Symptom | Likely allowlist gap |
| --- | --- |
| snow-create / search / resolve fails with host blocked | Missing `silvastg.service-now.com` |
| Category/group dropdown fails in editor | Same SNOW host (UI helper queries) |
| PD trigger/resolve fails; INC OK | Missing `events.pagerduty.com` |
| Both fail | Neither host granted, or wrong spelling |

---

## Data flow map

```
Dynatrace Workflow
        │
        ├─ Connector ──► need allow: silvastg.service-now.com
        │                   POST/GET/PUT /api/now/v2/table/incident
        │
        └─ JS fetch ───► need allow: events.pagerduty.com
                            POST /v2/enqueue

Text-only links in description (Problem URL, runbook)
        └── no allowlist entry required
```

## Related files

| Path | Why |
| --- | --- |
| `../20-dynatrace-snow-pd-architecture/` | Full architecture |
| `../23-architecture-all-apis-involved/` | Exact API URLs behind these hosts |
| `../19-snow-connector-workflow-again/` | Workflows that need the grants |
| `24.sh` | Reminder lines |

## Commands

See `24.sh` in this folder.
