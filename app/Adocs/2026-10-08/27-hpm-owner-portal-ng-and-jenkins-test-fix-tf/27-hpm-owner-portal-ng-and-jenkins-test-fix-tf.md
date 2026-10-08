# HPM Owner Portal NG And Jenkins Test Fix

## Decision tree

```
jenkins/test build_report on ceaa2099
  ABORTED or FAILURE? -> dropped
  App-Ops-OpenOps Functional job? -> not counted (Splunk empties its job_result)
  App-Ops-OpenOps Real Time Check? -> renamed to its Functional project, counted
  any other job (applications/<app>/prod/...) -> kept with its own name, counted
  configuration lookup -> application matches the alert?
    yes -> counted jobs: 2+ non-SUCCESS and 0 SUCCESS in the window?
             yes -> problem per job (high, PagerDuty on)
             next SUCCESS -> closes
Earlier seq 19 / 20 / 23 used "App-Ops-OpenOps only"?
  -> replace them with the fixed files here (same resource names, in-place update)
```

## Short takeaway

| Question | Answer |
|---|---|
| New alert | Prod_Life_HPM_Owner_Portal_RealTimeAndFunctionalCheck_NG, application "HPM_Owner_Portal". |
| Settings | Last 2 hours, cron every minute, PagerDuty Enable. |
| What did screenshot 4 reveal? | jenkins/test also holds plain jobs like `applications/seido-portal/prod/availability-check`. |
| Bug in seq 19, 20, 23 | They kept only App-Ops-OpenOps jobs, so plain application jobs were ignored. |
| Fix | Keep every jenkins/test job; only App-Ops Functional jobs are left out of the OK/NG count. |
| How to apply | All four detectors are in this folder; same resource names as before, so plan shows in-place updates. |

## Summary

The new HPM Owner Portal alert uses the same Splunk template as AG Portal NTTGW, Banca Portal and Compass PB. The raw search screenshot shows that most `jenkins/test` jobs are plain `applications/...` checks, not App-Ops-OpenOps jobs, and Splunk keeps them. The earlier detectors dropped those jobs, so they could miss real NG states. This folder has the HPM detector plus corrected versions of the other three.

## What the Splunk template really does

| Job kind | Example | What Splunk does | Counted for OK/NG? |
|---|---|---|---|
| App-Ops Functional | App-Ops-OpenOps/app-check-jobs/Functional/... | Empties job_result | No |
| App-Ops Real Time | App-Ops-OpenOps/app-check-group/Real Time Check/... | Renames to the Functional project name | Yes |
| Plain application job | applications/seido-portal/prod/availability-check | Keeps name and job_result | Yes |

## What changed in the query

| Part | Seq 19, 20, 23 | Fixed (this folder) |
|---|---|---|
| First content filter | `contains(content, "App-Ops-OpenOps")` | `contains(content, "build_report")` and no top-level `job_duration` |
| Jobs kept | Only App-Ops Real Time and Functional | Every jenkins/test job |
| Counted results | `is_realtime` only | `not is_functional` |
| Field names | rt_fails, rt_oks | fails, oks |

The `isNull(j[job_duration])` filter keeps jenkins/test events apart from jenkins_statistics events, which have a top-level job_duration. Check query 1 confirms this.

## Files in this folder

| File | Resource | Application | Window |
|---|---|---|---|
| `27-...-providers.tf` | provider block | none | none |
| `27-...-hpm-owner-portal.tf` | hpm_owner_portal_realtime_functional_ng | HPM_Owner_Portal | 2 hours |
| `27-...-ag-portal-nttgw.tf` | ag_portal_nttgw_realtime_functional_ng | AG Portal NTTGW | 30 minutes |
| `27-...-banca-portal.tf` | banca_portal_realtime_functional_ng | Banca Portal | 2 hours |
| `27-...-compass-pb.tf` | compass_pb_realtime_functional_ng | Compass AG | 2 hours |

All four: severity high, pagerduty "1".

## HPM query

```
fetch logs, from:now()-2h
| filter matchesValue(host.name, "ceaa2099*")
| filter contains(content, "build_report")
| parse content, "JSON:j"
| filter isNull(j[job_duration])
| fieldsAdd job_name, job_result
| filter isNotNull(job_name) and job_result != "ABORTED" and job_result != "FAILURE"
| fieldsAdd is_functional, project, name
| lookup /lookups/jenkins/configuration -> application
| filter cfg.application == "HPM_Owner_Portal"
| summarize fails = countIf(not is_functional and job_result != "SUCCESS"),
            oks = countIf(not is_functional and job_result == "SUCCESS"), ..., by:{ application, name }
| filter fails >= 2 and oks == 0
```

## Data flow

```
Jenkins jobs (App-Ops Real Time, App-Ops Functional, applications/*)
  -> build_report JSON on ceaa2099 (source jenkins/test) -> Grail
  -> 4 Records detectors (one per application)
       drop ABORTED/FAILURE, leave out App-Ops Functional, lookup application
  -> 2+ NG, 0 SUCCESS -> problem per job (high) -> PagerDuty + email
  -> next SUCCESS -> closes
```

## Investigation

| What I checked | What I found |
|---|---|
| HPM alert | Same template; `where application="HPM_Owner_Portal"`; cron */1; Last 2 hours; PagerDuty Enable. |
| Screenshot 4 | 165,649 jenkins/test events; jobs like applications/my-number-management/prod/functional-check and applications/seido-portal/prod/availability-check; event_tag build_report. |
| Splunk logic | No filter on App-Ops-OpenOps; plain jobs keep job_result and decide OK/NG. |
| Earlier detectors | Seq 19, 20, 23 filtered on "App-Ops-OpenOps" and counted only Real Time rows. |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1. jenkins/test lines should show `has_job_duration = false`. |
| 2 | Run query 2 to confirm configuration rows exist for all four applications. |
| 3 | Run query 3 to see the real job names per application. |
| 4 | Use this folder instead of seq 19, 20 and 23 folders. `terraform plan` from `27.sh`: 1 to add (HPM), 3 to update in place. |

## Related files

| File | What it is |
|---|---|
| `27-hpm-owner-portal-ng-and-jenkins-test-fix-tf-*.tf` | Provider plus four detectors |
| `27-hpm-owner-portal-ng-and-jenkins-test-fix-tf-check.dql` | Dynatrace checks |
| `27-hpm-owner-portal-ng-and-jenkins-test-fix-tf.spl` | Splunk checks |
| `27.sh` | Commands |
| `../19-...`, `../20-...`, `../23-...` | Earlier versions, now replaced |

## Commands

From `27.sh`:

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/27-hpm-owner-portal-ng-and-jenkins-test-fix-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
