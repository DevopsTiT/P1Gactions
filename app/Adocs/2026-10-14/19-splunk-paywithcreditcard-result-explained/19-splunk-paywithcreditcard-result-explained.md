# Splunk PayWithCreditCard Result Explained

## Decision tree

```
Splunk screen: SPL #85 → 75 events in the last hour
 What are the 75 events? → successful credit-card payment calls (policy change) → healthy traffic
 Want the same in Dynatrace?
   url field = full URL → match with contains(), not ==   (fix for #23–#27, #82–#84 too)
   host = pod name (portals-amp-backend-xxxx) → filter on pod or host prefix
   source = s3://axa-gi-jp-logforwarders-prod → logs come via S3
     check query finds portals-amp in Dynatrace? → compare count with Splunk's 75
     finds nothing? → logs are S3 / Splunk only → onboarding request
```

## Short takeaway

| Question | Answer |
|---|---|
| Which search is this? | SPL #85: payWithCreditCard_Adj with EXECUTION_COMPLETED, last 1 hour. |
| What did it find? | 75 completed credit-card payment calls between 14:58 and 15:58 JST. |
| Is that good or bad? | Good. EXECUTION_COMPLETED with level info means the call finished. |
| Which pods? | Two `portals-amp-backend-...` pods. |
| Where does Splunk get the logs? | From S3 bucket `axa-gi-jp-logforwarders-prod`. |
| What does it change in my DQL? | `url` is the full URL. Use `contains()` instead of `==`. |

## Summary

The screen shows about one successful credit-card payment per minute, spread over two backend pods. The important lesson is the `url` value: it is a full URL ending in `/payWithCreditCard_Adj`, and the Splunk search uses wildcards (`*payWithCreditCard_Adj*`). My earlier DQL compared with `==`, which would return 0 rows. The fix is `contains()`, and the same fix applies to #23 to #27 and #82 to #84. Also, these logs reach Splunk through S3, so they may not be in Dynatrace yet.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| Event | One log record. Splunk counts 75 of them here. |
| `spath` | Splunk command that turns the JSON into fields like `message.url`. |
| `EXECUTION_COMPLETED` | The app's message type for "the call finished". |
| `CAUGHT_EXCEPTION_ON_BACKEND` | The app's message type for "the call failed with an error". |
| `request_id` | ID of one API call. Lets you follow the call across logs. |
| `target_system` | Which back-end system the call went to. Here `PC_CUSTOMER` (PolicyCenter). |
| Interesting fields | Splunk's left panel. The number shows how many different values a field has. |

### Reading the screen, top to bottom

| Part of the screen | What it shows | What it means |
|---|---|---|
| Search bar | `sourcetype="portals-amp-backend" earliest=-1h ... message.url=*payWithCreditCard_Adj* message.type="EXECUTION_COMPLETED"` | Last hour, AMP backend, payment calls that completed. |
| Result count | 75 events, 14:58:28 to 15:58:27 on 10/14/26 | About 1.25 completed payments per minute. |
| Timeline bars | Green bars spread across the hour | Steady traffic. No long gap, so no outage in this hour. |
| `level: info` | Log level | Normal event, not an error. |
| `message.method: post` | HTTP method | The portal sent a POST request. |
| `message.service` | The service name inside the app | Which internal service handled it. |
| `message.target_system: PC_CUSTOMER` | Downstream system | The payment updates the policy in PolicyCenter. |
| `message.type: EXECUTION_COMPLETED` | Result type | The call finished. |
| `message.url: https://portals-api-gateway-inssuite-prod.../pc/rest/policychange/policychange/v1/payWithCreditCard_Adj` | Full API URL | The policy-change API for paying by credit card. |
| `timestamp: 2026-10-14T06:57:03.016Z` | App's own time, in UTC (the `Z`) | 06:57 UTC equals 15:57 JST, which matches the Time column. |
| `host = portals-amp-backend-5f57cbc7-lgk6x` | Pod name | Splunk stores the pod name as host. |
| `source = s3://axa-gi-jp-logforwarders-prod/2026/10/14/06/...` | Where Splunk read the log | Logs travel pod → S3 → Splunk. |
| `sourcetype = portals-amp-backend` | Splunk label | The thing the search filters on. |
| Left panel `host 2` | Two different hosts | Two pods are serving traffic. |
| Left panel `source 75` | 75 different sources | Each event came from its own S3 file. |

### What changes in the DQL

| Before (answers 13 and 17) | After | Why |
|---|---|---|
| `msg_url == "payWithCreditCard_Adj"` | `contains(msg_url, "payWithCreditCard_Adj")` | The value is a full URL. Splunk uses `*...*` wildcards. |
| `msg_url == "doCancel"` and similar | `contains(msg_url, "doCancel")` | Same reason. |
| `in(msg_url, array("save", "quote", ...))` | `endsWith(msg_url, "/save")` and so on | Short names like `quote` would match too much with `contains()`. |
| Source filter by container, pod, or `log.source` | `startsWith(src, "portals-amp-backend-")` | The screen proves the pod name is the host. |

## Result

Corrected #85 (also in `19-splunk-paywithcreditcard-result-explained.dql`):

```
fetch logs, from:now()-1h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "portals-amp-backend-")
| fieldsAdd raw = replaceString(replaceString(content, "\\\"", "\""), "\\", "")
| parse raw, "JSON:j"
| fieldsAdd msg_url = toString(j[message][url]),
            msg_type = toString(j[message][type]),
            request_id = toString(j[message][request_id]),
            target_system = toString(j[message][target_system]),
            level = toString(j[level])
| filter contains(msg_url, "payWithCreditCard_Adj") and msg_type == "EXECUTION_COMPLETED"
| sort timestamp desc
| fields timestamp, src, level, msg_type, target_system, request_id, msg_url
```

Count to compare with Splunk's 75:

```
fetch logs, from:now()-1h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "portals-amp-backend-")
| filter contains(content, "payWithCreditCard_Adj") and contains(content, "EXECUTION_COMPLETED")
| summarize events = count(), by:{ src }
```

Check whether the logs are in Dynatrace:

```
fetch logs, from:now()-24h
| filter contains(host.name, "portals-amp", caseSensitive:false)
    or contains(k8s.pod.name, "portals-amp", caseSensitive:false)
    or contains(k8s.container.name, "portals-amp", caseSensitive:false)
    or contains(log.source, "portals-amp", caseSensitive:false)
| summarize lines = count(), by:{ host.name, k8s.pod.name, k8s.namespace.name, log.source, dt.openpipeline.source }
```

| Check result | Meaning | Next step |
|---|---|---|
| Count is about 75 | Dynatrace has the same data. | Use the corrected DQL. |
| Count is lower | Some pods or lines are missing. | Compare pod names between the two tools. |
| Check query finds nothing | Logs go only pod → S3 → Splunk. | Raise an onboarding request, like eopt. |

## Data flow map

```
Customer pays by credit card in the portal
  -> portals-api-gateway (https://portals-api-gateway-inssuite-prod...)
  -> portals-amp-backend pod (2 pods)
  -> calls PolicyCenter (target_system PC_CUSTOMER)
  -> writes JSON log: type EXECUTION_COMPLETED, level info
  -> log shipped to S3 bucket axa-gi-jp-logforwarders-prod
  -> Splunk reads S3 -> sourcetype portals-amp-backend
  -> SPL #85 -> 75 events in 1 hour

Dynatrace (only if onboarded)
  -> fetch logs -> pod prefix -> parse JSON -> url contains payWithCreditCard_Adj -> EXECUTION_COMPLETED
```

## Related files

| File | What it holds |
|---|---|
| `19-splunk-paywithcreditcard-result-explained.dql` | Corrected #85, count, chart, check query, fixed filter lines for #23–#27 and #82–#84 |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | What the screen shows |
| `2-result.md` | The fix |
| `3-glossary.md` | Glossary |
| `19.sh` | Git one-liners |

## Commands

See `19.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/19-splunk-paywithcreditcard-result-explained
git commit -m "Splunk payWithCreditCard result explained"
git push
```
