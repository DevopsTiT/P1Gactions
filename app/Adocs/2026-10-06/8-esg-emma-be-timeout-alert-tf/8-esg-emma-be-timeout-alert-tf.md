# ESG Emma BE Timeout Alert

## Decision Tree

```
Splunk: backend SocketTimeoutException + append API gateway "Problem routing to ... timed out", last 5 min, > 20 → email
 → Dynatrace Records detector: one filter with "or" for both sources → summarize count → filter count > 20
 check.dql query 1 → backend logs found under host myaxabackend-*?
   no → use the field query 1 shows (k8s.namespace.name or log.source) in the first filter
 check.dql query 4 → highest 5-minute count in 7 days
   always far below 20 → alert never fires → agree a lower threshold with the team
```

## Short Takeaway

| Question | Answer |
|---|---|
| What it watches | Timeouts on calls from Emma BE (OpenPaaS) to ESG (CoreIT) |
| Source 1 | myaxa backend logs with `java.net.SocketTimeoutException` to api-jp-cert.corp.intraxa |
| Source 2 | API gateway logs with "Problem routing to ... timed out" for myaxa-api.alj.intraxa |
| How Splunk `append` maps | One filter with `or`, then one combined count |
| Threshold | More than 20 in 5 minutes (`local.esg_timeout_threshold`) |
| Notification | Email only, severity high, `pagerduty.enabled = 0` |

## Summary

The Splunk search adds the results of two searches together with `append` and alerts when the total is more than 20 in 5 minutes. In Dynatrace, both conditions go into one `filter` joined by `or`. `summarize count()` counts the total, and `filter count > 20` returns a row only when the limit is crossed. The Records detector alerts on that row, and a fixed identity field keeps it to one open problem.

## Splunk To Dynatrace

| Splunk | Dynatrace |
|---|---|
| `index="myaxabackend-prod-axa-li-jp"` | `startsWith(host.name, "myaxabackend-")` |
| `api-jp-cert.corp.intraxa AND "java.net.SocketTimeoutException"` | Two `contains(content, ...)` checks |
| `append [search index="apigw_syslog" sourcetype=apigw_syslog_prod ...]` | `or (contains(log.source, "/SYSLOG/APIGW/prod/") and ...)` |
| `"Problem routing to" AND "timed out" AND "myaxa-api.alj.intraxa"` | Three `contains(content, ...)` checks |
| Last 5 minutes, cron */5 | `from:now()-5m`; the detector checks every minute |
| Results > 20 | `summarize count = count()` then `filter count > 20` |
| Throttle 60 seconds | Identity field `check`: one problem stays open, no repeats |
| Expires 24 hours | No equivalent |
| Email, priority High | `alert.severity high`, `pagerduty.enabled 0` (recipients not copied) |

## Query

```
fetch logs, from:now()-5m
| filter (startsWith(host.name, "myaxabackend-")
          and contains(content, "api-jp-cert.corp.intraxa")
          and contains(content, "java.net.SocketTimeoutException"))
      or (contains(log.source, "/SYSLOG/APIGW/prod/")
          and contains(content, "Problem routing to")
          and contains(content, "timed out")
          and contains(content, "myaxa-api.alj.intraxa"))
| summarize count = count()
| filter count > 20
| fieldsAdd check = "esg_emma_be_timeout"
```

## Data Flow

```
Emma BE (myaxabackend pods) → S3 log forwarder → Grail ─┐
API gateway EEAA2015 → /SYSLOG/APIGW/prod/local4.log ──┴→ every minute: timeouts in last 5 min
   count > 20 → 1 row → High problem → email through the standard flow (no page)
   count ≤ 20 → no row → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| Alert screenshot | Last 5 minutes, cron */5, > 20, throttle 60 seconds, email only, priority High |
| Search screenshot | 6 events in about 24 hours from host myaxabackend-*, source s3://axa-li-jp-logforwarders-prod/... |
| Sample error | BusinessCalendarServiceException: I/O error on GET to api-jp-cert.corp.intraxa/biz-calendar, Read timed out |
| Volume | 6 events per day is far below 20 per 5 minutes; this alert only catches big outages |
| Personal emails | Team mailing lists shown; not copied into Terraform |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1 to confirm how the backend logs are labelled in Dynatrace |
| 2 | Run queries 2 and 3; you should see the same lines Splunk shows |
| 3 | Run query 4 to see how often more than 20 happened in 7 days |
| 4 | `terraform plan` shows 1 to add |

## Related Files

| File | Purpose |
|---|---|
| `8-esg-emma-be-timeout-alert-tf.tf` | Detector Terraform |
| `8-esg-emma-be-timeout-alert-tf-check.dql` | Check queries |
| `8.sh` | Commands |
