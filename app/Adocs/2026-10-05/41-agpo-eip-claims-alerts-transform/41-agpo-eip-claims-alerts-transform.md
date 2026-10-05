# AGPO EIP Claims Alerts Transform

## Decision Tree

```
3 new Splunk alerts
 AGPO-Auth0-Password-SyncError
   count in 5 min > 1 → static detector, 5-minute rolling sum, threshold 1, pages
 ALERT-EIP-MQ-CONN-TIMEOUT
   any line in 1 min  → static detector, threshold 0, email only
 Auto-Assessment API Error - !PRODUCTION!
   any ERROR in 10 min → static detector, threshold 0, high, email only
 Detector shows no data?
   run check.dql 1 to 3 → fix namespace, pod or host filter
```

## Short Takeaway

| Question | Answer |
|---|---|
| How many new alerts? | 3, none seen before today |
| Dynatrace shape | 3 static-threshold detectors in one `for_each`, no workflows |
| Which one pages? | Only AGPO (Splunk used PagerDuty); the key was not copied |
| Biggest Splunk problem | Auto-Assessment uses "For each result" on raw lines, so 30 error lines meant 30 emails |
| Includes provider block? | Yes, the file runs on its own |

## Summary

All three are "count matching log lines and alert above a number" rules, so detectors fit. AGPO needs a 5-minute rolling count because Splunk's rule is "more than 1 in 5 minutes". The EIP and Claims alerts fire on any matching line. Dynatrace opens one problem per incident instead of one email per line.

## What Each Splunk Alert Does

| Alert | Search (plain words) | Schedule and trigger | Action |
|---|---|---|---|
| AGPO-Auth0-Password-SyncError | AGPO authorization API logged an Auth0 password change BadRequest or NotFound response | Every 5 minutes over 5 minutes, more than 1 result | PagerDuty |
| ALERT-EIP-MQ-CONN-TIMEOUT | MQ hosts wpalja21b* logged "Connection timed out" | Every minute over 1 minute, more than 0 | Email to infra MWSS list, Normal |
| Auto-Assessment API Error | Claims auto-assessment API logged "] ERROR " lines, ignoring the stacktrace notice | Every 10 minutes over 10 minutes, more than 0, for each result | Email to two claims lists, High |

## Dynatrace Detectors

| Detector title | Query idea | Threshold | Window | Closes after | Severity | Pages? |
|---|---|---|---|---|---|---|
| `Prod_AGPO_Auth0PasswordSyncError_High` | Rolling 5-minute count of the two Auth0 errors | Above 1 | 5 | 5 quiet minutes | high | Yes |
| `Prod_EIP_MQConnectionTimeout_Normal` | Per-minute count of "Connection timed out" on wpalja21b* | Above 0 | 5 | 5 quiet minutes | medium | No |
| `Prod_Claims_AutoAssessmentAPIError_High` | Per-minute count of ERROR lines | Above 0 | 10 | 10 quiet minutes | high | No |

AGPO query:

```
fetch logs
| filter k8s.namespace.name == "agportalapi-prod-axa-li-jp"
| filter startsWith(k8s.pod.name, "agpo-cloud-authorization-process-api-")
| filter contains(content, "IamCChangePasswordBadRequestResponse")
      or contains(content, "IamCChangePasswordNotFoundResponse")
| makeTimeseries count = count(default: 0), interval:1m
| fieldsAdd count = arrayMovingSum(count, 5)
```

## Splunk Problems Found

| Alert | Problem | What Dynatrace does instead |
|---|---|---|
| AGPO | Throttle of 5 seconds does nothing on a 5-minute schedule | One problem stays open until 5 quiet minutes |
| AGPO | Description says "send email to PO" but the only action is PagerDuty | Pages through the standard flow; confirm whether the PO also needs email |
| AGPO | PagerDuty key typed into the alert | Routing comes from the standard flow; no key in Terraform |
| EIP MQ | Runs every minute with no throttle, so a 10-minute outage sends 10 emails | One problem per outage |
| Auto-Assessment | "For each result" on a raw-line table sends one email per error line | One problem; use check.dql query 5 to see the lines |
| Auto-Assessment | Name says !PRODUCTION! but index is a wildcard `claimsda*` | Filter is by pod or host name; confirm it only matches production |

## Data Flow

```
AGPO auth API pods  → Auth0 error lines     → rolling 5-min count > 1 → problem (high, pages)
MQ hosts wpalja21b* → "Connection timed out" → count > 0               → problem (medium, email)
Claims auto-assess  → "] ERROR " lines       → count > 0               → problem (high, email)
                                     → standard SILVA / PagerDuty flow (app.name, pagerduty.enabled)
```

## Investigation

| Checked | Evidence |
|---|---|
| Earlier answers today | None of the 3 alert names appear in seq 4 to 40 |
| AGPO sourcetype | `agportalapi-prod-axa-li-jp` matches the OCP namespace naming pattern |
| EIP MQ host | `wpalja21b*.prprivmgmt.intraxa` is a VM host name, so `host.name` |
| Claims host | `claims-auto-assessment-api*` looks like a pod name; both pod and host are checked |
| Secrets | PagerDuty key visible in the AGPO screenshot; not copied |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql queries 1 to 3 and fix the filters marked CONFIRM |
| 2 | Run query 4 to see how often AGPO would have paged |
| 3 | Ask the AGPO product owner whether they also need email |
| 4 | `terraform plan` should show 3 to add |
| 5 | Run alongside Splunk, then disable the 3 Splunk alerts |

## Related Files

| File | Purpose |
|---|---|
| `41-agpo-eip-claims-alerts-transform.tf` | Terraform, 3 detectors |
| `41-agpo-eip-claims-alerts-transform-check.dql` | 5 check queries |
| `41.sh` | Commands |

## Commands

See `41.sh`.

```
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/41-agpo-eip-claims-alerts-transform"
terraform init
terraform validate
terraform plan
```
