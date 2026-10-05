# Seq 35 Batch Combined Terraform

## Decision Tree

```
Which Jenkins screenshot batches do you want to apply?
 only the seq 35 batch        → batch-35/40-seq35-batch-combined-terraform.tf          (3 detectors)
 seq 34 + 35 + 36 together    → all-34-35-36/40-seq35-batch-combined-terraform-seq34-35-36-all.tf (4 detectors)
 never put two of these files in the same folder → "Duplicate resource" (jenkins_app_monitoring)
 already applied seq 34, 35, 36 or 39? → move state first, or keep that folder
```

## Short Takeaway

| Question | Answer |
|---|---|
| Was seq 35 duplicated? | Yes. URL, URL for MyAXA and function in the seq 35 screenshots are the same alerts as seq 34 |
| What is new in seq 35? | Only HTTP Response Check Outlier |
| File 1 | `batch-35/...tf`: the seq 35 batch, 3 detectors |
| File 2 | `all-34-35-36/...tf`: all three Jenkins batches with duplicates removed, 4 detectors |
| Seq 35 fixes included? | Yes, both fixes from seq 38 |
| Why two subfolders? | Both files contain `jenkins_app_monitoring`; Terraform reads every `.tf` in a folder, so they must be apart |

## Summary

The seq 35 screenshots repeated three seq 34 alerts and added one new one, the response-time outlier. File 1 covers just that batch. File 2 is the cleaner choice: it covers every Jenkins screenshot batch (seq 34, 35 and 36) with each alert defined once, giving 4 detectors for 12 unique Splunk alerts.

## File 1: Seq 35 Batch

| Splunk alert | Dynatrace detector |
|---|---|
| Application Monitoring Alert - URL | `jenkins_app_monitoring["jenkins_url_check_failed"]` |
| Application Monitoring Alert - URL for MyAXA | `jenkins_app_monitoring["jenkins_url_check_failed"]` |
| Application Monitoring Alert - function | `jenkins_app_monitoring["jenkins_functional_check_failed"]` |
| HTTP Response Check Outlier 【TEST】 | `jenkins_aggw_lb_response_outlier` |

## File 2: Seq 34 + 35 + 36, Duplicates Removed

| Batch | Alerts in the screenshots | New in that batch | Detector |
|---|---|---|---|
| Seq 34 | 10 Application Monitoring alerts | All 10 | `jenkins_app_monitoring` (2 detectors) |
| Seq 35 | URL, URL for MyAXA, function | None (repeats) | Same as seq 34 |
| Seq 35 | HTTP Response Check Outlier | Yes | `jenkins_aggw_lb_response_outlier` |
| Seq 36 | 7 Application Monitoring alerts | None (repeats) | Same as seq 34 |
| Seq 36 | Broker Policy undefined error | Yes | `broker_policy_undefined_error` |
| Total | 12 unique Splunk alerts | | 4 detectors |

## Seq 35 Fixes Included

| Fix | What it means |
|---|---|
| Removed `{violating_samples}` | Dynatrace does not fill this placeholder, so it would show as raw text |
| Added `arrayMovingMax(responsetime, 10)` | Keeps the worst value of the last 10 minutes, so sparse Jenkins runs can still reach 5 violating minutes |

## Which File Replaces What

| If you apply | Do not also apply |
|---|---|
| `all-34-35-36` file | Seq 34, 35, 36, 39, and `batch-35` |
| `batch-35` file | Seq 34, 35, 39 (they share detectors) |
| Seq 38 (everything today) | Any of the above; seq 38 already contains them all |

## Data Flow

```
Jenkins console [HTTP Monitor] → URL detector             ┐
Jenkins console AGGW LB timing → Outlier detector (fixed) ┤
Jenkins test results           → Functional detector      ┼→ problems → standard SILVA / PagerDuty flow
Broker OCP pod logs            → Broker detector (file 2) ┘
```

## Investigation

| Checked | Evidence |
|---|---|
| Seq 35 screenshot alerts | URL, URL for MyAXA, function, HTTP Response Check Outlier |
| Seq 34 coverage | First three already in `jenkins_app_monitoring` |
| Seq 36 coverage | Seven repeats of seq 34, plus Broker |
| Resource names | `jenkins_app_monitoring`, `jenkins_aggw_lb_response_outlier`, `broker_policy_undefined_error` |
| Fixes | `arrayMovingMax` present; `{violating_samples}` gone from code |

## Result

| Step | What to do |
|---|---|
| 1 | Pick one: file 2 (recommended), file 1, or seq 38 |
| 2 | Upload `/lookups/jenkins/configuration` |
| 3 | Run the three check.dql files and fix CONFIRM lines |
| 4 | `terraform plan` in that subfolder: 3 to add (file 1) or 4 to add (file 2) |

## Related Files

| File | Purpose |
|---|---|
| `batch-35/40-seq35-batch-combined-terraform.tf` | Seq 35 batch, 3 detectors |
| `all-34-35-36/40-seq35-batch-combined-terraform-seq34-35-36-all.tf` | All Jenkins batches, 4 detectors |
| `40-seq35-batch-combined-terraform-jenkins-check.dql` | Jenkins checks (copy of seq 34) |
| `40-seq35-batch-combined-terraform-outlier-check.dql` | Outlier checks (copy of seq 35) |
| `40-seq35-batch-combined-terraform-broker-check.dql` | Broker checks (copy of seq 36) |
| `40.sh` | Commands |

## Commands

See `40.sh`.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/40-seq35-batch-combined-terraform/all-34-35-36"
terraform init
terraform validate
terraform plan
```
