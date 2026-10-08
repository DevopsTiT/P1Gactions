# EIP MQ And AGPO Auth0 Alerts

## Decision tree

```
2 Splunk alerts → 1 tf, for_each, 2 Records detectors
 ALERT-EIP-MQ-CONN-TIMEOUT
  index=mq, host wpalja21b*, "Connection timed out"
  every 1 min, last 1 min, > 0, email only
   → from:now()-2m (late-arrival buffer), any row → problem, medium, pagerduty "0"
 AGPO-Auth0-Password-SyncError
  sourcetype agportalapi, host agpo-cloud-authorization-process-api-* (Kubernetes pods)
  "IamCChangePasswordBadRequestResponse" OR "IamCChangePasswordNotFoundResponse"
  every 5 min, last 5 min, > 1 (so 2 or more), PagerDuty
   → summarize count, filter count > 1, high, pagerduty "1"
 Both: Trigger Once → identity check → 1 problem per detector
```

## Short takeaway

| Question | Answer |
|---|---|
| How many detectors? | 2, in one resource with `for_each` |
| MQ alert fires when | Any "Connection timed out" line from the wpalja21b MQ hosts in the last 2 minutes |
| AGPO alert fires when | 2 or more password-change errors in the last 5 minutes |
| MQ severity and PagerDuty | medium, `"0"` (email only, priority Normal) |
| AGPO severity and PagerDuty | high, `"1"` (Splunk action is PagerDuty) |
| PagerDuty key from screenshot | Not copied |
| Email recipients | Not copied; route by `app.name` |

## Summary

The MQ alert watches the IBM MQ error log on the wpalja21b servers for connection timeouts between EIP and MQ. The AGPO alert watches the Auth0 password sync in the AGPO authorization pods and pages when two or more change-password errors happen within 5 minutes. Both become Records detectors with no `makeTimeseries`.

## Alert 1: ALERT-EIP-MQ-CONN-TIMEOUT

| Splunk part | What it means | DQL |
|---|---|---|
| `index=mq` | MQ log index | Not needed |
| `host="wpalja21b*.prprivmgmt.intraxa"` | MQ servers such as WPALJA21B7 | `matchesValue(host.name, "wpalja21b*")` (case-insensitive) |
| `*Connection timed out*` | Network timeout text in the MQ error log | `contains(content, "Connection timed out", caseSensitive:false)` |
| Last 1 minute, every minute | Near real-time | `from:now()-2m`, detector runs every minute |
| Results > 0, Once | Any line, one email | Any row, identity `check` |
| Email infra list, Normal | Email only | severity medium, pagerduty `"0"` |

The search screenshot shows the log file is `/var/mqm/qmgrs/MQSRVPROD/errors/AMQERR01.LOG` (queue manager MQSRVPROD), with channel start messages like AMQ9002I and AMQ9299I.

## Alert 2: AGPO-Auth0-Password-SyncError

| Splunk part | What it means | DQL |
|---|---|---|
| `sourcetype="agportalapi-prod-axa-li-jp"` | AGPO portal API logs | Not needed; the pod filter is enough |
| `host="agpo-cloud-authorization-process-api-*"` | AGPO authorization pods | `startsWith(host.name, ...) or startsWith(k8s.pod.name, ...)` |
| `"IamCChangePasswordBadRequestResponse" OR "IamCChangePasswordNotFoundResponse"` | Auth0 rejected a password change (bad request or user not found) | Two `contains` joined with `or` |
| Last 5 minutes, every 5 minutes | Short window | `from:now()-5m` |
| Results > 1 | 2 or more errors | `summarize count = count()` then `filter count > 1` |
| Throttle 5 seconds | Has no real effect with a 5-minute schedule | Not needed; one problem stays open |
| PagerDuty action | Pages on-call | severity high, pagerduty `"1"` |

Splunk OR binds tighter than the implied AND, so the search means "sourcetype AND host AND (BadRequest OR NotFound)". The DQL keeps that grouping.

## Terraform

File: `6-eip-mq-agpo-auth0-two-alerts-tf.tf`

```hcl
locals {
  alerts = {
    eip_mq_conn_timeout = {
      title     = "ALERT-EIP-MQ-CONN-TIMEOUT"
      severity  = "medium"
      pagerduty = "0"
      app       = "EIP"
      query     = <<-EOT
        fetch logs, from:now()-2m
        | filter matchesValue(host.name, "wpalja21b*")
        | filter contains(content, "Connection timed out", caseSensitive:false)
        | fields timestamp, host.name, log.source, content
        | fieldsAdd check = "eip_mq_conn_timeout"
      EOT
    }
    agpo_auth0_password_sync_error = {
      title     = "AGPO-Auth0-Password-SyncError"
      severity  = "high"
      pagerduty = "1"
      app       = "AGPO"
      query     = <<-EOT
        fetch logs, from:now()-5m
        | filter startsWith(host.name, "agpo-cloud-authorization-process-api-") or startsWith(k8s.pod.name, "agpo-cloud-authorization-process-api-")
        | filter contains(content, "IamCChangePasswordBadRequestResponse", caseSensitive:false)
              or contains(content, "IamCChangePasswordNotFoundResponse", caseSensitive:false)
        | summarize count = count()
        | filter count > 1
        | fieldsAdd check = "agpo_auth0_password_sync_error"
      EOT
    }
  }
}

resource "dynatrace_davis_anomaly_detectors" "eip_agpo_alerts" {
  for_each = local.alerts
  # Records analyzer, identity check, event_template with title, severity, app.name, pagerduty.enabled
}
```

The full file has the provider, descriptions, and the complete resource body.

## Data flow

```
WPALJA21B* MQ error log (AMQERR01.LOG) → OneAgent → Grail
 → eip_mq_conn_timeout (2 min) → "Connection timed out" → medium problem → email

AGPO auth pods → S3 log forwarder → Dynatrace → Grail
 → agpo_auth0_password_sync_error (5 min) → count > 1 → high problem → PagerDuty
```

## Investigation

| Screenshot | Finding |
|---|---|
| 1 (MQ Edit Alert) | Search, `*/1`, Last 1 minute, > 0, Once, no throttle, email infra list, Normal |
| 2 (AGPO Edit Alert) | Search, `*/5`, Last 5 minutes, > 1, Once, throttle 5 seconds, PagerDuty action with integration key (not copied) |
| 3 (MQ search) | 280 events in a day; host WPALJA21B7; file `/var/mqm/qmgrs/MQSRVPROD/errors/AMQERR01.LOG`; sourcetype mq-batch |
| 4 (AGPO search) | 1.5 million events; host names are pod names like `agpo-cloud-authorization-process-api-6c995df884-...`; source is an S3 log forwarder |

## Result

| Step | What to do |
|---|---|
| 1 | Run check query 1: confirm the MQ host and file reach Dynatrace |
| 2 | Run check query 2: keep only `host.name` or `k8s.pod.name` for the AGPO pods |
| 3 | Run check query 4: see how often AGPO has 2 or more errors in 5 minutes |
| 4 | `terraform plan` should show 2 detectors to add |

## Related files

| File | Purpose |
|---|---|
| `6-eip-mq-agpo-auth0-two-alerts-tf.tf` | Both detectors |
| `6-eip-mq-agpo-auth0-two-alerts-tf-check.dql` | Check queries |
| `6.sh` | Commands |

## Commands

See `6.sh`.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/6-eip-mq-agpo-auth0-two-alerts-tf"
terraform init
terraform validate
terraform plan
```
