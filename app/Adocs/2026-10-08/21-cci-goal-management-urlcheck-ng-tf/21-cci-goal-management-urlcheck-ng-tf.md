# CCI Goal Management URL Check NG TF

## Decision tree

```
Jenkins URL check job with "Management" in job_name (ceaa2099, jenkins/test)
  job_result ABORTED? -> dropped
  response code 200 in the last 30 minutes?
    yes -> OK (an open problem closes)
    no, and 2+ non-200 runs -> problem per application + name (high, PagerDuty off)
Never fires or fires too often?
  -> query 1: is the response code key really "status"?
  -> query 3: run interval; widen or shrink the 30-minute window
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it watch? | The Jenkins URL check for CCI Goal Management. |
| When is it NG? | The last 2 runs both returned something other than HTTP 200. |
| Dynatrace rule | 2 or more non-200 responses and 0 responses of 200 in 30 minutes. |
| Identity | `application` and `name`. |
| Severity | high (same as the other Alert Status Manager Jenkins alerts). |
| PagerDuty | "0", because PagerDuty Notification is Disable. |
| Recovery mail | Not needed; the problem closes on the next 200. |

## Summary

Splunk looks at the last 2 runs of every Jenkins job whose name contains "Management" and calls it NG when neither returned 200. Dynatrace cannot pick "the last 2 runs" directly, so the detector uses a short window: 2 or more non-200 results and no 200 in 30 minutes. Check the job's run interval with query 3 and adjust the window if needed.

## Splunk to Dynatrace mapping

| Splunk piece | What it means | Dynatrace |
|---|---|---|
| `index="jenkins" source="jenkins/test"` | Jenkins build reports | `matchesValue(host.name, "ceaa2099*")`, `parse content, "JSON:j"` |
| `job_name="*Management*"` | The Goal Management jobs | `contains(job_name, "Management")` |
| `job_result!=ABORTED` | Drop aborted builds | Same filter |
| `name` cleanup | Remove `job/`, `%20` and build number | `replaceString` and trailing `/` removal |
| `rename status as responsecode` | HTTP response code of the URL check | `responsecode = toString(j[status])` |
| `lookup configuration` | Adds application | `lookup /lookups/jenkins/configuration`, default "-" |
| `streamstats ... where index<=2` | Last 2 runs per job | 2 or more results in a 30-minute window |
| `status = OK if Response_Code="200"` | Any 200 in those runs means OK | `oks == 0` for NG |
| `search status="NG" OR (OK and prev NG)` | NG mail or recovery mail | Problem opens on NG, closes on 200 |
| Last 24 hours, cron */1 | Wide lookback, runs every minute | `from:now()-30m`; detector runs every minute |
| Add to Triggered Alerts | Shows in the Splunk Triggered Alerts list | Dynatrace Problems list does the same job |
| Alert Status Manager, PagerDuty Disable | Email only | `pagerduty.enabled = "0"`. Recipients and PagerDuty URL not copied. |

## Terraform

Full file: `21-cci-goal-management-urlcheck-ng-tf.tf`. Query:

```
fetch logs, from:now()-30m
| filter matchesValue(host.name, "ceaa2099*")
| filter contains(content, "Management")
| parse content, "JSON:j"
| fieldsAdd job_name, job_result, responsecode = toString(j[status])
| filter contains(job_name, "Management")
| filter job_result != "ABORTED"
| fieldsAdd name (cleaned job name)
| lookup /lookups/jenkins/configuration -> application
| summarize fails, oks, Response_Code, last_seen, by:{ application, name }
| filter fails >= 2 and oks == 0
| fieldsAdd type = "URL"
```

## Data flow

```
Jenkins URL check job (CCI Goal Management)
  -> build_report JSON on ceaa2099 (status = HTTP code) -> Grail
  -> Records detector (every minute, last 30 min) + configuration lookup
  -> 2+ non-200, no 200 -> problem (high, app CCI Goal Management, pagerduty 0)
  -> workflow -> email
  -> next 200 -> problem closes
```

## Investigation

| What I checked | What I found |
|---|---|
| Base search | jenkins/test, not ABORTED, job_name contains "Management". |
| Response code | The JSON `status` field, renamed to responsecode. |
| OK rule | `Response_Code="200"` on a multivalue field is true if any value is 200. |
| Last runs | streamstats keeps the last 2 runs per name. |
| Schedule | cron */1, Last 24 hours. |
| Actions | Add to Triggered Alerts; Alert Status Manager, Production, PagerDuty Disable. |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1. Confirm `status` holds the HTTP code; if the key differs, change `j[status]`. |
| 2 | Run query 2 to get the application name from configuration. |
| 3 | Run query 3. If the job runs less than every 10 minutes, widen the window to about 2 run intervals. |
| 4 | `terraform plan` and `terraform apply` from `21.sh`. |

## Related files

| File | What it is |
|---|---|
| `21-cci-goal-management-urlcheck-ng-tf.tf` | The detector |
| `21-cci-goal-management-urlcheck-ng-tf-check.dql` | Dynatrace checks |
| `21-cci-goal-management-urlcheck-ng-tf.spl` | Splunk checks |
| `21.sh` | Commands |
| `../11-jenkins-url-monitor-host-filter-tf/` | Generic Jenkins URL monitor using the same idea |

## Commands

From `21.sh`:

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/21-cci-goal-management-urlcheck-ng-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
