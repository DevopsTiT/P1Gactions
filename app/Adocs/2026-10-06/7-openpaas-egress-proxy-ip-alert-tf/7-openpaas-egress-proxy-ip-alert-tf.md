# OpenPaaS Egress Proxy IP Alert

## Decision Tree

```
Splunk: /maam/ lines with 52.76.125.86 OR 54.179.120.88, last 15 min, count <= 0 → email
 → Dynatrace Records detector: summarize count → filter count == 0 → row returned → alert
 check.dql query 1 → API gateway logs in Dynatrace?
   no → ingest /SYSLOG/APIGW/prod/local4.log first (otherwise the alert fires forever)
   yes → query 3 → do both IPs normally appear every 15 minutes?
     quiet periods at night → expect false alerts → widen to 30 or 60 minutes
```

## Short Takeaway

| Question | Answer |
|---|---|
| What it watches | API gateway traffic for /maam/ going out through two egress proxy public IPs |
| When it fires | Neither 52.76.125.86 nor 54.179.120.88 is seen for 15 minutes |
| Why it matters | Only one egress IP is left in use, so there is less capacity and no redundancy |
| Dynatrace type | Records detector with `summarize` and `filter count == 0` |
| Notification | Email only in Splunk, so `pagerduty.enabled = 0`, severity high |

## Summary

This is an "absence" alert: it fires when expected traffic stops. Splunk counts matching lines over 15 minutes and alerts when the count is 0. In Dynatrace, `summarize count()` always returns one row, even when there are no lines, so `filter count == 0` keeps that row only when traffic is missing. A Records detector alerts on that row. A fixed `check` field keeps it to one open problem instead of a new one every minute.

## Splunk To Dynatrace

| Splunk | Dynatrace |
|---|---|
| `index=apigw_syslog sourcetype=apigw_syslog_prod` | `contains(log.source, "/SYSLOG/APIGW/prod/")` |
| `/maam/*` | `contains(content, "/maam/")` |
| `*52.76.125.86* OR *54.179.120.88*` | `contains(content, ...) or contains(content, ...)` |
| `stats count` | `summarize count = count()` |
| `where count <= 0` | `filter count == 0` |
| Last 15 minutes, cron */15 | `from:now()-15m`; the detector checks every minute |
| Results > 0 | Records detector: any returned row alerts |
| Expires 24 hours | No equivalent |
| Email, priority High | `alert.severity high`, `pagerduty.enabled 0` (recipients not copied) |

## Query

```
fetch logs, from:now()-15m
| filter contains(log.source, "/SYSLOG/APIGW/prod/")
| filter contains(content, "/maam/")
| filter contains(content, "52.76.125.86") or contains(content, "54.179.120.88")
| summarize count = count()
| filter count == 0
| fieldsAdd check = "egress_proxy_public_ip"
```

## Data Flow

```
API gateway EEAA2015 → /SYSLOG/APIGW/prod/local4.log → Grail
  → every minute: count /maam/ lines with the two egress IPs in the last 15 minutes
      count > 0 → no row → no alert (or the open problem closes)
      count = 0 → 1 row → High problem → email through the standard flow (no page)
```

## Investigation

| Checked | Finding |
|---|---|
| Alert screenshot | Last 15 minutes, cron */15, count <= 0, email only, priority High |
| Description | Alert when only one public IP is found on ESG and the other two egress proxy IPs are missing |
| Search screenshot | 1.5M events, host EEAA2015.ppprivmgmt.intraxa, source /SYSLOG/APIGW/prod/local4.log |
| Splunk precedence | OR binds before the implicit AND: /maam/ AND (IP1 OR IP2) |
| Personal emails | Not copied into Terraform |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1. If the APIGW logs are missing, the alert fires all the time. |
| 2 | Run query 3 to see if the IPs appear in every 15-minute bucket |
| 3 | `terraform plan` shows 1 to add |
| 4 | Route the email to the team mailbox in the standard flow |

## Related Files

| File | Purpose |
|---|---|
| `7-openpaas-egress-proxy-ip-alert-tf.tf` | Detector Terraform |
| `7-openpaas-egress-proxy-ip-alert-tf-check.dql` | Check queries |
| `7.sh` | Commands |
