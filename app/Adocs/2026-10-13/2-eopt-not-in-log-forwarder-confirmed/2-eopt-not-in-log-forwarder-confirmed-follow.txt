# eopt Not In Log Forwarder Confirmed

## Decision tree

```
Is this PRD?
 1 h total = 134.53 GiB, oneagent 65 M lines → yes, PRD
Any eopt log under host, pod, namespace or source (24 h)?
 0 records (154.43 GiB scanned) → no
 lower(host.name) starts eopt (24 h) → 0 records (465.66 GiB) → no
Is eopt in the OpenShift log forwarder?
 multilogforwarder namespaces = 11 → eopt-prod-axa-li-jp not listed → no
Result
 → eopt logs are not onboarded to Dynatrace
 → ask platform team to add eopt-prod-axa-li-jp to the forwarder
 → after onboarding, check fields on the new logs → adjust alerts 31 and 34 if needed
```

## Short takeaway

| Question | Answer |
|---|---|
| Right tenant? | Yes. 134 GiB per hour and 65 million OneAgent lines is PRD. |
| Any eopt log at all? | No. Zero across host.name, k8s.pod.name, k8s.namespace.name and log.source for 24 hours. |
| Why? | eopt is not one of the 11 namespaces sent by `multilogforwarder-log-handler-dynatrace`. |
| Fix | Platform team adds `eopt-prod-axa-li-jp` to the log forwarder. |
| Alerts 31 and 34 | Correct logic, but they stay silent until the logs arrive. |

## Summary

The checks rule out tenant, field name and letter case. Other OpenPaaS apps send logs through the multilogforwarder, and eopt is simply not on that list. This is an onboarding gap, not a query problem. The small scan size in the first query was not a tenant issue: Grail skips data it knows cannot match the filter, so filtered queries scan less.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Log forwarder | An OpenShift component that copies pod logs to another system. | It is how OpenPaaS apps get logs into Dynatrace. |
| `multilogforwarder-log-handler-dynatrace` | The `log.source` value on logs that came through the forwarder. | Shows which namespaces are onboarded. |
| Namespace | A folder for one app's pods in OpenShift, for example `eopt-prod-axa-li-jp`. | The forwarder is set up per namespace. |
| Onboarding | Adding an app to the forwarder settings. | eopt needs this step. |
| Data skipping | Grail reads only data blocks that might match the filter. | Explains why scanned bytes change between queries. |

### What each screenshot proved

| Query | Result | What it proves |
|---|---|---|
| Logs per `dt.openpipeline.source`, 1 hour | 7 sources, 134.53 GiB, oneagent 65,088,085 lines | This is PRD with full data. |
| eopt in host, pod, namespace or source, 24 hours | 0 records, 154.43 GiB | No eopt logs under any common field. |
| `lower(host.name)` starts with eopt, 24 hours | 0 records, 465.66 GiB | Not a letter case problem. |
| Forwarder logs per namespace, 1 hour | 11 namespaces, no eopt | eopt is not onboarded. |

### Namespaces the forwarder sends today (1 hour)

| Namespace | Lines |
|---|---|
| compassproxy-prod-axa-li-jp | 154,642 |
| axahp-prod-axa-li-jp | 32,504 |
| nbwf-prod-axa-li-jp | 8,600 |
| orgchangerequestmgmt-prod-axa-li-jp | 7,133 |
| www2rp-prod-axa-li-jp | 4,688 |
| taxdeduction-prod-axa-li-jp | 2,856 |
| documentuploadproxy-prod-axa-li-jp | 2,852 |
| capportalsystemapi-prod-axa-li-jp | 2,138 |
| forthehappyfuture-prod-axa-li-jp | 664 |
| pbcosupportbe-prod-axa-li-jp | 12 |
| capportalprocessapi-prod-axa-li-jp | 8 |
| eopt-prod-axa-li-jp | Not present |

## Result

### Next steps

| Step | What to do |
|---|---|
| 1 | Send the request below to the OpenPaaS platform team. |
| 2 | While waiting, run check query 1 on a similar onboarded app (capportalsystemapi). It shows which fields forwarder logs carry. |
| 3 | After onboarding, run check query 2 to confirm eopt lines arrive. |
| 4 | If forwarder logs have the pod name in `k8s.pod.name` instead of `host.name`, change alerts 31 and 34 to the filter in check query 3. |
| 5 | Keep the Splunk eopt alerts on until the Dynatrace alerts are proven. |

### Request draft (English)

```
Subject: Please onboard eopt-prod-axa-li-jp logs to Dynatrace (multilogforwarder)

Hi team,

We are migrating eopt alerts from Splunk to Dynatrace. eopt pods are visible in
Dynatrace as hosts (OneAgent App only), but no eopt logs reach Dynatrace.

Evidence (DT PRD, 2026-10-13):
- 0 log records for eopt in host.name, k8s.pod.name, k8s.namespace.name, log.source over 24 h
- log.source "multilogforwarder-log-handler-dynatrace" sends 11 namespaces;
  eopt-prod-axa-li-jp is not one of them
- Splunk still receives eopt logs via S3 (axa-li-jp-logforwarders-prod)

Request:
- Add namespace eopt-prod-axa-li-jp (eoptsystemapi, eoptprocessapi, eoptfrontend)
  to the Dynatrace log forwarder, same as capportalsystemapi-prod-axa-li-jp
- Keep the Splunk S3 forwarding as is until we confirm the Dynatrace alerts

Thank you.
```

### Request draft (Japanese)

```
件名：eopt-prod-axa-li-jp のログを Dynatrace へ連携してください（multilogforwarder）

お疲れ様です。
eopt のアラートを Splunk から Dynatrace へ移行しています。
eopt の Pod は Dynatrace 上でホスト（OneAgent App only）として見えていますが、
ログが Dynatrace に届いていません。

確認結果（DT PRD、2026-10-13）：
- 24時間で host.name / k8s.pod.name / k8s.namespace.name / log.source のいずれにも eopt のログが 0 件
- log.source "multilogforwarder-log-handler-dynatrace" の対象は 11 Namespace で、eopt-prod-axa-li-jp は含まれていない
- Splunk には S3（axa-li-jp-logforwarders-prod）経由で eopt のログが届いている

依頼内容：
- Namespace eopt-prod-axa-li-jp（eoptsystemapi、eoptprocessapi、eoptfrontend）を
  capportalsystemapi-prod-axa-li-jp と同様に Dynatrace ログ転送の対象に追加
- Dynatrace アラートの確認が終わるまで、Splunk への S3 転送はそのまま維持

よろしくお願いいたします。
```

### Check queries

```
// 1. What fields do forwarder logs carry? (use an onboarded app as the example)
fetch logs, from:now()-1h
| filter k8s.namespace.name == "capportalsystemapi-prod-axa-li-jp"
| fields timestamp, host.name, k8s.pod.name, k8s.container.name, k8s.namespace.name, log.source, content
| limit 10

// 2. After onboarding: are eopt logs arriving?
fetch logs, from:now()-1h
| filter k8s.namespace.name == "eopt-prod-axa-li-jp"
| summarize lines = count(), by:{ k8s.pod.name }

// 3. Filter for alerts 31 and 34 if the pod name is in k8s.pod.name, not host.name
fetch logs, from:now()-1h
| filter startsWith(k8s.pod.name, "eoptsystemapi-")
    or startsWith(k8s.pod.name, "eoptprocessapi-")
    or startsWith(k8s.pod.name, "eoptfrontend-")
    or startsWith(host.name, "eoptsystemapi-")
    or startsWith(host.name, "eoptprocessapi-")
    or startsWith(host.name, "eoptfrontend-")
| summarize lines = count(), by:{ host.name, k8s.pod.name }
```

## Data flow map

```
Today:
capportalsystemapi, compassproxy, ... (11 namespaces)
  → OpenShift log forwarder → /api/v2/logs/ingest → Grail ✔

eopt-prod-axa-li-jp
  → S3 (axa-li-jp-logforwarders-prod) → Splunk ✔
  → OpenShift log forwarder ✘ (not configured)
  → Grail: 0 lines → alerts 31 and 34 silent

After onboarding:
eopt-prod-axa-li-jp → log forwarder → Grail → alerts 31 and 34 fire
```

## Related files

| File | What it holds |
|---|---|
| `2-eopt-not-in-log-forwarder-confirmed-check.dql` | Three check queries. |
| `2-eopt-not-in-log-forwarder-confirmed-request.txt` | Request drafts in English and Japanese. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | Evidence. |
| `2-result.md` | Next steps. |
| `3-glossary.md` | Words used. |
| `2.sh` | Git one-liners. |
| `Daily Files/2026-10-13/1-eopt-query-no-result-why/` | The first check round. |

## Commands

The checks are DQL. Git one-liners are in [`2.sh`](./2.sh). Nothing was run.

```bash
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-13/2-eopt-not-in-log-forwarder-confirmed
git commit -m "eopt not in log forwarder confirmed"
git push
```
