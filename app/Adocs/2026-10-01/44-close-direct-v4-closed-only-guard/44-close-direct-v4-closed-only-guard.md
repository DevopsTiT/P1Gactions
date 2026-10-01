# Close Trigger Closed Only

## Decision tree

```
Problem trigger panel says "Event state: active or closed"
 Is there a "closed only" option?  NO → Dynatrace Problem trigger offers "active" or "active or closed"
 So the CLOSE workflow also runs when a problem OPENS
   v1 to v3: close tasks do not check status → could resolve a brand-new INC and PD alert   ✘ risky
   v4: prepare-close sets is_closed → close tasks skip unless closed                      ✔ safe
 Canvas title says "v1"?  → you imported seq 39; import seq 44 (v4) instead
```

## Short takeaway

| Question | Answer |
|---|---|
| Is "active or closed" right? | It is the only way to get close events from the Problem trigger. It is expected. |
| Can I set "closed only"? | No. The trigger has "active" and "active or closed". |
| Is that a problem? | Yes for v1 to v3: on a new problem they could resolve what OPEN just created. |
| Fix | v4 checks the problem is really closed before resolving anything. |
| Which file? | `44-close-direct-v4-closed-only-guard.workflow.yaml` |
| Imported version | The canvas shows v1 (seq 39). Replace it with v4. |

## Summary

The trigger setting is fine, but the workflow must filter itself. Version 4 reads the problem status from the Problems API (or the event if the API is not available) and only closed problems go on to SILVA and PagerDuty. On an open event, both close tasks return `skipped: problem is not closed`.

## How the closed check works

| Source | Closed when | Used when |
|---|---|---|
| Problems API `status` | `CLOSED` | Real events (most reliable, read at run time) |
| Event `event.status` | `CLOSED` | API not available, or manual Run |
| Event `event.status_transition` | `RESOLVED` or `CLOSED` | Same |

## What happens per event

| Event | prepare-close | close-silva-incident | close-pagerduty |
|---|---|---|---|
| Problem opens | `is_closed: false` | skipped (not closed) | skipped (not closed) |
| Problem updates while open | `is_closed: false` | skipped | skipped |
| Problem closes | `is_closed: true` | resolves INC (incident_state) | resolves PD alert |
| Manual Run (sample, status CLOSED) | `is_closed: true` | skipped unless ALLOW_SAMPLE_POST | skipped unless ALLOW_SAMPLE_POST |

## OPEN workflow trigger (for comparison)

| Workflow | Event state | Why |
|---|---|---|
| OPEN (seq 36) | active | Create tickets only on new problems. |
| CLOSE (seq 44) | active or closed | Needed to receive the close; v4 ignores the active ones. |

## Go-live steps

| Step | Action |
|---|---|
| 1 | Delete or deactivate the imported v1 draft (seq 39) and any v2 or v3. |
| 2 | Import `44-close-direct-v4-closed-only-guard.workflow.yaml`. |
| 3 | Leave the trigger as "active or closed". |
| 4 | Run once: expected `skipped` (INC30341416 already Resolved). |
| 5 | Deploy. |
| 6 | Next real problem: when it opens, CLOSE executions show `skipped (problem is not closed)`; when it closes, both resolve. |

## Data flow map

```
Problem trigger (active or closed)
   ▼
prepare-close ── is_closed? (Problems API status, else event status)
   ├─► close-silva-incident  not closed → skip | closed → PATCH incident_state Resolved
   └─► close-pagerduty       not closed → skip | closed → resolve dt-problem-<id>
```

## Related files

| File | Purpose |
|---|---|
| `44-close-direct-v4-closed-only-guard.workflow.yaml` | Close workflow to use. Secrets inside, never commit. |
| `43-close-direct-v3-incident-state/` | v3 (unchanged, no closed guard). |
| `36-standard-flow-preview-then-post/` | OPEN (unchanged). |
| `44.sh` | Mirror lines only. |

## Commands

See `44.sh`. Only the folder copy lines.
