# Open Close Default Development

```
New INC defaults
  Environment      = Development
  Business service = QA Platforms
  Service offering = QA Platforms - AXA GROUP OPERATIONS (full Name ... - Production - ToD Web subscription)
Run OPEN → notFilled?
  serviceOffering blank → SNOW may only allow offerings that match the environment
                        → ask SILVA admin for the Development offering, or use Production
  environment blank     → "Development" not a choice label → check u_environment choices
  none                  → done
```

## Short takeaway

| Question | Answer |
|---|---|
| Default environment | Development |
| Default business service | QA Platforms (as in the screenshot) |
| Default service offering | "QA Platforms - AXA GROUP OPERATIONS - Production - ToD Web subscription" (as in the screenshot) |
| CLOSE changed? | No. CLOSE already uses QA Platforms and does not send the environment. |

## Summary

OPEN sends Development as the environment. The business service and offering are exactly the records in the screenshot. The offering record itself is marked Production, so watch `notFilled` in case SILVA rejects the combination.

## OPEN settings

```javascript
const BUSINESS_SERVICE = "QA Platforms";
// Must be the offering's full Name; SNOW matches the whole label, not the short text in the form
const SERVICE_OFFERING = "QA Platforms - AXA GROUP OPERATIONS - Production - ToD Web subscription";
const FIXED_ENVIRONMENT = "Development";
const DEFAULT_ENVIRONMENT = "Development";
```

| Setting | Seq 13 | Seq 14 |
|---|---|---|
| `FIXED_ENVIRONMENT` | Production | Development |
| `DEFAULT_ENVIRONMENT` | Production | Development |
| `BUSINESS_SERVICE` | QA Platforms | QA Platforms |
| `SERVICE_OFFERING` | ... - Production - ToD Web subscription | ... - Production - ToD Web subscription |

## Things to know

| Point | Why it matters |
|---|---|
| The offering is a Production record while the ticket says Development | Some SNOW setups filter offerings by environment and leave the field blank. `notFilled` will show it. |
| The form shows only "QA Platforms - AXA GROUP OPERATIONS" | The API needs the full Name, which is why the long text is used. |
| Name does not match | Put the offering's sys_id in `SERVICE_OFFERING` (lookup in `14.sh`). |

## Data flow map

```
FIXED_ENVIRONMENT "Development" ──► u_environment
BUSINESS_SERVICE  "QA Platforms" ──► business_service
SERVICE_OFFERING  full Name      ──► service_offering
        │
        ▼
POST incident ──► notFilled shows any label SNOW could not match
```

## Related files

| File | Purpose |
|---|---|
| `1-open-silva-http-and-pagerduty.workflow.yaml` | OPEN with Development and the screenshot's service values |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE, same as seq 13 |
| `14.sh` | Offering lookup, environment choices, and a check of new tickets |

Commands: see `14.sh` in this folder.
