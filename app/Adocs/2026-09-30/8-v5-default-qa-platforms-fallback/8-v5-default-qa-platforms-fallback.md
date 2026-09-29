# V5 Default Set Fallback

## Decision tree

```
After A (map), B (CI link), C (scored search), D (first answer):
 │
 ├─ business service found AND group found → use them (normal ticket)
 │
 ├─ only business service missing
 │    └─ business service = QA Platforms (single-field default)
 │
 ├─ only group missing
 │    └─ group = service group → CI group → Ops_Middleware_Monitoring_AXAJP
 │
 └─ BOTH missing → DEFAULT SET (default_set_used = true)
      ├─ Environment      = PoC / VoA / Demo
      ├─ Business service = QA Platforms
      ├─ Service Offering = QA Platforms - AXA GROUP OPERATIONS ...
      ├─ Assignment group = Ops_Middleware_Monitoring_AXAJP
      ├─ Company          = QA Platforms company, else AXA GROUP OPERATIONS
      └─ Assigned to      = optional setting (empty by default)
```

## Short takeaway

| Question | Answer |
|---|---|
| What is v5? | v4 plus one default set used when both the business service and the group are not found |
| Where is it? | `8-v5-default-qa-platforms-fallback.workflow.yaml` (v4 is unchanged) |
| How do I know the default set was used? | `snow_required.default_set_used` is true, and every `from` says "default set" |
| Will the Oracle event use it? | No. The group tag Database_AXAJP exists, so the group is found |
| Is anything sent? | No. Still read only with previews. |

## Summary

v5 adds a safe landing place for alerts that match nothing. When the workflow cannot find a business service and cannot find a group, it fills the SNOW form with the QA Platforms set from your screenshot, so the mandatory fields are always filled and the ticket reaches Ops_Middleware_Monitoring_AXAJP for triage.

## Default set values

| Form field | Payload field | Default value | Setting |
|---|---|---|---|
| Environment | `u_environment` | PoC / VoA / Demo | `DEFAULT_ENVIRONMENT_LABEL` (task 2) |
| Business service | `business_service` | QA Platforms | `DEFAULT_BUSINESS_SERVICE` (task 2) |
| Service Offering | `service_offering` | QA Platforms - AXA GROUP OPERATIONS - Production - ToD Web subscription | `DEFAULT_SERVICE_OFFERING` (task 2, "starts with") |
| Assignment group | `assignment_group` | Ops_Middleware_Monitoring_AXAJP | `DEFAULT_GROUP` (task 2) |
| Company | `company` | QA Platforms company, else AXA GROUP OPERATIONS | `DEFAULT_COMPANY` (task 3) |
| Assigned to | `assigned_to` | Empty (set "Shuge KUI" if wanted) | `DEFAULT_SET_ASSIGNED_TO` (task 3) |
| Impact | `impact` | 4 | `IMPACT` (task 3) |
| Urgency | `urgency` | 4 | `URGENCY` (task 3) |

## How the offering is found

| Try | Query |
|---|---|
| 1 | `service_offering` where `parent.name=QA Platforms` and name starts with "QA Platforms - AXA GROUP OPERATIONS" |
| 2 | `service_offering` where name starts with "QA Platforms - AXA GROUP OPERATIONS" |

The form shows "QA Platforms - AXA GROUP OPERATIONS", but the real record name is longer ("... - Production - ToD Web subscription"). A "starts with" match finds it either way.

## When each rule fires

| Case | Business service | Group | Environment |
|---|---|---|---|
| Both found | Found value | Found value | From tags |
| Service missing only | QA Platforms | Found value | From tags |
| Group missing only | Found value | Service group, CI group, or default group | From tags |
| Both missing | QA Platforms | Ops_Middleware_Monitoring_AXAJP | PoC / VoA / Demo |

## Data flow

```
TASK 1 extract ──► TASK 2
                     │ A, B, C, D searches
                     │ service found?  group found?
                     │   ├─ both no  → DEFAULT SET
                     │   └─ otherwise → single-field fallbacks
                     ▼
                   snow_required (default_set_used, from fields)
                     ▼
                   TASK 3 → snow_incident_payload + snow_form_check
```

## Related files

| File | What it is |
|---|---|
| `8-v5-default-qa-platforms-fallback.workflow.yaml` | New workflow |
| `../3-extract-v4-business-service-and-group/` | v4, unchanged |
| `8.sh` | Checks the default records exist in SILVA |

## Commands

See `8.sh`.
