# Open Close Fill Like INC30339677

```
Want new tickets to look like INC30339677
 Import seq 11 OPEN + CLOSE (password and routing key already inside)
 Trigger a test problem
   → INC created?
       yes → compare with INC30339677
             Short description = Testing-Dynatrace-Pagerduty ?
             Business service = QA Platforms ?
             Service offering = QA Platforms - AXA GROUP OPERATIONS ?
             Assignment group = testing 3122 ?
             any blank → check notFilled in post-silva-incident-http result
       no  → task error: 401 password / 403 access / allowlist
 Problem closes → CLOSE resolves INC + PagerDuty
 Done testing?
   → FIXED_SHORT_DESCRIPTION = "" (back to [DYNATRACE JAPAN][host] - title)
   → TEST_ASSIGNMENT_GROUP = "" (normal routing)
   → set the real business service
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed from seq 8? | Short description, business service and service offering now match INC30339677. |
| Which files? | `1-open-silva-http-and-pagerduty.workflow.yaml` and `2-close-silva-http-and-pagerduty.workflow.yaml` in this folder. |
| Are the password and routing key inside? | Yes, the same as seq 8. |
| What stays automatic? | Environment, impact, urgency, summary JSON, correlation_id and PagerDuty dedup_key. |

## Summary

The workflow now fills in the same fixed values you set on INC30339677. Everything tied to the real problem (title, host, severity, IDs) still comes from Dynatrace, so OPEN and CLOSE stay in sync.

## Field by field: INC30339677 vs the workflow

| Ticket field | Value on INC30339677 | Where the workflow gets it |
|---|---|---|
| Caller | Dynatrace JP | `caller_id` = API user Tech_DynatraceJP_WS (unchanged) |
| Contact type | Event | `CONTACT_TYPE` (unchanged) |
| Company | AXA GROUP OPERATIONS | `COMPANY` (unchanged) |
| Environment | Production | Tag AGO_AXAENVIRONMENTNAME, else Production (unchanged) |
| Business service | QA Platforms | `BUSINESS_SERVICE` (**changed**) |
| Service offering | QA Platforms - AXA GROUP OPERATIONS | `SERVICE_OFFERING` (**changed**) |
| Category / Subcategory | Other / Other | `DEFAULT_CATEGORY` (unchanged) |
| Impact / Urgency | 3 - Medium | From problem severity (unchanged) |
| Assignment group | testing 3122 | `TEST_ASSIGNMENT_GROUP` (unchanged) |
| External Ticket Number | P-260915247 | Not sent by the workflow; SILVA fills it itself |
| Short description | Testing-Dynatrace-Pagerduty | `FIXED_SHORT_DESCRIPTION` (**new**) |
| Summary | Title, then Additional Information JSON | `notificationDescription` (unchanged; the JSON now shows QA Platforms) |

## Code changes

OPEN, settings block:

```javascript
const TEST_ASSIGNMENT_GROUP = "testing 3122";
const FIXED_SHORT_DESCRIPTION = "Testing-Dynatrace-Pagerduty";
const SHORT_PREFIX = "[DYNATRACE JAPAN]";
const CONTACT_TYPE = "Event";
const COMPANY = "AXA GROUP OPERATIONS";
const APPLICATION = "EIP";
const BUSINESS_SERVICE = "QA Platforms";
const SERVICE_OFFERING = "QA Platforms - AXA GROUP OPERATIONS";
```

OPEN, return value:

```javascript
shortDescription: (FIXED_SHORT_DESCRIPTION ||
  SHORT_PREFIX + "[" + (ciName || where) + "] - " + problemTitle).slice(0, 160),
```

CLOSE, settings block:

```javascript
const BUSINESS_SERVICE = "QA Platforms";
```

## Things to know

| Point | Why it matters |
|---|---|
| Every test ticket gets the same short description | You tell tickets apart by the Summary first line (the problem title) or by External Ticket Number. |
| A tag `snow-service` on the entity overrides QA Platforms | Only if such a tag exists. It did not on INC30339677. |
| Label must match exactly | If "QA Platforms - AXA GROUP OPERATIONS" differs by one character, SNOW leaves it blank. `notFilled` will list it. |
| The files contain the password | Do not commit or push the `app/Adocs` copy. |

## Data flow map

```
Problem ACTIVE
   │
prepare-payload ── fixed: short description, QA Platforms, offering, testing 3122, Event, company
   │               from problem: title, host, severity → impact/urgency, environment tag, IDs
   ├──► post-silva-incident-http → INC like INC30339677 (correlation_id = P-xxxxxx)
   └──► trigger-pagerduty        → PD incident (dedup_key dt-problem-P-xxxxxx)

Problem CLOSED
   │
prepare-close-ids (business service QA Platforms in notes)
   ├──► resolve-silva-incident-http → INC Resolved
   └──► resolve-pagerduty           → PD resolved
```

## Related files

| File | Purpose |
|---|---|
| `1-open-silva-http-and-pagerduty.workflow.yaml` | OPEN workflow, filled like INC30339677 |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE workflow, business service QA Platforms |
| `11.sh` | Diff against seq 8 and SNOW checks |
| `../10-close-inc30339677-workflow-ticket/` | How to close INC30339677 |

Commands: see `11.sh` in this folder.
