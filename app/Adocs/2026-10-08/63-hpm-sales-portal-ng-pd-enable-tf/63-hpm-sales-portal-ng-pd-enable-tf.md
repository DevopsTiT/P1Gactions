# HPM Sales Portal PagerDuty Enable

## Decision tree

```
Prod_Life_HPM_Sales_Portal_RealTimeAndFunctionalCheck_NG (shown again, actions now visible)
 search same as seq 29? → yes (jenkins/test template, application="HPM_Sales_Portal", 2h, */1)
 actions? → Alert Status Manager, Production, PagerDuty Enable
 seq 29 pagerduty? → "0" (actions were cut off then)
 → change pagerduty.enabled to "1"; nothing else changes
 → same resource name hpm_sales_portal_realtime_functional_ng → in-place update, apply from ONE folder (63)
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a new alert? | No. It is the same alert as seq 29. |
| What changed? | The actions are now visible: Alert Status Manager, Production, PagerDuty Enable. |
| What changed in the tf? | `pagerduty.enabled` goes from "0" to "1". The query is unchanged. |
| Which folder to apply? | Seq 63. Don't apply seq 29 after it, or PagerDuty goes back to "0". |
| Severity | high |

## Summary

Seq 29 had to guess the PagerDuty setting because the screenshot ended at Trigger Actions. These screenshots show PagerDuty Enable, so the detector now routes to PagerDuty. Everything else stays the same: one problem per job when the counted jobs have 2 or more non-SUCCESS results in 2 hours with no SUCCESS.

## Investigation

| What I checked | What I found |
|---|---|
| Base search | `index="jenkins" source="jenkins/test" job_result!=ABORTED job_result!=FAILURE`. Same as seq 29. |
| Application | `where application="HPM_Sales_Portal"`. Same. |
| Last line | `search event=2 OR (status="OK" AND prev_status="NG")`. Same. |
| Schedule | `*/1`, last 2 hours, expires 24 hours, once, for each result, no throttle. |
| Action | Alert Status Manager, Production email. I did not copy the recipients. |
| PagerDuty | Enable. A URL was visible, and I did not copy it. |

## Result

| Setting | Seq 29 | Seq 63 |
|---|---|---|
| Resource | `hpm_sales_portal_realtime_functional_ng` | same |
| Query | jenkins/test template, 2 hours | unchanged |
| Severity | high | high |
| pagerduty.enabled | "0" | "1" |

## Data flow map

```
Jenkins (ceaa2099) build_report JSON (source jenkins/test)
  → drop ABORTED / FAILURE, drop statistics events
  → App-Ops Real Time Check renamed to Functional project; Functional runs not judged
  → lookup configuration → application == "HPM_Sales_Portal"
  → per application+name in 2h: fails >= 2 and oks == 0
  → problem (high, pagerduty 1) → PagerDuty → closes on SUCCESS
```

## Related files

| File | What it is |
|---|---|
| `63-hpm-sales-portal-ng-pd-enable-tf.tf` | Detector with pagerduty "1" |
| `63-hpm-sales-portal-ng-pd-enable-tf-check.dql` | jenkins/test shape, HPM_Sales_Portal lookup rows |
| `63-hpm-sales-portal-ng-pd-enable-tf.spl` | Lookup rows, saved search actions |
| `63.sh` | Commands |

## Commands

These are in `63.sh`. Nothing has been run. Apply from this folder only.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/63-hpm-sales-portal-ng-pd-enable-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
