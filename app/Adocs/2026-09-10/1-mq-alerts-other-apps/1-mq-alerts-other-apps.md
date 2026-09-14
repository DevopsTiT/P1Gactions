# MQ Alerts For Other Apps

```
ContactManager MQ alerts (current)
  │
  ├─ Same Guidewire messaging metrics?
  │     yes → clone TF, change app filter + names
  │     no  → do NOT copy guidewire.messaging.* (different metrics)
  │
  └─ Copy into applications/<app>/test/ then plan/apply that stack
```

| Key point | Detail |
| --- | --- |
| Template | `contactmanager/test/alerting_contactmanager_mq.tf` |
| What changes per app | Resource name, summary/title, `filter(eq(app,<code>))`, state key |
| Generated for | BillingCenter (`bc`), ClaimCenter (`cc`), PolicyCenter (`pc`) |
| Not auto-cloned | compass, OUD, PRC, EIS, CIS, BRM (confirm metrics first) |

## Summary

Your current ContactManager file defines **8 metric-event pairs** (failed / retry / inflight / unsent × Critical ERROR + Warning RESOURCE) on `guidewire.messaging.*` with `filter(eq(app,cm))`. For other **Guidewire** apps, keep the same thresholds and only change the app code and display names. Generated files are under `applications/` in this folder — copy them into `dynatrace-terraform-main`.

---

## Pattern from ContactManager (what stays the same)

| Setting | Value |
| --- | --- |
| Resource type | `dynatrace_metric_events` |
| Dimension key | `queue.name` |
| Model | `STATIC_THRESHOLD` / `ABOVE` |
| Critical | threshold **100**, violating **3**/10, event_type **ERROR** |
| Warning | threshold **10**, violating **10**/10, event_type **RESOURCE** |
| Metrics | `failed`, `retry`, `inflight`, `unsent` |
| Split | `queue.name`, `queue.id` |

## What to change per app

| Field | ContactManager | Example BillingCenter |
| --- | --- | --- |
| Folder | `applications/contactmanager/test/` | `applications/billingcenter/test/` |
| File | `alerting_contactmanager_mq.tf` | `alerting_billingcenter_mq.tf` |
| Resource name | `alerting_contactmanager_mq_failed_error` | `alerting_billingcenter_mq_failed_error` |
| Summary / title | `ContactManager Test …` | `BillingCenter Test …` |
| Metric filter | `eq(app,cm)` | `eq(app,bc)` |
| S3 state key | `…/contactmanager/test/…` | `…/billingcenter/test/…` |

## App code map (Guidewire)

| App folder | Display name | `eq(app,…)` |
| --- | --- | --- |
| contactmanager | ContactManager | `cm` |
| billingcenter | BillingCenter | `bc` |
| claimcenter | ClaimCenter | `cc` |
| policycenter | PolicyCenter | `pc` |

Confirm `bc` / `cc` / `pc` match the **actual** `app` dimension on your metrics in Dynatrace before apply. If your tenant uses different codes, edit the filter only.

## Apps in sidebar — do not blindly clone

| App folder | Why |
| --- | --- |
| compass | Likely different metrics (anomaly files, not guidewire MQ) |
| oracle-unified-directory | Directory — not Guidewire messaging |
| product-rate-calculation | Different domain metrics |
| enterprise-integration-* | Confirm before using `guidewire.messaging.*` |
| life*-customer-information* | Confirm before using `guidewire.messaging.*` |
| business-rules-manager | Confirm before using `guidewire.messaging.*` |

---

## Generated files (ready to copy)

```
applications/
  billingcenter/test/alerting_billingcenter_mq.tf
  billingcenter/test/provider.tf
  claimcenter/test/alerting_claimcenter_mq.tf
  claimcenter/test/provider.tf
  policycenter/test/alerting_policycenter_mq.tf
  policycenter/test/provider.tf
  contactmanager/test/alerting_contactmanager_mq.tf   # reconstructed reference
```

Copy into your repo:

`Tasks/Migration/GithubResources/dynatrace-terraform-main/applications/<app>/test/`

## How to apply (per app stack)

1. Copy `alerting_<app>_mq.tf` (+ `provider.tf` if that env folder is empty)  
2. Confirm Dynatrace token / env for that stack  
3. In that folder: `terraform init` → `terraform plan` → `terraform apply` (only when you intend to create alerts)  
4. In Dynatrace UI: Settings → Anomaly detection / Metric events — search for `<App> Test MQ`  

Commands listed in `1.sh` — review before run (not executed here).

## Investigation

Source: your open `alerting_contactmanager_mq.tf` screenshots (failed/retry/inflight/unsent, critical 100 / warning 10). Repo path was not present on this Mac workspace, so files were generated as a drop-in pack.

## Result

MQ alerts for **billingcenter**, **claimcenter**, and **policycenter** (test) mirror ContactManager. Other sidebar apps need a metric check first.

## Data flow map

```
guidewire.messaging.<metric>
  filter(eq(app,<code>))
  splitBy(queue.name, queue.id)
        │
        ▼
dynatrace_metric_events (Terraform)
  Critical ERROR  threshold 100 (3/10)
  Warning RESOURCE threshold 10 (10/10)
        │
        ▼
Dynatrace Problem / event → (optional) ServiceNow
```

## Related files

| File | Purpose |
| --- | --- |
| `1_generate_mq_alerts.py` | Regenerate all app TF |
| `applications/*/test/alerting_*_mq.tf` | Drop-in alerts |
| `1.sh` | Copy / plan reminders |

## Commands

See `1.sh`.
