# All Alerts Combined Terraform

## Decision Tree

```
Want one Terraform file for every alert written today?
 use 38-all-alerts-combined-terraform.tf (replaces seq 37, which only had seq 27 to 36)
   any seq folder already applied?
     yes → state mv / import first, or Dynatrace gets duplicates
     no  → set TF_VAR_cdus_pagerduty_routing_key and TF_VAR_bre_pagerduty_routing_key
           → init → validate → plan → apply
   "Duplicate resource" error? → another .tf from a seq folder is in the same folder → remove it
   lookup error?               → upload /lookups/controlm/* and /lookups/jenkins/configuration
   seq 35 detector never fires? → check that arrayMovingMax line is present (fixed here)
```

## Short Takeaway

| Question | Answer |
|---|---|
| What is it? | One `.tf` with the latest version of every alert from seq 5 to 36 |
| Size | 4,473 lines, 51 resource blocks |
| Resource types | 24 detectors, 25 workflows, 2 log event rules (before for_each expansion) |
| Old versions left out | Seq 4 and 21 (Cisco, replaced by 22), seq 25 (OUD, replaced by 26), seq 30 (Control-M, replaced by 31), house-style `dynatrace_log_alert` files |
| Seq 35 check result | Two fixes applied in this file |
| Secrets | None. Two PagerDuty keys are sensitive variables passed at run time |
| Name clashes | None found for resources or locals |

## Summary

Seq 38 widens seq 37 from the Splunk migration only to every alert written today, keeping only the newest version of each. While checking seq 35, two issues showed up and are fixed in this file only: a placeholder Dynatrace does not support, and a 1-minute series that could stay too sparse to ever reach 5 violating minutes.

## Seq 35 Check

| Finding | Why it matters | Fix in seq 38 |
|---|---|---|
| `{violating_samples}` in `event.description` | Not a Dynatrace placeholder; would appear as literal text in the problem | Replaced with plain text "10-minute max response time" |
| `makeTimeseries ... interval:1m` with `violatingSamples = 5` | If the Jenkins HTTP Monitor job logs less than once a minute, most minutes are empty, and empty minutes do not count as violations. 5 of 10 might never happen | Added `fieldsAdd responsetime = arrayMovingMax(responsetime, 10)`, which carries the worst value of the last 10 minutes forward, like Splunk's 10-minute max |
| Query, analyzer, ABOVE, severity | Correct | No change |

Seq 34 and 36 were also checked: their `{dims:...}` placeholders are valid, and their settings match the Splunk logic.

## What Is Inside

| Part | Seq | Alert group | Main objects |
|---|---|---|---|
| 1 | 5 | Compass BigData Glue skip | Detector and log event rule |
| 1 | 6 | CCI AWS Batch timeout | Detector and log event rule |
| 1 | 7 | HPM CMX to SharePoint Lambda error | Detector |
| 1 | 8 | CS Digital Document Management | Detector and 2 workflows |
| 1 | 9 | Customer Process API | Detector and 2 workflows |
| 1 | 10 | Document Upload API (CDUS) | Detectors (for_each) and 2 workflows, PagerDuty variable |
| 1 | 11 | eOPT serverless | Detector and 2 workflows |
| 1 | 12 | Gov inquiry system | Notice workflows (for_each), detector and email workflow |
| 1 | 13 | HPM SharePoint API Lambda error | Daily workflow |
| 1 | 14 | HPM SurveyMonkey Lambda error | Detector and workflow |
| 1 | 15 | BRE InnoRules | Detector and PagerDuty workflow, PagerDuty variable |
| 1 | 16 | Emma MsgBox errors | Detector and workflow |
| 1 | 17 | Emma onboarding batch | Detectors (for_each) and workflow |
| 1 | 18 | PMT API | Detectors (for_each) and email workflows (for_each) |
| 1 | 19 | RecruitIMP serverless | Daily workflow, detector and workflow |
| 1 | 20 | SA support batches | Detectors (for_each) and 2 workflows |
| 2 | 22 | Cisco VPN LDAP | Detector and email workflow |
| 2 | 26 | OUD restart failed | Detector |
| 3 | 27 | OpenPaaS and ESG | 5 detectors |
| 3 | 28 | PowerCenter service down | 1 detector |
| 3 | 29 | Datalake batch result | 1 workflow |
| 3 | 31 | Control-M | 1 detector and 6 workflows |
| 3 | 32 | IWFM | 3 detectors |
| 3 | 34 | Jenkins Application Monitoring | 2 detectors |
| 3 | 35 | HTTP Response Check Outlier | 1 detector (fixed) |
| 3 | 36 | Broker Policy undefined error | 1 detector |

## Versions Left Out

| Left out | Replaced by | Why |
|---|---|---|
| Seq 4 Cisco VPN LDAP | Seq 22 | Seq 22 covers both Splunk alerts, written inline |
| Seq 21 Cisco main and house-style | Seq 22 | Same resource names; would clash |
| Seq 25 OUD main and house-style | Seq 26 | User asked for Terraform only, no workflow |
| Seq 30 Control-M | Seq 31 | Seq 31 is the corrected v2 |
| Seq 37 combined | Seq 38 | Seq 38 is a superset |

## Before Apply

| Step | What to do |
|---|---|
| 1 | Decide on state: one new stack, or keep the per-seq folders. Never both against the same tenant without moving state |
| 2 | Export `TF_VAR_cdus_pagerduty_routing_key` and `TF_VAR_bre_pagerduty_routing_key` from your secret store |
| 3 | Upload lookup files for Control-M and Jenkins |
| 4 | Work through the 24 CONFIRM lines (`rg -n CONFIRM`) |
| 5 | `terraform plan` and read the add count; for_each expands the 51 blocks into more objects |

## Data Flow

```
seq 5 … 20 (log_alert conversions) ┐
seq 22 (Cisco), seq 26 (OUD)       ┼─ joined, one provider block, seq 35 fixed ─→ 38 combined .tf
seq 27 … 36 (Splunk migration)     ┘
       → terraform plan (needs 2 PagerDuty variables)
       → detectors → problems → standard SILVA / PagerDuty flow
       → workflows → scheduled emails and PagerDuty events
```

## Investigation

| Checked | Evidence |
|---|---|
| All tf files under today's folder | 33 files from seq 4 to 37 |
| Duplicate resource addresses | `sort \| uniq -d` on resource lines returned nothing |
| Duplicate local names | Only duplicates were between seq 37 and its sources; seq 37 not included |
| Variables | Two sensitive PagerDuty keys with no default |
| terraform and provider blocks | Only seq 4 and 37 had one; both left out, one added at the top |
| Seq 35 | Placeholder and sparse-series issues found and fixed |

## Result

The single file `38-all-alerts-combined-terraform.tf` is ready for `terraform plan` once the variables, lookups and CONFIRM lines are handled.

## Related Files

| File | Purpose |
|---|---|
| `38-all-alerts-combined-terraform.tf` | The combined Terraform |
| `38.sh` | Commands |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Evidence |
| `2-result.md` | Next steps |
| `3-glossary.md` | Terms |

## Commands

See `38.sh`.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/38-all-alerts-combined-terraform"
export TF_VAR_cdus_pagerduty_routing_key="<from secret store>"
export TF_VAR_bre_pagerduty_routing_key="<from secret store>"
terraform init
terraform validate
terraform plan
```
