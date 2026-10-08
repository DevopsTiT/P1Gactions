# Control-M Job Update Information

## Decision tree

```
Screenshots
 Prod_Life_Emma_MyAXAUserRegistrationBatchStatus_Normal → repeat of seq 78, no change, apply from seq 78 only
 controlm_job_update_infomation (every 30 min, last 60 min)
   Current-version job definitions from def_ver_jobs and def_ver_lnki_p
   Group by job_id + table_id, add pre_job (from condition) and post_job (who waits on it)
   Drop jobs whose predecessor is YC-D-001-F, and jobs with no predecessor (Splunk where behavior)
   → one problem per changed definition (job_id + table_id + c_day_time), medium, PagerDuty "0"
 Rest of the Splunk search cut off? → send the bottom of the search box, then adjust the tf
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the Splunk alert do? | Every 30 minutes it mails a CSV of Control-M job definitions that were created or changed in the last hour. |
| Why does it matter? | Teams see who changed which job, its command line, and which jobs run before and after it. |
| Dynatrace version | A records detector. Each changed job definition opens one problem. |
| Resource | `controlm_job_update_information` |
| Severity | medium (priority Normal). Low is also fine for a change notice. |
| PagerDuty | "0" |
| Open point | The end of the Splunk search is not visible. |
| CHDR010M screenshot | Same as seq 78. No new tf. |

## Summary

This alert is a change report for Control-M job definitions. The Dynatrace detector rebuilds the same fields: the change date, the command line, the predecessor job from the `condition` field, and the successor jobs from a lookup over the same data, which replaces the Splunk `append`. One problem opens per changed definition, so a repeat run in the next 30 minutes does not open a second one.

## Investigation

| What I checked | What I found |
|---|---|
| Data | `controlm_def_ver_jobs` and `controlm_def_ver_lnki_p`, current version only |
| Change time | `change_date` and `change_time`, or the creation date and time for new jobs |
| CMDLINE | `cmd_line`, else `mem_lib\memname`, else `memname` |
| MONTH | `month_1` to `month_12` joined into one string |
| pre_job | Taken from `condition` with the pattern `L-<job>-OK` |
| Grouping | `stats ... by job_id table_id` |
| Exclusion | `where pre_job!="YC-D-001-F"` |
| append | Builds post_job: for each predecessor, the jobs that wait on it |
| Not visible | Everything after the append |
| Schedule | `*/30 * * * *`, last 60 minutes |
| Trigger | Results > 0, once, for each result, no throttle |
| Action | Email, priority Normal, link to results, CSV attached |

## Result

| Item | Value |
|---|---|
| Detector | Records detector over the last 60 minutes |
| Identity | `job_id`, `table_id`, `c_day_time`, so the same change is not reported twice |
| pre_job | DQL `parse condition, "'L-' LD:pre_job '-OK'"` |
| post_job | `lookup` over the same data, matched on predecessor name |
| Exclusion | Rows with no predecessor or with YC-D-001-F as predecessor are dropped |
| CSV attachment | Not available in Dynatrace. The problem carries the same fields. |

## Data flow map

```
Control-M definition export (def_ver_jobs, def_ver_lnki_p)
  → Grail logs (is_current_version = Y)
  → detector (last 60 min)
      build c_day_time, CMDLINE, MONTH, pre_job
      lookup successors (post_job)
      group by job_id + table_id
      drop no-predecessor and YC-D-001-F
  → one problem per changed definition (medium)
  → notification route → email list (not copied), PagerDuty off
```

## Related files

| File | What it is |
|---|---|
| `79-controlm-job-update-information-tf.tf` | The detector |
| `79-controlm-job-update-information-tf-check.dql` | Source names, field names, change volume per hour |
| `79-controlm-job-update-information-tf.spl` | The full Splunk search text (shows the cut-off part), fire history, volume |
| `78-emma-myaxa-user-registration-batch-tf/` | The CHDR010M answer (unchanged) |
| `79.sh` | Commands |

## Commands

These are in `79.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/79-controlm-job-update-information-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
