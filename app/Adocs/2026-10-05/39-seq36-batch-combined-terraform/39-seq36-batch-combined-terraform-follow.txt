# Seq 36 Batch Combined Terraform

## Decision Tree

```
22 screenshots from seq 36 → want one .tf for all of them
 use 39-seq36-batch-combined-terraform.tf
   seq 34 or seq 36 already applied on their own?
     yes → do not apply this too; move state first or keep the old folders
     no  → upload /lookups/jenkins/configuration → init → validate → plan (3 to add) → apply
   Jenkins detector finds no data? → fix log.source with jenkins-check.dql 1 to 3
   Broker detector finds no data?  → fix namespace filter with broker-check.dql 1
```

## Short Takeaway

| Question | Answer |
|---|---|
| What is it? | One `.tf` that covers every alert in the 22 screenshots from seq 36 |
| Splunk alerts covered | 8: 1 Broker Policy alert and 7 Application Monitoring alerts |
| Dynatrace objects | 3 detectors, no workflows |
| Changes to the logic | None; it joins seq 34 (Jenkins) and seq 36 (Broker) |
| Secrets | None; PagerDuty keys from the screenshots were not copied |

## Summary

The seven Application Monitoring alerts in this batch are all handled by the two seq 34 Jenkins detectors, which split their problems by application. The Broker Policy alert is the seq 36 detector. This file puts the three detectors together with one provider block so the whole batch can be planned and applied as one unit.

## Alert to Detector Map

| Splunk alert | Application filter in Splunk | Dynatrace detector |
|---|---|---|
| ALJ Broker Policy Maintenance: Cannot read properties of undefined | Not applicable | `broker_policy_undefined_error` |
| Application Monitoring Alert - URL | All URL checks | `jenkins_app_monitoring["jenkins_url_check_failed"]` |
| Application Monitoring Alert - URL for MyAXA | All URL checks, paging version | `jenkins_app_monitoring["jenkins_url_check_failed"]` |
| Application Monitoring Alert - function | Apps with pager_duty 0 | `jenkins_app_monitoring["jenkins_functional_check_failed"]` |
| function for AG Portal | AG Portal NTTGW | `jenkins_app_monitoring["jenkins_functional_check_failed"]` |
| function for BancaPotal | Banca Portal | `jenkins_app_monitoring["jenkins_functional_check_failed"]` |
| function for Compass | Compass | `jenkins_app_monitoring["jenkins_functional_check_failed"]` |
| function for Compass PB | Compass AG | `jenkins_app_monitoring["jenkins_functional_check_failed"]` |

## The Three Detectors

| Detector title | Fires when | Severity |
|---|---|---|
| `Prod_Jenkins_AppMonitoring_URLCheckFailed_High` | An HTTP Monitor check fails twice with no OK in 15 minutes | high |
| `Prod_Jenkins_AppMonitoring_FunctionalCheckFailed_High` | A functional test fails twice with no PASSED in 2 hours | high |
| `Prod_BrokerPolicyMaintenance_UndefinedPropertyError_Normal` | More than 50 "Cannot read properties of undefined" errors in a minute | medium |

## Small Differences From Splunk

| Splunk behavior | Dynatrace behavior | Why it is acceptable |
|---|---|---|
| "URL" emails on a single NG; "URL for MyAXA" pages after two | One detector: two failures with no OK | One rule avoids two alerts for the same outage |
| Recovery email when OK follows NG | Problem closes on the first OK run | The standard flow sends the close notice |
| Broker: up to 15 emails for a 5-minute burst | One problem per burst | No more email storms |

## Data Flow

```
Jenkins console logs ([HTTP Monitor])  → URL detector        ┐
Jenkins test results (jenkins/test)    → Functional detector ┼→ problems (app.name, pagerduty.enabled)
Broker OCP pod logs                     → Broker detector     ┘     → standard SILVA / PagerDuty flow
Lookup /lookups/jenkins/configuration → adds application and pager_duty to the Jenkins detectors
```

## Investigation

| Checked | Evidence |
|---|---|
| Alert names in the 22 screenshots | 8 distinct alerts |
| Seq 34 tf versus screenshots | Same searches, windows (15 minutes and 2 hours) and application filters |
| Seq 36 tf | Matches the Broker search and threshold |
| Name clashes | `jenkins_app_monitoring` and `broker_policy_undefined_error` are different; one locals block |

## Result

| Step | What to do |
|---|---|
| 1 | Upload `/lookups/jenkins/configuration` |
| 2 | Run the two check.dql files and fix the CONFIRM lines |
| 3 | `terraform plan` should show 3 to add |
| 4 | Run alongside Splunk, then disable the 8 Splunk alerts |

## Related Files

| File | Purpose |
|---|---|
| `39-seq36-batch-combined-terraform.tf` | Combined Terraform, 3 detectors |
| `39-seq36-batch-combined-terraform-jenkins-check.dql` | Jenkins check queries (copy of seq 34) |
| `39-seq36-batch-combined-terraform-broker-check.dql` | Broker check queries (copy of seq 36) |
| `39.sh` | Commands |

## Commands

See `39.sh`.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/39-seq36-batch-combined-terraform"
terraform init
terraform validate
terraform plan
```
