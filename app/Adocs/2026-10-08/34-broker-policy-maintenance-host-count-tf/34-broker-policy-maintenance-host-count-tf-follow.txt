# Broker Policy Maintenance Host Count

## Decision tree

```
broker-policy-maintenance host count alert
 what does "host" mean? → pod name (broker-policy-maintenance-web-<hash>-<id>)
 pods logging in last 60m < 2?
   → yes → is a pod down? → kubectl get pods → restart or scale back to 2
          → pods fine? → log forwarder or S3 bucket stopped → check forwarder
   → no → healthy
 0 pods logging? → summarize with no "by" still returns 1 row → pod_count = 0 → fires
 pod name field in Dynatrace? → check query 1 (k8s.pod.name or host.name)
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it alert on? | Fewer than 2 broker-policy-maintenance-web pods sent logs in the last 60 minutes. |
| Why does it exist? | To catch a pod that went down or logs that stopped being forwarded. |
| What is "host" here? | The Kubernetes pod name, not a server. |
| Severity? | medium, because Splunk sends email with Priority Normal. |
| PagerDuty? | "0", because the only action is email. |

## Summary

Splunk counts distinct hosts in the broker-policy-maintenance index once an hour and emails if there are fewer than 2. The hosts are the two web pods, so the alert really means "one of the two pods stopped logging". The Dynatrace detector counts distinct pods over the last 60 minutes, checks every minute, and also fires when no pod logs at all.

## Investigation

| What I checked | What I found |
|---|---|
| Search | `index=brokerpolicymaintenance-prod-axa-li-jp \| stats dc(host) as host` |
| Trigger | Custom condition `search host < 2`. |
| Time range | Last 60 minutes. |
| Cron | `0 * * * *`, once an hour. |
| Action | Send email, Priority Normal. I did not copy the recipients. |
| Hosts in the index | 2 values, both pods: `broker-policy-maintenance-web-5649696b64-vpkf9` (55%) and `...-fqsp2` (45%). |
| Source | `s3://axa-li-jp-logforwarders-prod/...`, so logs go through an S3 log forwarder. |
| Total events | About 1.6 million, mostly health check lines like `GET url:/meta/health`. |

## Result

| Setting | Value |
|---|---|
| Resource | `broker_policy_maintenance_host_count` |
| Query window | `from:now()-60m` |
| Threshold | `pod_count < 2` |
| Identity | constant `check = "broker_policy_maintenance_host_count"` |
| Severity | medium |
| pagerduty.enabled | "0" |

Things to know:

| Topic | What it means |
|---|---|
| Pod names change | A redeploy creates new pod names. During a rollout the count can briefly be 3 or 4, which is still fine. |
| Replica count | If the team scales the deployment to 1 or 3, change the threshold. |
| Field name | If Dynatrace collects these logs through OneAgent on Kubernetes, the pod name is in `k8s.pod.name`. If they come from the S3 forwarder, it may be in `host.name`. The query checks both. |
| Faster than Splunk | Splunk checked once an hour. Dynatrace checks every minute over the same 60-minute window. |

## Data flow map

```
broker-policy-maintenance-web pods (2)
  → app logs → log forwarder → S3 / Dynatrace ingest
  → Grail logs (pod name in k8s.pod.name or host.name)
  → countDistinct(pod) over 60 minutes
  → pod_count < 2 → Davis problem (medium, email only)
  → both pods logging again → problem closes
```

## Related files

| File | What it is |
|---|---|
| `34-broker-policy-maintenance-host-count-tf.tf` | The detector |
| `34-broker-policy-maintenance-host-count-tf-check.dql` | Finds the pod name field and counts per pod |
| `34-broker-policy-maintenance-host-count-tf.spl` | Splunk checks for the host count and last log time |
| `34.sh` | Commands |

## Commands

These are in `34.sh`. Nothing has been run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/34-broker-policy-maintenance-host-count-tf"
terraform init
terraform validate
terraform plan
terraform apply
kubectl get deploy broker-policy-maintenance-web -A
kubectl get pods -A -l app=broker-policy-maintenance-web
```
