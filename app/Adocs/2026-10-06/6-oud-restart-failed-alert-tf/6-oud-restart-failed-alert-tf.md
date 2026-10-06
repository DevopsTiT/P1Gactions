# OUD Restart Failed Alert

## Decision Tree

```
Splunk: index=ods sourcetype=oud_service failed, last 24h, daily 04:01, > 0, High, PagerDuty
 → Dynatrace Records detector (each "failed" row = alert)
 check.dql query 1 → which log.source is oud_service?
   one service file → put its exact path in the filter
   only access/error logs → "failed" may match normal LDAP bind failures → narrow the filter
 query 3 shows many "failed" lines per day → too noisy → match the restart message only
```

## Short Takeaway

| Question | Answer |
|---|---|
| What it watches | The OUD (Oracle Unified Directory) service log reporting "failed" |
| Host | WPALJA2162.prprivmgmt.intraxa |
| Log path | Under `/opt/oracle/oud/asinst_1/OUD/logs/` |
| Dynatrace type | Records detector, so no makeTimeseries |
| Severity | High, pages through the standard flow |
| Timing | Splunk checked once a day; Dynatrace checks every minute |

## Summary

The Splunk alert searches the OUD service log once a day for the word "failed" over the last 24 hours, and pages if it finds even one line. The Dynatrace Records detector raises an alert for any matching row, which covers "more than 0". It runs every minute, so a failed restart pages within minutes instead of the next morning.

## Splunk To Dynatrace

| Splunk setting | Dynatrace |
|---|---|
| `index=ods` | `host.name` WPALJA2162 (the only host in index ods) |
| `sourcetype=oud_service` | `log.source` under `/opt/oracle/oud/` (confirm the exact file) |
| `failed` | `contains(content, "failed", caseSensitive:false)`; Splunk terms are case-insensitive |
| Last 24 hours, cron 04:01 daily | Runs every minute and looks back 2 hours |
| Results > 0 | Any row raises an alert |
| Expires 24 hours | No equivalent; the problem history stays in Dynatrace |
| For each result | `alertIdentityFields[0] = host.name`: one problem per host |
| High, PagerDuty, email | `alert.severity high`, `pagerduty.enabled 1` |

## Query

```
fetch logs
| filter matchesValue(host.name, "WPALJA2162*") and contains(log.source, "/opt/oracle/oud/")
| filter contains(content, "failed", caseSensitive:false)
```

## Data Flow

```
OUD on WPALJA2162 → /opt/oracle/oud/asinst_1/OUD/logs/* → OneAgent → Grail
  → every minute: any "failed" line in the last 2 hours?
      yes → High problem (OUD) → standard SILVA / PagerDuty flow
      no rows → problem closes
```

## Investigation

| Checked | Finding |
|---|---|
| Alert screenshot | Last 24 hours, cron read as "1 4 * * *", expires 24 hours, > 0, High, PagerDuty and email |
| index=ods search | 18,966 events in about 24 hours, all from host WPALJA2162.prprivmgmt.intraxa |
| Sources | 2 sources and 2 sourcetypes, under /opt/oracle/oud/asinst_1/OUD/logs/ |
| Sample lines | category=BACKEND and JEB, severity NOTICE; normal log lines, not failures |
| Risk | The word "failed" can also appear in normal LDAP bind failures in access logs |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 1 and find the oud_service log file |
| 2 | Replace `/opt/oracle/oud/` with that exact path if other files are noisy |
| 3 | Run query 3; if "failed" appears many times a day, match the restart message instead |
| 4 | `terraform plan` shows 1 to add |

## Related Files

| File | Purpose |
|---|---|
| `6-oud-restart-failed-alert-tf.tf` | Detector Terraform |
| `6-oud-restart-failed-alert-tf-check.dql` | Check queries |
| `6.sh` | Commands |
