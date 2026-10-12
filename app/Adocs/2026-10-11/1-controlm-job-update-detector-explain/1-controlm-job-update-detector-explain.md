# Control-M Job Update Detector Explained

## Decision tree

```
Someone changed a Control-M job definition
 Is it the live version (is_current_version = Y)?   no → ignore
 Was it created or changed in the last 60 minutes?  no → ignore
 Does it have a predecessor job (L-xxx-OK)?          no → ignore (same as Splunk)
 Is the predecessor YC-D-001-F?                      yes → ignore
 Already reported this exact change (same job_id, table_id, c_day_time)? yes → no new problem
 → open one Dynatrace problem with who, what, command, before-jobs, after-jobs
```

## Short takeaway

| Question | Answer |
|---|---|
| What is it? | A "change notice" for Control-M batch job settings. |
| What triggers it? | A job definition being created or edited in the last hour. |
| What does a problem tell you? | Which job changed, who changed it, its command, and which jobs run before and after it. |
| Is it an outage alert? | No. It is an audit and awareness alert. Nothing is broken yet. |
| Why keep it? | A wrong edit to a batch job can break the next night's run. This gives people a chance to check it first. |
| Severity | medium, PagerDuty off |

## Summary

Control-M is the scheduler that runs the nightly batch jobs. Each job has a saved setup, called a definition. The Splunk alert mails a CSV every 30 minutes listing definitions that changed. The Dynatrace detector does the same job, but opens one problem per changed definition instead of mailing a spreadsheet.

## Investigation

### Step 1: What the data is

Control-M exports its job definitions into two log sources.

| Source | What it holds |
|---|---|
| `controlm_def_ver_jobs` | Job definition versions |
| `controlm_def_ver_lnki_p` | A second definition table with the same kind of fields |

Each definition is stored with every version. `is_current_version = Y` marks the live one, so the detector reads only those.

### Step 2: Building readable fields

| Field | How it is built | Why |
|---|---|---|
| `c_day_time` | The change date and time; for a brand-new job, the creation date and time | One value that says "when this version appeared" |
| `change_date` | `20261008` and `143005` turned into `2026/10/08 14:30:05` | Easier to read in the problem |
| `CMDLINE` | The command line. If it is empty, the script library and file name instead | Shows what the job actually runs |
| `MONTH` | The twelve month flags joined into one string | Shows which months the job runs in |

### Step 3: Finding the job before (pre_job)

A Control-M job waits for a condition such as `L-JOBA-OK`, which means "start after JOBA ends OK". The detector cuts out the middle part:

```
condition = L-JOBA-OK   →   pre_job = JOBA
```

### Step 4: Finding the jobs after (post_job)

This is the reverse question: which jobs wait for this one? The Splunk search answers it with an `append`, a second search glued under the first. The detector uses a `lookup` instead:

```
For every definition: read its condition → predecessor name
Group by predecessor → list of jobs that wait for it
Match that list back on job_name → post_job
```

Example:

| job_name | condition | Result |
|---|---|---|
| JOBB | L-JOBA-OK | JOBB's pre_job is JOBA |
| JOBC | L-JOBA-OK | JOBC's pre_job is JOBA |
| JOBA | (changed) | JOBA's post_job is JOBB and JOBC |

So if JOBA is edited, you immediately see that JOBB and JOBC could be affected.

### Step 5: One row per job

Splunk uses `stats ... by job_id table_id`. The detector uses `summarize ... by:{ job_id, table_id }`. Both squeeze all versions and conditions of a job into one row, with lists for fields that have several values.

### Step 6: Filters at the end

| Filter | What it does | Why |
|---|---|---|
| Predecessor is YC-D-001-F | Row is dropped | The Splunk owner excluded that chain, probably because it changes often or is noise |
| No predecessor at all | Row is dropped | Splunk `where pre_job!=...` silently drops empty values, so the detector copies that behavior |

### Step 7: Not reporting the same change twice

Splunk runs every 30 minutes but looks back 60 minutes, so every change appears in two runs. The detector solves this with identity fields:

| Identity field | Meaning |
|---|---|
| `job_id` | Which job |
| `table_id` | Which folder or table it lives in |
| `c_day_time` | Which change |

Same three values means the same problem, so it is not opened again. A new edit to the same job has a new `c_day_time`, so it opens a new problem.

## Result

| Splunk | Dynatrace | Difference |
|---|---|---|
| Email every 30 minutes with a CSV | One problem per changed job | Easier to track; each change can be acknowledged |
| `append` subsearch | `lookup` subquery | Same answer, different technique |
| CSV attachment | Fields on the problem | No attachment in Dynatrace |
| Same change in two mails | One problem | Identity fields remove duplicates |

### What is still open

| Item | Why it matters |
|---|---|
| The end of the Splunk search is cut off | There may be one more filter or join that the detector does not have yet |
| Field names in Grail | The detector assumes the same names as in Splunk |
| A condition with several jobs | `parse` reads only the first `L-xxx-OK` |
| Noise | Check query 3 in seq 79 shows how many changes happen per hour. On a busy release day this could open many problems. |

### Common mistakes

| Mistake | What happens | How to avoid |
|---|---|---|
| Forgetting `is_current_version = Y` | Old versions show up as changes | Keep that filter |
| Using only `job_id` as identity | The second edit of the same job never alerts | Keep `c_day_time` in the identity |
| Treating it as an outage | People get paged for normal releases | Keep PagerDuty "0" |

## Data flow map

```
Engineer edits a job in Control-M
  → definition export (def_ver_jobs, def_ver_lnki_p)
  → Dynatrace Grail logs
  → detector runs every minute over the last 60 minutes
      keep live versions
      build c_day_time, CMDLINE, MONTH
      pre_job from condition, post_job from lookup
      one row per job_id + table_id
      drop no-predecessor and YC-D-001-F
  → new job_id + table_id + c_day_time? → open problem (medium)
  → notification route → email list, no PagerDuty
```

## Related files

| File | What it is |
|---|---|
| `2026-10-08/79-controlm-job-update-information-tf/79-controlm-job-update-information-tf.tf` | The detector being explained |
| `2026-10-08/79-controlm-job-update-information-tf/79-controlm-job-update-information-tf-check.dql` | Checks to run before applying |
| `3-glossary.md` | Terms used here |
| `1.sh` | Commands |

## Commands

These are in `1.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/79-controlm-job-update-information-tf"
terraform init
terraform validate
terraform plan
```
