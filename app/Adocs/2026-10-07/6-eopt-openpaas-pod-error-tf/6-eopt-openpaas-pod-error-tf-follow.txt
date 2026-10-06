# eopt OpenPaaS Pod Error Alert

## Decision Tree

```
Splunk: index eopt-prod-axa-li-jp, level right after timestamp = ERROR, hourly, > 0 → email
 → Dynatrace Records detector: "Z ERROR " in eopt pod logs → one medium problem → email
 check.dql query 3 → loglevel already parsed?
   yes → use loglevel == "ERROR" instead of the text match
 check.dql query 4 → only the 09:30 import job errors every day?
   yes → expected noise → agree with the team: exclude it or keep a daily email
```

## Short Takeaway

| Question | Answer |
|---|---|
| What it watches | ERROR-level lines from eopt backend pods on OpenPaaS |
| How Splunk finds the level | `rex` reads the word right after the ISO timestamp, then `level="ERROR"` |
| Dynatrace match | `contains(content, "Z ERROR ", caseSensitive:false)` in pods starting with `eopt` |
| Real events | 11 ERROR lines at 09:30 JST from PropertyDetailImportServiceImpl (daily import job) |
| Notification | Email only, priority Normal: severity medium, `pagerduty.enabled = "0"` |
| Change from Splunk | One problem instead of one email per line (Splunk "For each result" sent 11) |

## Summary

The Splunk search pulls the log level from the start of each line and keeps lines where it is ERROR. It runs hourly and emails once per matching line. In Dynatrace, the level always follows the timestamp's closing `Z`, so `"Z ERROR "` finds the same lines. A fixed identity field groups them into one problem. The only errors seen are from a scheduled import job reporting missing values, so confirm with the team that these should alert.

## Splunk To Dynatrace

| Splunk | Dynatrace |
|---|---|
| `index="eopt-prod-axa-li-jp"` | `startsWith(host.name, "eopt")` (pod names like eoptsystemapi-...) |
| `rex "^(?<timestamp>...Z)\s+(?<level>[A-Z]+)"` | Level is the word after `Z ` at the start of the line |
| `eval level=upper(level)` | `caseSensitive:false` |
| `search level="ERROR"` | `contains(content, "Z ERROR ", ...)` |
| Run every hour at :00 | Checks every minute and looks back 2 hours |
| Results > 0 | Any row raises an alert |
| For each result | One problem (`alertIdentityFields[0] = check`) |
| Expires 24 hours | No equivalent |
| Email, priority Normal | `alert.severity medium`, `pagerduty.enabled 0` |

## About The Rex

| Part | What it means |
|---|---|
| `^` | Start of the line |
| `\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z` | ISO timestamp such as 2026-10-06T00:30:06.693Z |
| `\s+` | One or more spaces |
| `(?<level>[A-Z]+)` | The level word, such as INFO or ERROR |

## Query

```
fetch logs
| filter startsWith(host.name, "eopt")
| filter contains(content, "Z ERROR ", caseSensitive:false)
| fieldsAdd check = "eopt_backend_error"
```

## Data Flow

```
eopt pods (eoptsystemapi-*) → S3 log forwarder → Grail
  → every minute: any "Z ERROR " line in the last 2 hours?
      yes → one medium problem (eopt) → email through the standard flow
      no rows → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| Alert screenshot | Run every hour at 0 minutes past, > 0, Once, For each result, email priority Normal |
| Search screenshot | 11 events on 10/6 at 09:30 JST, host eoptsystemapi-564c45bd9f-nj8q4 |
| Error text | PropertyDetailImportServiceImpl: "18 error records were found" and "Since the value does not exist, we set it to null : GL_ACCOUNT:..." |
| Pattern | Scheduled job (scheduling-1), probably daily: likely expected data issues, not an outage |
| Recipients | Team list plus one personal address; not copied |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1 to confirm the eopt pod host names in Dynatrace |
| 2 | Run query 3; if loglevel is parsed, switch to `loglevel == "ERROR"` |
| 3 | Run query 4 and agree with the team whether the 09:30 import errors should alert |
| 4 | `terraform plan` shows 1 to add |

## Related Files

| File | Purpose |
|---|---|
| `6-eopt-openpaas-pod-error-tf.tf` | Detector Terraform |
| `6-eopt-openpaas-pod-error-tf-check.dql` | Check queries |
| `6.sh` | Commands |
