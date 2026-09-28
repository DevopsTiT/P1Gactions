# Close INC30339677 Workflow Ticket

```
Close INC30339677 (testing 3122, problem P-260915247)
 Best: let the sync close it
   → Dynatrace problem P-260915247 goes CLOSED
   → CLOSE workflow finds INC by correlation_id = P-260915247
   → PATCH state 6 (Resolved) + PagerDuty resolve (dedup_key dt-problem-P-260915247)
 Problem still open and you want it closed now?
   → close the problem in Dynatrace (UI or Problems API) → CLOSE workflow runs
 CLOSE workflow ran but INC still New?
   → check the run result: found=false → correlation_id not stored on the INC
   → HTTP 4xx → password / allowlist / ACL
 Just want it gone by hand?
   → form: State = Resolved + Resolution code + Resolution notes → Update
   → PagerDuty incident stays open → resolve it in PagerDuty too
```

## Short takeaway

| Question | Answer |
|---|---|
| Who created this ticket? | The OPEN workflow. Contact type is Event, and the Summary has the "Additional Information" JSON block. |
| What links it to Dynatrace? | `correlation_id` = `P-260915247`. The same value is in External Ticket Number. |
| Best way to close it | Let Dynatrace close problem P-260915247. The CLOSE workflow then resolves the INC and the PagerDuty incident together. |
| Fast way | Close the problem in Dynatrace by hand, which still triggers the CLOSE workflow. |
| Manual SNOW close | Works, but PagerDuty stays open, so resolve it there too. |

## Summary

Because this INC came from the workflow, you should close it from the Dynatrace side. That keeps SNOW and PagerDuty in step. Closing only in SNOW leaves the PagerDuty incident and the Dynatrace problem open.

## What the ticket shows

| Field | Value in INC30339677 | What it means |
|---|---|---|
| Number | INC30339677 | The ticket to close. |
| Incident State | New | Not resolved yet. |
| Contact type | Event | Created by automation, not by hand. |
| Assignment group | testing 3122 | The test override worked. |
| Impact / Urgency | 3 - Medium | The problem had medium severity. |
| Environment | Production | Read from the AGO environment tag. |
| External Ticket Number | P-260915247 | Dynatrace problem display ID. |
| correlation_id (in Summary JSON) | P-260915247 | The key the CLOSE workflow searches on. |
| problem_id (in Summary JSON) | -7958242114081464045_1790571960000V2 | Internal problem ID. You need it to close the problem by API. |

## Option 1: Let the sync close it (recommended)

| Step | What happens |
|---|---|
| 1 | Problem P-260915247 closes in Dynatrace, either on its own when the disk issue clears or when you close it. |
| 2 | The CLOSE workflow triggers on the CLOSED event. |
| 3 | `prepare-close-ids` builds correlation_id `P-260915247` and dedup_key `dt-problem-P-260915247`. |
| 4 | `resolve-silva-incident-http` finds INC30339677 and sets state 6 (Resolved) with close notes. |
| 5 | `resolve-pagerduty` resolves the PagerDuty incident. |
| 6 | Later, SNOW moves the INC from Resolved to Closed with its auto-close timer. |

## Option 2: Close the problem by hand in Dynatrace

| Where | How |
|---|---|
| Dynatrace UI | Open problem P-260915247 and click **Close**, if your role allows it. Custom alert problems can usually be closed by hand. |
| Problems API | POST `/api/v2/problems/<problem_id>/close` with a message. The command is in `10.sh`. The token needs the `problems.write` scope. |

Either way, the CLOSE workflow then does the SNOW and PagerDuty work.

## Option 3: Close only in SNOW (manual)

| Step | What to do |
|---|---|
| 1 | Set Incident State to Resolved. |
| 2 | In Resolution Information, set Resolution code to "Solved (Permanently)". |
| 3 | Write Resolution notes, for example "Test ticket for Dynatrace and PagerDuty integration." |
| 4 | Click Update. |
| 5 | Resolve the matching incident in PagerDuty by hand. |

If the problem closes later, the CLOSE workflow runs again and tries to resolve an INC that is already resolved. That is harmless.

## If the CLOSE workflow ran but the INC is still New

| What you see in the run | Likely cause | Fix |
|---|---|---|
| `found: false` | correlation_id was not saved on the INC, even though it is in the Summary text. | Run the first command in `10.sh` and check the correlation_id field. |
| HTTP 401 | Wrong password. | Re-check the password line in the CLOSE YAML. |
| HTTP 403 | The API user cannot update incidents. | Ask the SILVA admin for write access on incident. |
| Network or allowlist error | `silvastg.service-now.com` is not allowlisted. | Add it under Settings, External requests. |

## Things I noticed on this ticket

| Field | Seen | Workflow setting | Note |
|---|---|---|---|
| Short description | Testing-Dynatrace-Pagerduty | `[DYNATRACE JAPAN][<host>] - <title>` | Fine if you set it on purpose for testing. |
| Business service | QA Platforms | Third Party Services Monitoring Application (also shown in the Summary JSON) | The field and the JSON differ. Either the YAML was edited or SNOW replaced the value. |
| Service offering | QA Platforms - AXA GROUP OPERATIONS | Third Party Services Monitoring Application | Same as above. |
| Configuration item | Empty | Host name | SNOW did not match the host to a CMDB record, so it left the field blank. |

## Data flow map

```
Problem P-260915247 CLOSED (auto or manual close)
        │
        ▼
CLOSE workflow ── prepare-close-ids ──► correlation_id P-260915247
        │                              dedup_key dt-problem-P-260915247
        ├──► resolve-silva-incident-http
        │      GET incident?correlation_id=P-260915247 → INC30339677 sys_id
        │      PATCH state 6 + close_notes + comments → Resolved
        └──► resolve-pagerduty
               POST enqueue resolve dedup_key → PD resolved
        ▼
SNOW auto-close timer → Closed
```

## Related files

| File | Purpose |
|---|---|
| `10.sh` | Commands to check the INC, close the problem, and resolve by API as a backup |
| `../8-open-close-with-credentials/2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE workflow |
| `../9-close-silva-test-ticket/` | General guide for closing a hand-made test ticket |

Commands: see `10.sh` in this folder.
