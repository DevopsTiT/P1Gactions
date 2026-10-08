# EIP AG Portal UserInfo 500

## Decision tree

```
Prod_Life_EIP_AGPortalUserInfoService_High
 what? → AG Portal UserInfoService, called by Compass through EIP
 signal? → index=eip10 API_VERSION="jp-Distributing-Sell-UserInfoService-v1-vs" RESPONSE_CODE=500
 window? → Last 5 minutes, cron */5, results > 0, throttle 5 minutes
 actions? → Triggered Alerts (High) + PagerDuty + email → severity high, pagerduty "1"
 fields in Grail? → check.dql 1
   attributes → toString(RESPONSE_CODE) == "500" matches
   text only → content match (key=value or JSON) matches
 500 normal noise? → check.dql 2 → raise "errors > 0" threshold
 → detector: any 500 in 5 minutes → one problem → closes after a clean 5 minutes
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it watch? | HTTP 500 responses from the AG Portal UserInfoService API, as logged by EIP. |
| Who is affected? | Compass. It calls this API through EIP to get user information. |
| When does it open a problem? | When at least one 500 is logged in the last 5 minutes. |
| Resource | `eip_ag_portal_userinfo_service_500` |
| Severity and PagerDuty | high and "1" (the alert has a direct PagerDuty action) |

## Summary

This is a simple error-count alert: any HTTP 500 from the UserInfoService in 5 minutes pages on-call. In Dynatrace it becomes one problem that stays open while 500s continue and closes after a clean 5-minute window, which also replaces Splunk's 5-minute throttle. Before applying, check where `eip10` logs land in Grail and whether `RESPONSE_CODE` is a real attribute or only text.

## Investigation

### Splunk settings

| Setting | Value |
|---|---|
| Search | `index=eip10 API_VERSION="jp-Distributing-Sell-UserInfoService-v1-vs" RESPONSE_CODE=500` |
| Description | An API service provided by AG Portal and consumed by Compass via EIP |
| Time range | Last 5 minutes |
| Cron | `*/5` |
| Expires | 30 minutes |
| Trigger | Results > 0, once |
| Throttle | Suppress for 5 minutes |
| Action 1 | Add to Triggered Alerts, severity High |
| Action 2 | PagerDuty. I did not copy the integration key. |
| Action 3 | Send email. I did not copy the recipients. |

### How the Splunk settings map to Dynatrace

| Splunk | Dynatrace |
|---|---|
| `API_VERSION=...` | Text match on the API name, or the attribute if it exists |
| `RESPONSE_CODE=500` | Attribute match, or text match for `key=value` and JSON formats |
| Results > 0, once | `summarize` into one row, `filter errors > 0` |
| Throttle 5 minutes | One open problem doesn't re-notify while 500s continue |
| PagerDuty action | `pagerduty.enabled = "1"` |
| Triggered Alerts High | `alert.severity = "high"` |

### Things to check

| Point | Why it matters |
|---|---|
| Where `eip10` lands in Grail | There is no fixed host filter yet. Once check query 1 shows the `log.source` or host, add it to make the query cheaper and safer. |
| Attribute or text | Splunk extracted `API_VERSION` and `RESPONSE_CODE` at search time. In Grail they may only be inside `content`, so the query checks both. |
| Normal 500 rate | One 500 pages someone. If check query 2 shows a steady trickle of 500s, raise the threshold, for example `errors >= 3`. |

## Result

| Setting | Value |
|---|---|
| Resource | `eip_ag_portal_userinfo_service_500` |
| Window | `from:now()-5m` |
| Opens when | `errors > 0` |
| Identity | `check` (one problem for the whole API) |
| Severity | high |
| pagerduty.enabled | "1" |

## Data flow map

```
Compass → EIP (API gateway) → AG Portal UserInfoService
  EIP access log (index=eip10): API_VERSION=jp-Distributing-Sell-UserInfoService-v1-vs, RESPONSE_CODE=500
  → Dynatrace logs (Grail)
  → filter API name + RESPONSE_CODE 500 (attribute or text), last 5m
  → summarize errors → errors > 0
  → problem (high, pagerduty 1) → stays open while 500s continue → closes after a clean 5m
```

## Related files

| File | What it is |
|---|---|
| `58-eip-ag-portal-userinfo-500-tf.tf` | Detector |
| `58-eip-ag-portal-userinfo-500-tf-check.dql` | Where lines land, 500 rate over 7 days, detector filter test |
| `58-eip-ag-portal-userinfo-500-tf.spl` | Raw lines, codes per hour, 500s per day, alert fire history |
| `58.sh` | Commands |

## Commands

These are in `58.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/58-eip-ag-portal-userinfo-500-tf"
terraform init
terraform validate
terraform plan
terraform apply
```
