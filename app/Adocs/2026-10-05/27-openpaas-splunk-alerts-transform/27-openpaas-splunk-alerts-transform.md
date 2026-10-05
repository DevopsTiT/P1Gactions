# OpenPaaS Splunk Alerts Transform

## Decision tree

```
7 Splunk alerts (OpenPaaS, ESG, PIS, eopt) → Terraform only
 3 alerts share the "Emma BE timeout to ESG" search → DUPLICATES → merge into 1 detector (High)
 Egress proxy IP alert: "stats count | where count <= 0" → ABSENCE alert → condition BELOW 1 for 15 of 15 minutes
 "> 20 in 5 minutes"                                      → rolling 5-minute sum, threshold 20
 PIS regex errorCode ESG120                               → contains "errorCode" and "\"ESG120\""
 eopt backend rex / frontend spath                        → DPL parse ISO8601 + WORD / JSON
 hourly email alerts (eopt)                               → detector, dealerting 60 (one alert per hour-ish)
 Splunk index / sourcetype / host                         → mapped by guess → CONFIRM with check.dql query 1
 no workflows                                             → every problem goes to the standard SILVA + PagerDuty flow; email-only alerts lose their email
 PagerDuty key visible in screenshot 5                    → not copied; standard flow handles paging
```

## Short takeaway

| Question | Answer |
|---|---|
| How many detectors? | 5 from 7 Splunk alerts |
| Biggest cleanup | 3 Splunk alerts run the exact same search and all notify. Merged into 1 |
| Tricky one | The egress proxy alert fires when something is *missing*. In Dynatrace that's `alertCondition = BELOW` |
| Must do before apply | Replace the guessed index and sourcetype fields (lines marked CONFIRM) |
| No workflows means | No emails. Problems go to the standard SILVA and PagerDuty workflow, including the "Normal" ones |

## Summary

These seven alerts collapse to five detectors in one `for_each` file. The three "Emma BE timeout to ESG" alerts are copies of one search with different notifications, so they become a single High detector. The egress proxy alert is an absence check: Splunk fires when the two expected IPs did not appear at all in 15 minutes, which in Dynatrace is a "below 1 for 15 straight minutes" condition. The Splunk index and sourcetype names don't exist in Dynatrace, so I mapped them to likely fields (`log.source`, `k8s.namespace.name`, `host.name`); run the discovery query and fix those lines before applying.

## The 7 Splunk alerts

| # | Splunk alert | Search (short) | Trigger | Actions | Dynatrace |
|---|---|---|---|---|---|
| 1 | ALJ OpenPaaS Egress Proxy Public IP Usage Alert | apigw_syslog, `/maam/`, IP 52.76.125.86 or 54.179.120.88, count <= 0 | Every 15 min over 15 min | Email, High | `egress_proxy_ip_absent` (BELOW 1, 15 of 15 minutes) |
| 2 | ESG - Emma BE timeout to ESG Production | Emma BE SocketTimeoutException + apigw "Problem routing to ... timed out" | Every 5 min, > 20, throttle 60 s | Email, High | Merged into `emma_be_timeout_to_esg` |
| 3 | PIS Connection Issue (Batch->OpenPaaS) Alert | claims, host CEAA2058, pis_defaultlog, errorCode ESG120 | Every 5 min, > 0 | Email, Normal | `pis_connection_esg120` |
| 4 | Prod_Life_Emma_EmmaBETmeoutToESGProduction_High | Same as 2 | Same as 2 | Triggered alert High, PagerDuty, email | Merged into `emma_be_timeout_to_esg` |
| 5 | Prod_Life_Emma_EmmaBETmeoutToESGProduction_High_PagerDuty | Same as 2 | Same as 2 | PagerDuty (key in alert) | Merged into `emma_be_timeout_to_esg` |
| 6 | eopt - OpenPaaS Pod Error (Backend) | eopt-prod-axa-li-jp, rex timestamp + level, level ERROR | Hourly, > 0 | Email, Normal | `eopt_pod_error_backend` |
| 7 | eopt - OpenPaaS Pod Error (Frontend) | eopt-prod-axa-li-jp, spath, level ERROR | Hourly, > 0 | Email, Normal | `eopt_pod_error_frontend` |

## Index and field mapping (CONFIRM)

| Splunk | Guessed Dynatrace filter | Why the guess |
|---|---|---|
| `index=apigw_syslog sourcetype=apigw_syslog_prod` | `matchesValue(log.source, "*apigw_syslog*")` | Syslog source from the API gateway |
| `index="myaxabackend-prod-axa-li-jp"` | `k8s.namespace.name == "myaxabackend-prod-axa-li-jp"` | Looks like an OpenPaaS (OpenShift) namespace name |
| `index="eopt-prod-axa-li-jp"` | `k8s.namespace.name == "eopt-prod-axa-li-jp"` | Same naming pattern |
| `index=claims host="CEAA2058..." sourcetype=pis_defaultlog` | `matchesValue(host.name, "ceaa2058*")` and `matchesValue(log.source, "*pis_default*")` | OneAgent host name is often the short name |

`check.dql` query 1 lists bucket, log source, namespace and host for lines matching each alert, so you can replace every guess with the real value.

## Alert 1: egress proxy, an absence alert

| Splunk | Dynatrace |
|---|---|
| `/maam/*` and (`*52.76.125.86*` or `*54.179.120.88*`) | `contains(content, "/maam/")` and (IP 1 or IP 2). Splunk evaluates OR before the implicit AND, so this matches |
| `stats count \| where count <= 0` over 15 minutes | Count per minute, condition BELOW, threshold 1 |
| Every 15 minutes | `violatingSamples = 15`, `slidingWindow = 15`: all 15 minutes must be zero |
| Recovery | `dealertingSamples = 5`: closes after traffic returns |

The description says the alert means "only one public IP is used; the other two egress IPs are missing". `check.dql` query 2 shows per hour how often each IP appears, so you can see whether a 15-minute gap is normal at night.

## Alerts 2, 4, 5: Emma BE timeout to ESG (merged)

| Splunk | Dynatrace |
|---|---|
| Search A or `append` search B | One `filter` with `(A) or (B)` |
| More than 20 in 5 minutes | `arrayMovingSum(count, 5)`, threshold 20, Above |
| Throttle 60 seconds | Shorter than the 5-minute schedule, so it did nothing. Dealerting 5 instead |
| 3 alerts: email, PagerDuty plus email, PagerDuty only | 1 High problem. The standard workflow pages; one page instead of up to three |

The PagerDuty integration key is visible in screenshot 5. I did not copy it anywhere. Paging goes through the standard workflow.

## Alert 3: PIS ESG120

Splunk regex `"errorCode":\s"ESG120"` becomes `contains(content, "errorCode") and contains(content, "\"ESG120\"")`. That's slightly looser than the regex (it doesn't require the two to be adjacent), but it handles any spacing after the colon.

## Alerts 6 and 7: eopt pod errors

| Alert | Splunk | Dynatrace |
|---|---|---|
| Backend | `rex` timestamp then level | `parse content, "LD ISO8601:log_ts SPACE+ WORD:level"`, then `upper(level) == "ERROR"` |
| Frontend | `spath` (JSON) then level | `parse content, "JSON:j"`, then `upper(toString(j[level])) == "ERROR"` |
| Hourly schedule | Every hour at :00 | Detector every minute, `dealertingSamples = 60` so a burst stays one problem for about an hour |

`check.dql` query 3 compares both parses with `status == "ERROR"`. If `status_error` gives the same numbers, use `filter status == "ERROR"` for both and drop the parses.

## What "Terraform only" means for notifications

| Alert | Splunk notified | Dynatrace without workflows |
|---|---|---|
| Emma BE timeout | PagerDuty and email | Standard flow: SILVA + PagerDuty. No email |
| Egress proxy IP | Email (High) | Standard flow: SILVA + PagerDuty. No email |
| PIS ESG120 | Email (Normal) | Standard flow: SILVA + PagerDuty, which is more than before |
| eopt backend, frontend | Email (Normal) | Same: would now page |

The standard workflow triggers on every new problem, including custom alerts. Before applying, decide with the team whether the `_Normal` alerts should page. If not, the standard workflow needs a skip rule (for example, skip problems whose name ends in `_Normal`), or those alerts need small email workflows after all.

The standard workflow also finds the SILVA group from entity tags. These are log-based alerts with no host attached (except possibly PIS on CEAA2058), so routing has the same gap as the Cisco alert (seq 21).

## Data flow

```
apigw syslog, OpenPaaS pods (myaxabackend, eopt), PIS host CEAA2058
  → Dynatrace log ingest → Grail
  → 5 detectors every minute
      egress IPs absent 15 min   → High
      Emma BE timeouts > 20/5min → High
      PIS ESG120 > 0             → Normal
      eopt backend ERROR > 0     → Normal
      eopt frontend ERROR > 0    → Normal
  → problems → standard SILVA + PagerDuty workflow (routing and _Normal handling to decide)
```

## Investigation

| Checked | Finding |
|---|---|
| 7 screenshots | 7 Splunk alerts from the OpenPaaS search |
| Screenshots 2, 4, 5 | Identical search, trigger and throttle; only actions differ |
| Screenshot 1 | Absence logic: `stats count \| where count <= 0` |
| Screenshot 5 | PagerDuty integration key visible; not copied |
| Screenshots 6, 7 | Same index, backend text lines vs frontend JSON lines |
| Throttle 60 seconds | No effect on a 5-minute schedule |

## Result

One Terraform file with 5 detectors in a `for_each` map. Before applying: replace the guessed field filters, check the eopt parses, and decide how `_Normal` and email-only alerts should be notified now that there are no workflows.

## Related files

| File | Purpose |
|---|---|
| `27-openpaas-splunk-alerts-transform.tf` | 5 detectors |
| `27-openpaas-splunk-alerts-transform-check.dql` | Field discovery, egress IP history, eopt parse check, timeout peaks |
| `27.sh` | Validate, plan, mirror and git one-liners |
| `2026-10-05/16-emma-msgbox-alert-tf-check/` | Rolling-sum pattern |
| `2026-10-05/21-cisco-vpn-ldap-two-alerts-transform/` | Routing gap options |

## Commands

See `27.sh` (not run).
