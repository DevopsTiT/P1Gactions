# Workflow Task And API Picture

## Decision Tree

```
Davis problem
 ├─ CREATED + ACTIVE → OPEN
 │   1 extract-event-tags  ──(Problems API, optional)
 │   2 resolve-snow-values ──(SILVA GET: group, service, offering)
 │   3 display-result      ──(no API) → decision yes/no
 │   4 post-silva-incident ──(SILVA GET duplicate, POST incident)
 │   5 trigger-pagerduty   ──(PagerDuty POST trigger)
 └─ CLOSED / RESOLVED → CLOSE
     1 prepare-close       ──(Problems API, optional)
     ├─ 2 resolve-silva-incident ──(SILVA GET, PATCH state 6)
     └─ 3 resolve-pagerduty      ──(PagerDuty POST resolve)
```

## What Each Task Hands To The Next

```
OPEN
 task 1 ─ snow_inputs ──────────────► task 2
 task 1 ─ dynatrace_alert, tags ────► task 3
 task 2 ─ snow_required ────────────► task 3
 task 3 ─ snow_incident, decision ──► task 4
 task 3 ─ pagerduty, decision ──────► task 5
 task 4 ─ action, number, url ──────► task 5
CLOSE
 task 1 ─ correlationId, notes ─────► task 2
 task 1 ─ dedupKey ─────────────────► task 3
```

## Shared Keys

```
display_id ──► SILVA correlation_id        (OPEN writes, CLOSE searches)
display_id ──► PD dedup_key dt-problem-<id> (OPEN triggers, CLOSE resolves)
```
