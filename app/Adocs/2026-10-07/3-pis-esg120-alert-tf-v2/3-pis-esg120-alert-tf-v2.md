# PIS ESG120 Alert Version 2

## Decision Tree

```
Real ESG120 events = multi-line HTTP response with JSON body ("errorCode": "ESG120", "Routing failed")
 → filter by pisp2.log path + exact "errorCode": "ESG120" text
 check.dql query 2 → 5 events from 10/6 found?
   yes → terraform plan → apply
   no  → query 1: is pisp2.log ingested? fix ingest first
 Host name unclear (CEAA2088 or CEAA20B8) → path filter only, so it doesn't matter
```

## Short Takeaway

| Question | Answer |
|---|---|
| What changed from seq 2 | Host filter removed; the log path alone selects the file |
| Why | Host reads CEAA2088 here and CEAA20B8 earlier; the path is unambiguous |
| Real event shape | Multi-line HTTP response; the JSON body has errorCode ESG120 and errorMessage Routing failed |
| Does the match still work | Yes; `"errorCode": "ESG120"` is on one line with one space, as in the Splunk regex |
| Volume | 5 events on 10/6 |
| Notification | Email only (priority Normal): severity medium, `pagerduty.enabled = "0"` |

## Summary

The search results show what ESG120 looks like in the log: ESG answered the batch with an HTTP error body, `"errorCode": "ESG120", "errorMessage": "Routing failed"`. The detector matches that exact text in `pisp2.log` and alerts on any match, which covers Splunk's "more than 0". Filtering on the file path avoids the unclear host name.

## Splunk To Dynatrace

| Splunk | Dynatrace |
|---|---|
| `index=claims host=... sourcetype=pis_defaultlog` | `contains(log.source, "/IFDATA/DATA/PC/LOG/PISP2/")` |
| `regex _raw = "\"errorCode\"\:\s\"ESG120\""` | `contains(content, "\"errorCode\": \"ESG120\"")` |
| Last 5 minutes, cron */5 | Checks every minute and looks back 2 hours |
| Results > 0 | Any row raises an alert |
| For each result | One problem per host (`alertIdentityFields[0] = host.name`) |
| Expires 24 hours | No equivalent |
| Email, priority Normal | `alert.severity medium`, `pagerduty.enabled 0` |

## Query

```
fetch logs
| filter contains(log.source, "/IFDATA/DATA/PC/LOG/PISP2/")
| filter contains(content, "\"errorCode\": \"ESG120\"")
```

## Data Flow

```
PIS batch → ESG → OpenPaaS
              ✗ Routing failed → HTTP error body {"errorCode": "ESG120"} → pisp2.log → Grail
  → every minute: any ESG120 line in the last 2 hours? → medium problem (PIS) → email
```

## Investigation

| Checked | Finding |
|---|---|
| Search results | 5 events on 10/6, all from pisp2.log |
| Event body | Date and Server headers, then JSON with errorCode ESG120 and errorMessage Routing failed |
| Host | Reads CEAA2088.prprivmgmt.intraxa in this screenshot |
| Alert actions | Only Send email visible, priority Normal |

## Result

| Step | What to do |
|---|---|
| 1 | Run check.dql query 2; you should see the 5 events from 10/6 |
| 2 | Use this file instead of seq 2 (same resource name) |
| 3 | `terraform plan` shows 1 to add (or 1 to change if seq 2 was applied) |

## Related Files

| File | Purpose |
|---|---|
| `3-pis-esg120-alert-tf-v2.tf` | Detector Terraform |
| `3-pis-esg120-alert-tf-v2-check.dql` | Check queries |
| `3.sh` | Commands |
