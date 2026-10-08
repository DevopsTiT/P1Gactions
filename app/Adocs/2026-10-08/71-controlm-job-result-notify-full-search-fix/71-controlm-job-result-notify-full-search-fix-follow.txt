# Control-M Job Result Notify Fix

## Decision tree

```
CTL-M:ジョブ実行結果通知 (full search now visible)
 compare with seq 13 line by line
   addresslist lookup key      → JobID as job_name   (seq 13: job_name)        → FIX
   PrimarySupport fallback     → "N/A"               (seq 13: literal 対応方法)  → FIX
   job_Definition lookup       → CMD_STRING, node_id (seq 13: missing)         → ADD
   SpecificContact Email (CC)  → per-job contact     (seq 13: not shown)       → ADD as field
   everything else             → same
 same resource controlm_job_result_notify → in-place update → apply from seq 71 only
 対応方法 field not in any visible OUTPUT → mapped to Method → CONFIRM in Splunk
```

## Short takeaway

| Question | Answer |
|---|---|
| Is this a new alert? | No. It is seq 13, now with the whole search visible. |
| What changed? | Four fixes to the lookups and the title text. The trigger logic is the same. |
| Severity | medium, because the email priority is Normal. |
| PagerDuty | "0". The only action is email. |
| Which folder to apply? | Seq 71. Applying seq 13 afterwards would undo the fixes. |

## Summary

The alert fires when a Control-M job that abended in the last 24 hours ends again, either OK (正常終了) or not OK (異常終了). Seq 13 got the core right but guessed the lookup details. With the full search visible, the address-list key, the "N/A" fallback, the job definition command line and the per-job contact are now correct.

## Investigation

| Splunk line | Seq 13 | Seq 71 |
|---|---|---|
| `lookup controlm_addresslist.csv JobID as job_name OUTPUT Method` | `lookupField:job_name` | `lookupField:JobID` |
| `lookup controlm_job_Definition.csv job_name OUTPUT mem_lib, cmd_line, memname, node_id, host` | Missing | Added with prefix `def.` so `host` does not clash |
| `lookup controlm_SpecificContact.csv job_name OUTPUT Email` | Missing | Added as `contact.Email` |
| `CMD_STRING = if(isnull(mem_lib), cmd_line, mem_lib."\\".memname)` | Missing | Added |
| `PrimarySupport = ... case('対応方法'="", "N/A", true(), '対応方法')` | Fell back to the text "対応方法" | Falls back to "N/A" |
| TITLE and BODY | Correct | Unchanged |
| Throttle on `$result.JOB_CODE$` for 10 minutes | Per-run identity | Unchanged |
| Email CC `$result.Email$` | Not possible in a detector | Still not possible. The address is shown on the problem so a workflow can use it. |

Open point: the search uses a field called `対応方法`, but the only visible lookup output for it is `Method`. I mapped `対応方法` to `Method`. The SPL file has a query to check whether Splunk has a field alias.

## Result

| Setting | Value |
|---|---|
| Resource | `controlm_job_result_notify` (same as seq 13) |
| Identity | `UID` = order_id + isn, so one problem per run |
| Fires when | A job abended in the last 24 hours, and it ended again in the last 10 minutes |
| New fields on the problem | `CMD_STRING`, `def.node_id`, `def.host`, `contact.Email` |
| Severity | medium |
| PagerDuty | "0" |

Lookups to upload to Grail before apply:

| Lookup path | Columns |
|---|---|
| `/lookups/controlm/addresslist` | `JobID`, `Method` |
| `/lookups/controlm/job_definition` | `job_name`, `mem_lib`, `cmd_line`, `memname`, `node_id`, `host` |
| `/lookups/controlm/specific_contact` | `job_name`, `Email` |

## Data flow map

```
controlm_activejobs (ended in last 10 min, OK or not OK, not *-F / *-S)
  → dedup by order_id + isn
  → join controlm_alert (abended in last 24 h) → keep only abended jobs
  → addresslist (JobID) → Method → PrimarySupport ("N/A" if empty)
  → job_definition → CMD_STRING, node_id, host
  → specific_contact → Email
  → TITLE / BODY (Japanese, same as Splunk)
  → problem per run (medium) → email route (CC per job needs a workflow reading contact.Email)
```

## Related files

| File | What it is |
|---|---|
| `71-controlm-job-result-notify-full-search-fix.tf` | Corrected detector |
| `71-controlm-job-result-notify-full-search-fix-check.dql` | Source, field, lookup and coverage checks |
| `71-controlm-job-result-notify-full-search-fix.spl` | Splunk lookup contents and the 対応方法 alias check |
| `71.sh` | Commands |

## Commands

These are in `71.sh`. Nothing has been run. Apply from seq 71 only.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/71-controlm-job-result-notify-full-search-fix"
terraform init
terraform validate
terraform plan
terraform apply
```
