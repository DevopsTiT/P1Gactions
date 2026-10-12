# eopt Pod Error Backend Host Name Alert

## Decision tree

```
Assume eopt logs are in Dynatrace, host.name = pod name (same as Splunk host)
 index eopt-prod-axa-li-jp → 12 hosts, 3 services
   eoptsystemapi-* → keep
   eoptprocessapi-* → keep
   eoptfrontend-* → keep (Splunk search covers the whole index)
 rex timestamp + level → parse "NSPACE:log_ts SPACE+ ALPHA:level"
 search level="ERROR" → filter level == "ERROR"
 every hour → from:now()-1h
 > 0 → any line → problem per service (medium)
 email Normal → PagerDuty 0
 want backend only? → delete the eoptfrontend- line
```

## Short takeaway

| Question | Answer |
|---|---|
| Assumption | eopt logs are in Dynatrace and `host.name` holds the pod name, like the Splunk host field. |
| Scope | Host names starting with `eoptsystemapi-`, `eoptprocessapi-` or `eoptfrontend-`. |
| Why all three? | The Splunk search uses the whole index, which includes the frontend pods. |
| Condition | Any line whose level is ERROR in the last hour. |
| Identity | `service`, one problem per service. |
| Severity | medium, PagerDuty off. |

## Summary

This is a straight translation of the Splunk alert, written as if the eopt logs were already in Dynatrace. The index becomes a host name prefix filter, the `rex` becomes a `parse`, and the ERROR check stays the same. Pod names change on every deploy, so only the prefix is used.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Pod | One running copy of an app in Kubernetes. | Its name is the host name here. |
| Prefix | The fixed start of the pod name, such as `eoptsystemapi-`. | Stays the same across deploys. |
| `parse` | DQL command that pulls fields out of text. | Reads the timestamp and level. |
| Identity field | Field deciding one problem or many. | One problem per service. |

### Hosts from Splunk

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
| eoptfrontend-688699b58f-flt22 | 4,288 | eoptfrontend |
| eoptfrontend-688699b58f-ktnn9 | 3,767 | eoptfrontend |

There are 12 hosts in total, 293,715 events in about 24 hours.

### Splunk to Dynatrace

| Splunk setting | Dynatrace form |
|---|---|
| `index="eopt-prod-axa-li-jp"` | `host.name` starts with one of the three prefixes. |
| `rex "^(?<timestamp>...Z)\s+(?<level>[A-Z]+)"` | `parse content, "NSPACE:log_ts SPACE+ ALPHA:level"` plus a check that `log_ts` contains `T` and ends with `Z`. |
| `eval level=upper(level)` | Not needed. The regex only accepts capital letters. |
| `search level="ERROR"` | `filter level == "ERROR"` |
| Run every hour at minute 0 | `from:now()-1h`. The detector runs every minute. |
| Expires 24 hours | Dropped. |
| Results greater than 0 | Detector default. |
| Throttle off | Identity `service`. |
| Send email, Normal | `alert.severity = "medium"`, `pagerduty.enabled = "0"`. Workflow sends email. Recipients not copied. |
| Subject `Splunk Alert: $name$` | Dropped. Splunk token. |
| Description Optional | Replaced with a real description. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "eopt_openpaas_pod_error_backend" {
  title       = "eopt - OpenPaaS Pod Error (Backend)"
  description = "An eopt pod on OpenPaaS (eoptsystemapi, eoptprocessapi or eoptfrontend) logged a line with level ERROR in the last hour."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-1h
          | filter startsWith(host.name, "eoptsystemapi-")
              or startsWith(host.name, "eoptprocessapi-")
              or startsWith(host.name, "eoptfrontend-")
          | parse content, "NSPACE:log_ts SPACE+ ALPHA:level"
          | filter level == "ERROR"
          | filter endsWith(log_ts, "Z") and contains(log_ts, "T")
          | fieldsAdd service = if(startsWith(host.name, "eoptsystemapi-"), "eoptsystemapi",
                                else: if(startsWith(host.name, "eoptprocessapi-"), "eoptprocessapi",
                                else: "eoptfrontend"))
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
        value = "eopt service {service} logged level ERROR in the last hour. See host.name (pod) and the matching log lines (content) on the problem."
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

### Options

| Option | How |
|---|---|
| Backend pods only | Delete the line `or startsWith(host.name, "eoptfrontend-")`. |
| Faster closing | Change `from:now()-1h` to `from:now()-15m`. |
| Logs arrive through the forwarder instead | Use answer 30, which filters on `k8s.namespace.name` and `k8s.pod.name`. |

Same resource name as answers 27 and 30. Apply only one of them.

## Data flow map

```
eopt pods on OpenPaaS
  eoptsystemapi-*  ─┐
  eoptprocessapi-* ─┤ "2026-...Z ERROR ..."
  eoptfrontend-*   ─┘
  → Dynatrace Grail logs (host.name = pod name)
  → detector every minute, last 1 h
       parse level → ERROR → one problem per service (medium)
  → workflow: pagerduty.enabled = "0" → email
  → no ERROR for 1 h → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `31-eopt-pod-error-backend-hostname-tf.tf` | Full Terraform. |
| `31-eopt-pod-error-backend-hostname-tf-check.dql` | Three check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `31.sh` | Commands, one per line. |

## Commands

All commands are in [`31.sh`](./31.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/31-eopt-pod-error-backend-hostname-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/31-eopt-pod-error-backend-hostname-tf
git commit -m "eopt pod error detector on host names"
git push
```
