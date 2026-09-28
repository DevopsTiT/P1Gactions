# Open Close Default Environment And Service

```
New INC should show
  Environment      = Production
  Business service = QA Platforms
  Service offering = QA Platforms - AXA GROUP OPERATIONS (full Name ... - Production - ToD Web subscription)
Run OPEN → look at notFilled
  serviceOffering blank?
    → label not matched → run 13.sh offering query → copy exact Name (or sys_id) into SERVICE_OFFERING
  environment blank?
    → "Production" not a choice label → check sys_choice for u_environment
  all filled → done
Need a non-Production offering later?
  → change SERVICE_OFFERING and FIXED_ENVIRONMENT together
```

## Short takeaway

| Question | Answer |
|---|---|
| Environment default | Production, always, via the new `FIXED_ENVIRONMENT`. |
| Business service default | QA Platforms, and it now wins over any `snow-service` tag. |
| Service offering | The full record Name: "QA Platforms - AXA GROUP OPERATIONS - Production - ToD Web subscription". |
| Why the long name? | The form shows only the start of the Name. SNOW matches the whole Name when the API sends a label. |
| Base | Seq 12, with the group, assignee, "Resolved" comment, password and routing key kept. |

## Summary

Tickets now always get Production, QA Platforms, and the exact Production offering from your screenshot. Tags no longer change these three fields, so the environment and the offering can't disagree.

## OPEN changes

| Item | Before (seq 12) | Now (seq 13) |
|---|---|---|
| `SERVICE_OFFERING` | "QA Platforms - AXA GROUP OPERATIONS" | "QA Platforms - AXA GROUP OPERATIONS - Production - ToD Web subscription" |
| `FIXED_ENVIRONMENT` (new) | Not present | "Production" |
| Environment order | Tag, then Production | FIXED_ENVIRONMENT, then tag, then Production |
| Business service order | Tag `snow-service`, then QA Platforms | QA Platforms, then tag |

```javascript
const BUSINESS_SERVICE = "QA Platforms";
// Must be the offering's full Name; SNOW matches the whole label, not the short text in the form
const SERVICE_OFFERING = "QA Platforms - AXA GROUP OPERATIONS - Production - ToD Web subscription";
// The offering above is a Production offering, so keep this in step with it
const FIXED_ENVIRONMENT = "Production";
```

```javascript
const environment =
  FIXED_ENVIRONMENT ||
  tagValue(tags, "ago_axaenvironmentname") ||
  ENVIRONMENT[tagValue(tags, "env").toLowerCase()] ||
  DEFAULT_ENVIRONMENT;
const businessService = BUSINESS_SERVICE || tagValue(tags, "snow-service");
```

## CLOSE changes

| Item | Before | Now |
|---|---|---|
| Business service order | Tag, then QA Platforms | QA Platforms, then tag |

## Things to know

| Point | What to do |
|---|---|
| The offering Name was read from a photo | If `notFilled` lists `serviceOffering`, run the offering query in `13.sh` and paste the exact Name. |
| Name still does not match | Put the offering's sys_id in `SERVICE_OFFERING`. SNOW also accepts a sys_id in a reference field. |
| Tags are ignored for these fields now | To go back to tag-driven values, set `FIXED_ENVIRONMENT = ""` and `BUSINESS_SERVICE = ""`. |
| Environment and offering must agree | The offering is the Production one, so change both together. |

## Data flow map

```
prepare-payload
   FIXED_ENVIRONMENT  "Production"      ──► u_environment
   BUSINESS_SERVICE   "QA Platforms"    ──► business_service
   SERVICE_OFFERING   full Name         ──► service_offering
   (tags only used if these are set to "")
        │
        ▼
post-silva-incident-http ──► INC ──► notFilled shows any label SNOW could not match
```

## Related files

| File | Purpose |
|---|---|
| `1-open-silva-http-and-pagerduty.workflow.yaml` | OPEN with default Production and QA Platforms |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE with QA Platforms first |
| `13.sh` | Offering and environment lookups |

Commands: see `13.sh` in this folder.
