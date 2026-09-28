# Open Close uk-sap-fscd-dev Defaults

```
New INC defaults
  Environment      = Development
  Business service = uk-sap-fscd-dev
  Service offering = uk-sap-fscd-dev - AXA GROUP OPERATIONS - Development - Standard
  Password and routing key = filled in (all copies)
Run OPEN → notFilled?
  businessService / serviceOffering blank → Name differs → run 15.sh lookups → paste exact Name or sys_id
  none → done
Never git add / push the app/Adocs copy (secrets inside)
```

## Short takeaway

| Question | Answer |
|---|---|
| Default business service | uk-sap-fscd-dev |
| Default service offering | uk-sap-fscd-dev - AXA GROUP OPERATIONS - Development - Standard |
| Default environment | Development, which now matches the offering record. |
| Password and routing key | Hardcoded in OPEN and CLOSE, in all three copies. |
| Base | Seq 14, with the title, group, assignee and "Resolved" comment kept. |

## Summary

The defaults now match the Development record in your screenshot, so the environment and the offering agree. The secrets are in every copy, including the git-tracked `app/Adocs` one.

## Settings

OPEN:

```javascript
const BUSINESS_SERVICE = "uk-sap-fscd-dev";
// Must be the offering's full Name; SNOW matches the whole label, not the short text in the form
const SERVICE_OFFERING = "uk-sap-fscd-dev - AXA GROUP OPERATIONS - Development - Standard";
const FIXED_ENVIRONMENT = "Development";
const DEFAULT_ENVIRONMENT = "Development";
```

CLOSE:

```javascript
const BUSINESS_SERVICE = "uk-sap-fscd-dev";
```

Secrets (the same two lines appear in OPEN and CLOSE):

```javascript
const password = "JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}";
const routingKey = "222651dbacb04403c0bf52d3b48499e8";
```

| Line | OPEN | CLOSE |
|---|---|---|
| `BUSINESS_SERVICE` | 87 | 66 |
| `SERVICE_OFFERING` | 90 | not used |
| `FIXED_ENVIRONMENT` | 91 | not used |
| `password` | 331 | 190 |
| `routingKey` | 436 | 273 |

## Things to know

| Point | What to do |
|---|---|
| The offering Name was read from a photo | If `notFilled` lists `serviceOffering`, run the lookup in `15.sh` and paste the exact Name. |
| `app/Adocs` now holds the password | Do not `git add` or push this folder. |
| Stop git picking it up | Optional: add the folder to `.gitignore` (the one-liner is in `15.sh`). |

## Data flow map

```
prepare-payload
  FIXED_ENVIRONMENT "Development"             ──► u_environment
  BUSINESS_SERVICE  "uk-sap-fscd-dev"         ──► business_service
  SERVICE_OFFERING  "... - Development - Standard" ──► service_offering
        │
        ├──► post-silva-incident-http (password) ──► INC
        └──► trigger-pagerduty (routing key)     ──► PD incident
CLOSE ──► same password and routing key ──► Resolved + PD resolve
```

## Related files

| File | Purpose |
|---|---|
| `1-open-silva-http-and-pagerduty.workflow.yaml` | OPEN with the uk-sap-fscd-dev defaults |
| `2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE with the uk-sap-fscd-dev business service |
| `15.sh` | Lookups and an optional .gitignore line |

Commands: see `15.sh` in this folder.
