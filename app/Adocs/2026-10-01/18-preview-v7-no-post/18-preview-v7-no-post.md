# PREVIEW v7 Prepared Data Without Posting

## Decision Tree

```
Davis problem (or Run = sample P-260916863)
 └─ 1 extract → 2 resolve (GET SILVA) → 3 build-payload          ← identical to OPEN v7
      └─ 4 preview-silva-incident
           ├─ field_check: each SILVA form field OK / MISSING / WRONG / EMPTY
           ├─ duplicate_check: GET open incident with same correlation_id
           └─ open_v7_would: CREATE incident | SKIP (reason)
      └─ 5 preview-pagerduty
           ├─ checks: event_action, dedup_key, summary, source, severity
           └─ open_v7_would: SEND trigger | NOT send
Nothing is POSTed anywhere.
```

## Short Takeaway

| Question | Answer |
|---|---|
| File | `18-preview-v7-no-post.workflow.yaml` |
| Sends anything? | No. No POST to SILVA, no PagerDuty call. Only GET lookups. |
| Same data as OPEN v7? | Yes. Tasks 1 to 3 are copied from OPEN v7 unchanged. |
| Where to look | Task 4 result: `ready`, `open_v7_would`, `problems`, `field_check` |
| PagerDuty | Task 5 shows the body with the routing key hidden |

## Summary

PREVIEW v7 prepares the data exactly like OPEN v7 and then stops. Task 4 tells you, per SILVA form field, whether the value is filled and in the right format, whether an incident is already open, and what OPEN v7 would do. Task 5 shows the PagerDuty body and checks its required fields.

## Tasks

| Task | What it does | Network |
|---|---|---|
| 1 extract-event-tags | Reads event, tags, environment, app code, host | Dynatrace problem API (read) |
| 2 resolve-snow-values | Finds group, business service, offering, host CI, company | SILVA GET |
| 3 build-payload | Builds SNOW body, PD body, decision | None |
| 4 preview-silva-incident | Field check, duplicate check, verdict | SILVA GET (duplicate check) |
| 5 preview-pagerduty | PD body and checks | None |

## Task 4 Field Check

| Form label | Key | Mandatory | Must be sys_id |
|---|---|---|---|
| Caller | caller_id | Yes | Yes |
| On Behalf Of | u_on_behalf_of | Yes | Yes |
| Contact type | contact_type | Yes | No |
| Company | company | Yes | Yes |
| Environment | u_environment | Yes | No |
| Business service | u_business_service | Yes | Yes |
| Service Offering | cmdb_ci | Yes | Yes |
| Configuration item | u_configuration_item | No | Yes |
| Category | category | Yes | No |
| Subcategory | subcategory | Yes | No |
| Impact | impact | Yes | No |
| Urgency | urgency | Yes | No |
| Assignment group | assignment_group | Yes | Yes |
| Short description | short_description | Yes | No |
| Summary | description | Yes | No |
| Correlation ID | correlation_id | Yes | No |

## Status Meanings

| Status | What it means |
|---|---|
| OK | Filled, and a sys_id where SILVA needs one |
| MISSING | Mandatory field is empty; OPEN v7 would create a poor ticket or skip |
| WRONG | Reference field holds a name instead of a sys_id (SILVA would ignore it) |
| EMPTY | Optional field is empty; fine |

## How To Read open_v7_would

| Value | Meaning |
|---|---|
| CREATE incident | OPEN v7 would POST this exact body |
| SKIP (maintenance is on) | Entity under maintenance |
| SKIP (missing: ...) | build-payload found empty required data |
| SKIP (sample event ...) | You pressed Run without a real problem |
| SKIP (already open: INC...) | Incident exists for this problem |

## Data Flow

```
problem → extract → resolve (GET SILVA) → build-payload
        → preview-silva-incident (GET duplicate) → field_check + verdict
        → preview-pagerduty → PD body (routing key hidden) + checks
        (no POST)
```

## Related Files

| File | What it is |
|---|---|
| `18-preview-v7-no-post.workflow.yaml` | This preview workflow |
| `../17-open-v7-silva-pagerduty/` | OPEN v7 that really sends |
| `../4-v7-test-extraction-validate/` | TEST v7 with deeper SILVA validation |
| `18.sh` | Copy commands |
