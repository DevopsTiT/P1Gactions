# ServiceNow Priority From Impact And Urgency

```
Need a SNOW priority?
  → Do NOT set priority directly (SNOW recalculates it)
  → Set impact (1-3) + urgency (1-3)
  → SNOW looks up the matrix → priority
       1+1 → P1 Critical
       2+2 → P3 Moderate
       3+3 → P5 Planning (or P4 if your company trimmed the scale)
Priority looks wrong?
  → check impact/urgency sent → check company's custom matrix (SILVA may override)
```

## Short takeaway

| Question | Answer |
| --- | --- |
| What is impact? | How many people or how much business is hurt |
| What is urgency? | How fast it must be fixed before damage grows |
| What is priority? | The result SNOW calculates from impact and urgency |
| Can I send priority in the API? | Usually no effect; SNOW overwrites it from the matrix |
| P1 to P4 or P1 to P5? | Out of the box SNOW has 5 levels; many companies show only 4 |

## Summary

Priority is not typed in by hand. ServiceNow reads two inputs, impact and urgency, each from 1 (high) to 3 (low), and looks up the answer in a small table called the priority matrix. Our Dynatrace workflow sends impact and urgency; SNOW (or SILVA rules) turns them into the priority.

## Investigation

Checked the OPEN workflow `2026-09-24/1-silva-http-snow-pd-sync-workflows/1-open-silva-http-and-pagerduty.workflow.yaml` lines 91 to 102 and 167 to 168: it sends `impact` and `urgency`, never `priority`.

## Result

Map Dynatrace severity to impact and urgency, and let SNOW calculate priority. Confirm the real matrix with the SNOW / SILVA owners.

## 1) The two inputs

| Input | Question it answers | 1 (High) | 2 (Medium) | 3 (Low) |
| --- | --- | --- | --- | --- |
| Impact | How big is the damage? | Whole service or many customers | One team or some users | One user |
| Urgency | How fast must we act? | Right now, business stopped | Soon, workaround exists | Can wait |

## 2) Default priority matrix (ServiceNow out of the box)

| | Urgency 1 High | Urgency 2 Medium | Urgency 3 Low |
| --- | --- | --- | --- |
| **Impact 1 High** | P1 Critical | P2 High | P3 Moderate |
| **Impact 2 Medium** | P2 High | P3 Moderate | P4 Low |
| **Impact 3 Low** | P3 Moderate | P4 Low | P5 Planning |

Many companies remove P5 or merge it into P4, which is why I wrote "P1 to P4" earlier. The exact scale is your company's setting.

## 3) What each priority usually means

| Priority | Meaning | Typical response |
| --- | --- | --- |
| P1 Critical | Major outage | Page on-call now, bridge call, fix within hours |
| P2 High | Serious degradation | Page on-call, fix same day |
| P3 Moderate | Partial issue with workaround | Business hours |
| P4 Low | Minor issue | Queue |
| P5 Planning | Nice to fix | Backlog |

## 4) How our workflow maps Dynatrace severity

| Dynatrace severity | impact | urgency | Resulting priority (default matrix) | PagerDuty severity |
| --- | --- | --- | --- | --- |
| AVAILABILITY or CRITICAL | 1 | 1 | P1 Critical | critical |
| ERROR | 2 | 2 | P3 Moderate | error |
| Anything else (performance, resource, custom) | 3 | 3 | P5 Planning (or P4) | warning |

Note: ERROR landing on P3 may be lower than your team wants. If ERROR should be P2, send impact 1 and urgency 2 (or impact 2 and urgency 1).

## 5) Common mistakes

| Mistake | What happens | Fix |
| --- | --- | --- |
| Sending `priority: 1` only | SNOW recalculates and ignores it | Send impact and urgency |
| Sending numbers as labels ("High") | Field may reject or default to 3 | Send "1", "2", "3" |
| Assuming the default matrix | Company matrix may differ | Ask SNOW owners for the lookup table |
| SILVA rules override | Ticket priority differs from what you sent | Check SILVA mapping |

## Data flow map

```
Dynatrace problem severity
  → workflow maps → impact + urgency
  → HTTP → SILVA → SNOW incident
  → SNOW priority lookup (impact x urgency)
  → priority P1..P5 → drives SLA timers and assignment
```

## Related files

| File | Role |
| --- | --- |
| `2026-09-27/1-servicenow-explained/` | ServiceNow overview |
| `2026-09-24/1-silva-http-snow-pd-sync-workflows/1-open-silva-http-and-pagerduty.workflow.yaml` | Severity mapping lines 91 to 102 |
| `2.sh` | Query to check priority on a real ticket |

## Commands

See `2.sh`.
