# Splunk Migration Combined Terraform

## Decision Tree

```
Want one Terraform file for every converted alert?
 use 37-splunk-migration-combined-terraform.tf
   already applied some seq folders separately?
     yes → do NOT apply this file in a new state; terraform import or state mv first,
           otherwise Dynatrace gets duplicate detectors and workflows
     no  → terraform init → validate → plan (expect 21 to add) → apply
   plan shows a duplicate resource name? → you also have a seq .tf in the same folder; remove it
   plan fails on a lookup? → upload /lookups/controlm/* and /lookups/jenkins/configuration first
```

## Short Takeaway

| Question | Answer |
|---|---|
| What is it? | One `.tf` file that contains every Splunk alert converted today |
| Which answers are inside? | Seq 27, 28, 29, 31, 32, 34, 35 and 36 |
| What is left out? | Seq 30, because seq 31 is its v2 and replaces it |
| How many objects? | 21: 14 detectors and 7 workflows |
| Secrets inside? | None. PagerDuty keys were never copied |
| What changed from the seq files? | Nothing in the resources; only one provider block and section headers were added |

## Summary

The combined file is the eight per-group Terraform files joined in order, with one `terraform` and `provider` block at the top. Resource names and local value names were checked and do not clash, so the file can be planned as one stack. All the CONFIRM notes from each group are still inside and still need checking before apply.

## What Is Inside

| Section | Source seq | Splunk group | Splunk alerts | Dynatrace objects |
|---|---|---|---|---|
| A | 27 | OpenPaaS and ESG | 7 | 5 detectors (`openpaas[*]`) |
| B | 28 | PowerCenter service down | 3 | 1 detector |
| C | 29 | Datalake batch result | 1 | 1 workflow (daily 08:00) |
| D | 31 | Control-M | 13 | 1 detector and 6 workflows |
| E | 32 | IWFM | 3 | 3 detectors (`iwfm[*]`) |
| F | 34 | Jenkins Application Monitoring | 10 | 2 detectors (`jenkins_app_monitoring[*]`) |
| G | 35 | HTTP Response Check Outlier | 1 | 1 detector (auto-adaptive) |
| H | 36 | Broker Policy undefined error | 1 | 1 detector |
| Total | | | 39 | 14 detectors and 7 workflows |

## Name Clash Check

| Item | Result |
|---|---|
| Resource addresses | All 17 resource blocks have unique names |
| Local values | `openpaas_alerts`, `cm_*`, `daily_reports`, `report_intro`, `iwfm_alerts`, `jenkins_*` are all different |
| Variables | None in these files |
| Provider blocks | Only one, at the top |

## Important: Existing State

| Situation | What to do |
|---|---|
| You have not applied any seq folder yet | Use only this file; plan should show 21 to add |
| You already applied some seq folders | Running this file in a new folder will create duplicates. Either keep using the seq folders, or move their state with `terraform state mv` / `terraform import` before applying |
| You want both files in one folder | Do not; Terraform will fail with "Duplicate resource" |

## Still To Confirm Before Apply

| Section | What to confirm |
|---|---|
| A, B, E, G, H | `log.source` or `k8s.namespace.name` guesses for each Splunk index |
| C | Recipient for the Datalake daily email |
| D | Control-M lookup files under `/lookups/controlm/` and the PDDW0100 recipients |
| F | `/lookups/jenkins/configuration` uploaded, and the macro definitions |
| G | Whether the 【TEST】 outlier alert should go live at all |
| H | Recipients for the Broker Policy alert |

## Data Flow

```
seq 27 .tf ┐
seq 28 .tf ┤
seq 29 .tf ┤
seq 31 .tf ┤  joined in order, one provider block on top
seq 32 .tf ┼──────────────────────────────────────────→ 37 combined .tf
seq 34 .tf ┤
seq 35 .tf ┤
seq 36 .tf ┘
                         → terraform plan → 14 detectors + 7 workflows
                         → Dynatrace problems → standard SILVA / PagerDuty flow
                         → scheduled workflows → email
```

## Investigation

| Checked | Evidence |
|---|---|
| Which tf files belong to the Splunk migration | Seq 27 to 36 (seq 33 had no tf) |
| Seq 30 versus 31 | Seq 31 is the v2 inventory of the same Control-M alerts |
| Resource names | Listed with a search for `^resource`; no duplicates |
| Local names | Listed per file; no duplicates |
| Secrets | Searched for key, secret and variable; none found |

## Result

| Step | What to do |
|---|---|
| 1 | Decide on state: new stack or keep per-seq folders |
| 2 | Upload the lookup files for sections D and F |
| 3 | Fix the CONFIRM lines using each seq's check.dql |
| 4 | `terraform plan` should show 21 to add |
| 5 | Apply, run in parallel with Splunk, then disable the Splunk alerts |

## Related Files

| File | Purpose |
|---|---|
| `37-splunk-migration-combined-terraform.tf` | Combined Terraform, 1,338 lines |
| `37.sh` | Commands |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Evidence |
| `2-result.md` | Next steps |
| `3-glossary.md` | Terms |

## Commands

See `37.sh`.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/37-splunk-migration-combined-terraform"
terraform init
terraform validate
terraform plan
```
