# eopt Pod Error Backend Hosts Only

## Decision tree

```
Backend alert → reference = backend hosts from Splunk
 eoptsystemapi-564c45bd9f-*  → keep
 eoptprocessapi-7d49b9558c-* → keep
 eoptfrontend-688699b58f-*   → out (Frontend alert, answer 32)
 line "2026-...Z ERROR ..." → parse timestamp + level → level == ERROR
 every hour → from:now()-1h → problem per service (medium) → email
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed from answer 31? | The `eoptfrontend-` line is removed. Only backend hosts are in scope. |
| Backend hosts | `eoptsystemapi-*` and `eoptprocessapi-*`, 10 of the 12 Splunk hosts. |
| Frontend | Covered by answer 32. |
| Severity | medium, PagerDuty off. |
| Apply | This one plus answer 32. Not answers 27, 30 or 31. |

## Summary

The Backend alert now uses only the backend hosts from the Splunk host list as its reference. The frontend has its own JSON-based alert, so the two do not overlap.

## Investigation

### Backend hosts from Splunk

| Host | Events | Service |
|---|---|---|
| eoptsystemapi-564c45bd9f-jqqtl | 73,241 | eoptsystemapi |
| eoptsystemapi-564c45bd9f-drgst | 47,833 | eoptsystemapi |
| eoptprocessapi-7d49b9558c-mg6x6 | 42,702 | eoptprocessapi |
| eoptprocessapi-7d49b9558c-5whpq | 34,675 | eoptprocessapi |
| eoptsystemapi-564c45bd9f-l6f4n | 26,801 | eoptsystemapi |
| eoptsystemapi-564c45bd9f-jm5qd | 21,883 | eoptsystemapi |
| eoptprocessapi-7d49b9558c-kdk88 | 18,464 | eoptprocessapi |
| eoptprocessapi-7d49b9558c-288n5 | 16,340 | eoptprocessapi |

The frontend hosts (eoptfrontend-688699b58f-flt22 and ktnn9) are left out.

### Sample backend line

```
2026-10-12T09:18:54.959Z DEBUG [ip: 10.94.240.2 | reqId: 869c4295-... | /api/actuator/...
```

The first word is the timestamp and the second is the level, which is what the parse reads.

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "eopt_openpaas_pod_error_backend" {
  title       = "eopt - OpenPaaS Pod Error (Backend)"
  description = "An eopt backend pod (eoptsystemapi or eoptprocessapi) on OpenPaaS logged a line with level ERROR in the last hour."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1h
          | filter startsWith(host.name, "eoptsystemapi-") or startsWith(host.name, "eoptprocessapi-")
          | parse content, "NSPACE:log_ts SPACE+ ALPHA:level"
          | filter level == "ERROR"
          | filter endsWith(log_ts, "Z") and contains(log_ts, "T")
          | fieldsAdd service = if(startsWith(host.name, "eoptsystemapi-"), "eoptsystemapi", else:"eoptprocessapi")
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "service"
      }
    }
  }

  event_template {
    properties {
      property {
        key   = "event.type"
        value = "CUSTOM_ALERT"
      }
      property {
        key   = "event.name"
        value = "eopt - OpenPaaS Pod Error (Backend): {service}"
      }
      property {
        key   = "event.description"
        value = "eopt backend service {service} logged level ERROR in the last hour. See host.name (pod) and the matching log lines (content) on the problem."
      }
      property {
        key   = "alert.severity"
        value = "medium"
      }
      property {
        key   = "app.name"
        value = "eopt"
      }
      property {
        key   = "pagerduty.enabled"
        value = "0"
      }
    }
  }

  execution_settings {}
}
```

### Which eopt files to apply

| Answer | Alert | Apply? |
|---|---|---|
| 27 | Backend, coalesce version | No |
| 30 | Backend, forwarder fields | Only if logs arrive through the forwarder instead |
| 31 | Backend plus frontend hosts | No |
| 32 | Frontend | Yes |
| 33 | Backend hosts only | Yes |

## Data flow map

```
eoptsystemapi-*  ─┐
eoptprocessapi-* ─┤ "2026-...Z ERROR ..." → Grail (host.name = pod)
                  → detector every minute, last 1 h, level ERROR
                  → problem per service (medium) → workflow → email
eoptfrontend-*   → answer 32 (JSON level)
```

## Related files

| File | What it holds |
|---|---|
| `33-eopt-pod-error-backend-hosts-only-tf.tf` | Full Terraform. |
| `33-eopt-pod-error-backend-hosts-only-tf-check.dql` | Three check queries. |
| `../32-eopt-pod-error-frontend-hostname-tf/32-eopt-pod-error-frontend-hostname-tf.tf` | Frontend pair. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `33.sh` | Commands, one per line. |

## Commands

All commands are in [`33.sh`](./33.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/33-eopt-pod-error-backend-hosts-only-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/33-eopt-pod-error-backend-hosts-only-tf
git commit -m "eopt backend pod error detector on backend host names"
git push
```
