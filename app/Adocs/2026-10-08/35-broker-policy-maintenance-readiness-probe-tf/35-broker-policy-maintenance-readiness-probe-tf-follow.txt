# Broker Policy Maintenance Readiness Probe

## Decision tree

```
ReadinessProbe失敗エラー(HealthCheck)
 does statusCode exist on /meta/health lines? (check query 1)
   → no → Splunk alert can never fire (dead) → decide: drop it, or log statusCode first
   → yes ↓
 pod's newest health status in last 5m != 200?
   → yes → problem per pod → kubectl describe pod → readiness probe events
          → app slow or dependency down → fix app / dependency
   → no → healthy (problem closes when it goes back to 200)
 want old Splunk "status changed" mail exactly? → not recommended (mails on recovery, silent while broken, flaps across pods)
```

## Short takeaway

| Question | Answer |
|---|---|
| What does Splunk do? | It takes the newest 2 health check lines and mails when their status codes differ. |
| Why is that weak? | It mails on recovery too, stays silent while the probe keeps failing, and mixes both pods. |
| What does Dynatrace do? | One problem per pod while that pod's newest health status is not 200. It closes when 200 returns. |
| Biggest risk | Your search screenshot shows no `statusCode` field on the health lines, so the Splunk alert may never fire. |
| Severity and PagerDuty | medium and "0", because the action is email only. |

## Summary

The Splunk alert is a "status changed" detector, not a "status is bad" detector. It compares the two newest health lines across both pods. The Dynatrace version keeps the intent, which is to tell someone when the readiness check fails. It does this per pod, stays open while the pod is unhealthy, and closes on its own on recovery. First confirm that `statusCode` is actually logged.

## Investigation

### What the Splunk search does, line by line

| Step | What it does |
|---|---|
| `GET "/meta/health" statusCode!=""` | Keeps health check lines that have a status code. |
| `head 2` | Keeps only the newest 2 lines, from either pod. |
| `earliest(statusCode)` | Status code of the older of the two. |
| `latest(statusCode)` | Status code of the newer of the two. |
| `where earliest != latest` | Keeps the row only if the code changed. |
| Trigger | More than 0 results, every 5 minutes, over the last 5 minutes. |

### Problems with that logic

| Problem | What happens |
|---|---|
| Mails on recovery | 503 followed by 200 is also a change, so the team gets a "failure" mail when it recovers. |
| Silent while broken | 503 followed by 503 is no change, so a pod that keeps failing raises nothing after the first mail. |
| Mixes pods | If pod A returns 200 and pod B returns 503, the newest 2 lines can alternate and cause flapping mails. |
| Field may be missing | The search screenshot's field list shows level, message, spanId, timestamp and traceId, but not statusCode. If the health lines never carry statusCode, the search returns nothing and the alert is dead. |

### Other settings

| Setting | Value |
|---|---|
| Time range | Last 5 minutes |
| Cron | `*/5 * * * *` |
| Action | Send email. I did not copy the recipients. |

## Result

| Setting | Value |
|---|---|
| Resource | `broker_policy_maintenance_readiness_probe` |
| Query window | `from:now()-5m` |
| Identity | pod |
| Fires when | The pod's newest health status is not "200". |
| Closes when | The pod's newest health status is "200" again. |
| Severity | medium |
| pagerduty.enabled | "0" |

If check query 1 shows that statusCode never exists, the source logs need to change. Ask the app team to log the response status on `/meta/health`. A simpler alternative is to rely on Kubernetes readiness events (`reason=Unhealthy`) or the broker-policy-maintenance host count detector from seq 34.

## Data flow map

```
kubelet readiness probe → GET /meta/health on each pod
  → app log line (statusCode?) → forwarder → Grail
  → per pod: newest statusCode in 5 minutes
  → != 200 → Davis problem (medium, email only)
  → == 200 → problem closes
```

## Related files

| File | What it is |
|---|---|
| `35-broker-policy-maintenance-readiness-probe-tf.tf` | The detector |
| `35-broker-policy-maintenance-readiness-probe-tf-check.dql` | Checks whether statusCode exists, and shows the per-pod output |
| `35-broker-policy-maintenance-readiness-probe-tf.spl` | Splunk checks for statusCode values |
| `35.sh` | Commands |

## Commands

These are in `35.sh`. Nothing has been run. Replace `<namespace>` and `<pod-name>` with the values from the first kubectl command.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/35-broker-policy-maintenance-readiness-probe-tf"
terraform init
terraform validate
terraform plan
terraform apply
kubectl get pods -A | grep broker-policy-maintenance
kubectl describe pod -n <namespace> <pod-name>
kubectl get events -n <namespace> --field-selector reason=Unhealthy
```
