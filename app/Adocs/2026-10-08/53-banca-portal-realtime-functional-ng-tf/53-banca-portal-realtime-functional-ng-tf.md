# Banca Portal Check NG

## Decision tree

```
Prod_Life_BancaPortal_RealTimeAndFunctionalCheck_NG
 template? → jenkins/test (same as seq 29 HPM_Sales_Portal, seq 52 AG Portal NTTGW)
 data alive? → yes (seq 52: 168,553 events since 10/1)
 application? → "Banca Portal" (check exact spelling in lookup, check.dql 1)
 window? → Last 2 hours, cron */1 → from:now()-2h
 trigger actions visible? → no → pagerduty "0", severity high (CONFIRM)
   PagerDuty Enable → "1"
 → detector: per application+name, fails >= 2 and oks == 0 (FAILURE/ABORTED excluded like Splunk)
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it watch? | Banca Portal Jenkins checks (Real Time and Functional) in `index=jenkins source=jenkins/test`. |
| When does it open a problem? | When a counted job has 2 or more non-SUCCESS results in 2 hours and no SUCCESS. |
| Resource | `banca_portal_realtime_functional_ng` |
| Severity and PagerDuty | high and "0", both to confirm because the actions were not visible |

## Summary

This is the same `jenkins/test` template as seq 29 and 52. Only the application name ("Banca Portal") changes, and the window is the same as seq 29: 2 hours, cron `*/1`. Before applying, check the exact application spelling in the lookup and the trigger actions.

## Investigation

| What I checked | What I found |
|---|---|
| Search | Same steps as seq 29 and 52, with `where application="Banca Portal"`. |
| Results excluded | ABORTED and FAILURE, so NG only comes from results like UNSTABLE. |
| Last line | `search event=2 OR (status="OK" AND prev_status="NG")`, which mails when 2 runs failed and on recovery. |
| Schedule | `*/1`, last 2 hours, expires 24 hours, once, for each result, no throttle. |
| Actions | Not visible. The screenshot ends at Trigger Actions. |

## Result

| Setting | Value |
|---|---|
| Resource | `banca_portal_realtime_functional_ng` |
| Window | `from:now()-2h` |
| Filter | `cfg.application == "Banca Portal"` |
| Opens when | `fails >= 2 and oks == 0` |
| Identity | application, name |
| Severity | high (CONFIRM) |
| pagerduty.enabled | "0" (set it to "1" if PagerDuty is Enable) |

## Data flow map

```
Jenkins (ceaa2099) build_report JSON (source jenkins/test)
  → drop ABORTED / FAILURE, drop statistics events (job_duration)
  → App-Ops Real Time Check renamed to Functional project; Functional runs not judged
  → name cleanup (job/, %20, trailing /)
  → lookup /lookups/jenkins/configuration → application == "Banca Portal"
  → per application+name in 2h: fails >= 2 and oks == 0
  → problem (high, pagerduty 0) → closes on SUCCESS
```

## Related files

| File | What it is |
|---|---|
| `53-banca-portal-realtime-functional-ng-tf.tf` | Detector |
| `53-banca-portal-realtime-functional-ng-tf-check.dql` | Lookup rows, runs and results per job |
| `53-banca-portal-realtime-functional-ng-tf.spl` | Lookup, saved search actions, scheduler history |
| `53.sh` | Commands |

## Commands

These are in `53.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/53-banca-portal-realtime-functional-ng-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
