# CompassPB Confirm and PagerDuty Fix

## Decision tree

```
Prod_Life_CompassPB_RealTimeAndFunctionalCheck_NG (shown again)
 seen before? → yes: seq 23, fixed in seq 27
 search same as seq 27? → yes (jenkins/test, application="Compass AG", OKメンテナンス中 remark, 2h, */1)
 → no change: reuse seq 27 compass-pb tf (pagerduty "1", PagerDuty Enable seen in seq 23/27)

While checking: AG Portal NTTGW (seq 52) and Banca Portal (seq 53)
 same alerts as seq 19 / 20, fixed in seq 27? → yes, same resource names
 seq 52/53 pagerduty? → "0" (actions not visible then)
 seq 27 pagerduty? → "1" (PagerDuty Enable seen earlier)
 → do NOT apply seq 52 or 53; apply seq 27 or this seq 56 folder instead
```

## Short takeaway

| Question | Answer |
|---|---|
| Is CompassPB new? | No. It was done in seq 23 and fixed in seq 27. |
| Anything changed in CompassPB? | No. The tf is the seq 27 version, unchanged. |
| What else did I find? | Seq 52 (AG Portal NTTGW) and seq 53 (Banca Portal) repeat seq 19/20 and 27, but with `pagerduty.enabled = "0"`. |
| Why that matters | Same resource names, so applying seq 52 or 53 would switch PagerDuty off for those two alerts. |
| What to apply | This folder (seq 56), which has all three detectors with the seq 27 settings. Do not apply seq 52 or 53. |

## Summary

CompassPB is unchanged from seq 27. While checking it, I found that the AG Portal NTTGW and Banca Portal answers from earlier this hour (seq 52 and 53) duplicate detectors already fixed in seq 27. They set PagerDuty to "0" only because the trigger actions were cut off in those screenshots. Seq 27 had seen PagerDuty Enable for them. This folder gathers the three seq 27 detectors so you can apply them from one place.

## Investigation

### CompassPB screenshots compared with seq 27

| What I checked | What I found |
|---|---|
| Base search | `index="jenkins" source="jenkins/test" job_result!=ABORTED job_result!=FAILURE`. Same. |
| `rex ... OKメンテナンス中` | Kept as `remarks` in the seq 27 tf. |
| Application | `where application="Compass AG"`. Same. |
| Last line | `search event=2 OR (status="OK" AND prev_status="NG")`. Same. |
| Schedule | Last 2 hours, `*/1`. Same. |
| Actions | Not visible this time. Seq 23 saw PagerDuty Enable, so `pagerduty.enabled` stays "1". |

### Seq 52 and 53 compared with seq 27

| Alert | Seq 27 | Seq 52 or 53 | Difference |
|---|---|---|---|
| AG Portal NTTGW | 30 minutes, pagerduty "1" | 30 minutes, pagerduty "0" | PagerDuty only |
| Banca Portal | 2 hours, pagerduty "1" | 2 hours, pagerduty "0" | PagerDuty only |

The query logic is identical. Only the PagerDuty flag differs.

## Result

| Detector | Resource | Window | pagerduty.enabled |
|---|---|---|---|
| CompassPB | `compass_pb_realtime_functional_ng` | 2 hours | "1" |
| AG Portal NTTGW | `ag_portal_nttgw_realtime_functional_ng` | 30 minutes | "1" |
| Banca Portal | `banca_portal_realtime_functional_ng` | 2 hours | "1" |

All three are severity high and open a problem when `fails >= 2 and oks == 0`.

### How to apply

| Do | Don't |
|---|---|
| Apply this folder (seq 56), or seq 27 | Apply seq 52 or seq 53 |
| Use one folder per resource | Apply the same resource from two folders |

To double-check PagerDuty, run Splunk query 1 in the `.spl` file. It lists the actions for all three alerts.

### Also found: CCI Goal Management (seq 21 and seq 54)

| Point | What it means |
|---|---|
| Seq 21 resource | `cci_goal_management_urlcheck_ng` |
| Seq 54 resource | `cci_goal_management_url_check_ng`. The name is different, so applying both creates two detectors with the same title. |
| Seq 21 logic | It reads `j[status]`, which build_report events don't have. `fails` stays 0, so it never fires. |
| What to keep | Seq 54 (job_result based, ships disabled). |
| If seq 21 was already applied | Remove it from the seq 21 folder with the targeted destroy in `56.sh`, then apply seq 54. |

## Data flow map

```
Jenkins (ceaa2099) build_report JSON (source jenkins/test)
  → drop ABORTED / FAILURE, drop statistics events (job_duration)
  → App-Ops Real Time Check renamed to Functional project; Functional runs not judged
  → name cleanup (job/, %20, trailing /), remark OKメンテナンス中 (CompassPB)
  → lookup configuration → application (Compass AG | AG Portal NTTGW | Banca Portal)
  → per application+name: fails >= 2 and oks == 0 (2h / 30m / 2h)
  → problem (high, pagerduty 1) → closes on SUCCESS
```

## Related files

| File | What it is |
|---|---|
| `56-compass-pb-confirm-and-pd-fix-providers.tf` | Provider block |
| `56-compass-pb-confirm-and-pd-fix-compass-pb.tf` | CompassPB, copy of seq 27 |
| `56-compass-pb-confirm-and-pd-fix-ag-portal-nttgw.tf` | AG Portal NTTGW, copy of seq 27 (replaces seq 52) |
| `56-compass-pb-confirm-and-pd-fix-banca-portal.tf` | Banca Portal, copy of seq 27 (replaces seq 53) |
| `56-compass-pb-confirm-and-pd-fix-check.dql` | Lookup rows and Compass AG runs |
| `56-compass-pb-confirm-and-pd-fix.spl` | Saved search actions and lookup pager_duty |
| `56.sh` | Commands |

## Commands

These are in `56.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/56-compass-pb-confirm-and-pd-fix"
terraform init
terraform validate
terraform plan
terraform apply
```
