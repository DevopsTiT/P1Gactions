# Dynatrace S2 CLOSE Problem SILVA and PagerDuty

> **Audience:** SRE / platform who need to understand the Dynatrace workflow that resolves SILVA incidents and PagerDuty alerts when a Davis problem closes.

> **Safety:** Sends for real when active. Use Draft or `DRY_RUN = true` until values are confirmed. No secrets in Confluence. Pair with S0 OPEN (same `correlation_id` / `dedup_key`). Do not run two CLOSE workflows for the same scope. Drafts are not triggered.

---

## Decision tree

```
Dynatrace problem CLOSED?
  → prepare-close (problem id, correlation_id, dedup_key, times, cause)
      ├─► close-silva-incident
      │     open SILVA by correlation_id? NO → skip
      │     YES → valid state/close_code? NO → fail with allowed values
      │           YES → PATCH each → Resolved
      └─► close-pagerduty (parallel)
            POST resolve with same dedup_key OPEN used
```

---

## Short takeaway

| Question | Answer |
| --- | --- |
| What is it? | On problem **close**: resolve SILVA + resolve PagerDuty |
| UI title | **S2 - CLOSE Problem direct to SILVA and PagerDuty v5** |
| Tasks | prepare-close → close-silva ∥ close-pagerduty |
| Preview? | **No** (direct). OPEN S0 still uses preview-then-post |
| Keys | `correlation_id` = problem id; `dedup_key` = `dt-problem-<id>` |

---

## Summary

When a Davis problem closes, this workflow prepares close keys, then in parallel PATCHes open SILVA incidents (by correlation id) to Resolved and sends a PagerDuty resolve with the same dedup key OPEN used. Short “direct” CLOSE design—use once close_code/state are trusted.

---

## How S2 fits with S0 (OPEN)

```
S0 OPEN:  Active → create SILVA + PD trigger
S2 CLOSE: Closed → PATCH SILVA Resolved + PD resolve
Shared:   correlation_id + dedup_key = dt-problem-<id>
```

---

## End-to-end picture

```
Problem trigger (closed)
  → prepare-close
      ├─ close-silva-incident: GET open → PATCH Resolved
      └─ close-pagerduty: POST /v2/enqueue event_action=resolve
```

---

## Task catalog

| # | Task | Network | What it does |
| --- | --- | --- | --- |
| 0 | Problem trigger | DT events | On closed problem |
| 1 | prepare-close | Optional Problems API | ids, times, duration, cause |
| 2a | close-silva-incident | SILVA GET + PATCH | Find by correlation_id; resolve |
| 2b | close-pagerduty | PD POST | resolve with same dedup_key |

---

## API calls

### prepare-close

- Optional Dynatrace Problems API v2 for start/end/cause.
- Outputs: `correlation_id`, `dedup_key = dt-problem-<id>`, notes fields.

### close-silva-incident

```
GET  {SILVA}/api/now/v2/table/incident?sysparm_query=correlation_id=<id>^active=true...
GET  {SILVA}/api/now/v2/table/sys_choice   (state / close_code)
PATCH {SILVA}/api/now/v2/table/incident/{sys_id}
  body: state, close_code, close_notes, work_notes/comments
```

### close-pagerduty

```
POST https://events.pagerduty.com/v2/enqueue
{ "routing_key": "<secret>", "event_action": "resolve", "dedup_key": "dt-problem-<id>" }
```

---

## Settings

| Setting | Meaning |
| --- | --- |
| RESOLVED_STATE | Target SILVA state |
| CLOSE_CODE | Must match SILVA choice list |
| NOTES_FIELD | work_notes vs comments |
| EXTRA_FIELDS | Extra mandatory resolve fields |
| DRY_RUN | true = no send |
| ALLOW_SAMPLE_POST | Allow manual Run on sample id |

---

## Operator checklist

1. Same keys as S0 OPEN  
2. Confirm CLOSE_CODE in SILVA  
3. Allowlist SILVA + events.pagerduty.com  
4. DRY_RUN / sample test first  
5. Deploy; disable other CLOSE workflows  
6. Test close → SILVA Resolved + PD resolved  

---

## Document control

| Field | Value |
| --- | --- |
| Source | Screenshot S2 CLOSE v5 + seq 39 close-direct |
| Secrets | None |
