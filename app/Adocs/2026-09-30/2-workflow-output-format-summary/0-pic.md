# Output Format Picture

```
display-result output
 ├─ dynatrace_alert         what / where / how severe      (from Dynatrace)
 ├─ servicenow_enrichment   owning business service        (from SILVA)
 ├─ decision                create? group? environment?
 ├─ snow_incident_payload   → OPEN POST incident
 ├─ pagerduty_payload       → OPEN POST PagerDuty
 ├─ tags                    raw inputs
 └─ lookup                  every SILVA search, candidates
```

```
event ─► dynatrace_alert ─┐
tags  ─► SILVA search ─► servicenow_enrichment ─┤
                                                 ├─► decision ─► SNOW payload / PD payload
                          problem_id ─► correlation_id + dedup_key
```
