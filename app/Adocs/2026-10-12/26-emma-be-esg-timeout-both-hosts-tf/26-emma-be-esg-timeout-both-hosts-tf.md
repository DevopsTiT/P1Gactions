# Emma BE ESG Timeout Both Hosts

## Decision tree

```
Splunk append search → two parts
 Part A (backend) → hosts myaxabackend-* (pods) → startsWith "myaxabackend-"
 Part B (gateway) → index apigw_syslog
   1 host → EEAA2015.ppprivmgmt.intraxa → contains(host.name, "EEAA2015")
   1 source → /SYSLOG/APIGW/prod/local4.log → contains(log.source, ...)
 A or B → count → more than 20 in 5 min → problem high → PagerDuty + email
 gateway lines missing in Dynatrace? → check query 1 → syslog not ingested → fix first
```

## Short takeaway

| Question | Answer |
|---|---|
| What changed from answer 25? | The gateway part now also filters on host EEAA2015 and source local4.log. |
| Backend part | Unchanged: pod names starting with `myaxabackend-`. |
| Why add host and source? | `local4.log` holds all gateway traffic (315,104 lines in about a day). Locking it down keeps other systems' lines out. |
| Severity | high, PagerDuty on. |
| Replaces | Answer 25. Same resource name, apply one only. |

## Summary

The new screenshot shows the `apigw_syslog` index has exactly one host and one source. Both are now references for the gateway part, the same way the pod prefix is the reference for the backend part. The rest of the alert is unchanged.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| API gateway (apigw) | The Layer7 gateway that routes API calls between systems. | It logs "Problem routing to ... timed out". |
| `local4.log` | Syslog file for the "local4" channel, which the gateway writes to. | Reference 2 for the gateway part. |
| EEAA2015 | The server collecting the gateway syslog. | Reference 1 for the gateway part. |
| Pod prefix | The fixed start of Kubernetes pod names, `myaxabackend-`. | Reference for the backend part. |

### What the screenshot shows

| Fact | What it means |
|---|---|
| `index="apigw_syslog" sourcetype=apigw_syslog_prod` | The gateway half of the Splunk search. |
| host, 1 value | EEAA2015.ppprivmgmt.intraxa |
| source, 1 value | /SYSLOG/APIGW/prod/local4.log |
| 315,104 events from 10/11 5:00 PM to 10/12 5:34 PM | Very busy log. Mostly INFO traffic lines. |
| Lines start with `epago30100 SSG[...]` | SSG is the Layer7 gateway process. |

### Final filters

| Part | Host reference | Source reference | Content |
|---|---|---|---|
| Backend | host or pod starts with `myaxabackend-` | Not needed | `api-jp-cert.corp.intraxa` and `java.net.SocketTimeoutException` |
| Gateway | host contains `EEAA2015` | source contains `/SYSLOG/APIGW/prod/local4.log` | `Problem routing to` and `timed out` and `myaxa-api.alj.intraxa` |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "emma_be_timeout_to_esg_production" {
  title       = "Prod_Life_Emma_EmmaBETmeoutToESGProduction_High"
  description = "Monitors the ESG calls from Emma BE (OpenPaaS) to ESG (CoreIT) for timeouts. Fires when more than 20 timeouts are logged in 5 minutes, counting myaxabackend pods and the API gateway host EEAA2015 together."
  enabled     = true
  source      = "Davis Anomaly Detection"

  analyzer {
    name = "dt.statistics.anomaly_detection.RecordAnomalyDetectionAnalyzer"
    input {
      analyzer_input_field {
        key   = "query.expression"
        value = <<-EOT
          fetch logs, from:now()-5m
          | filter (
                (startsWith(host.name, "myaxabackend-") or startsWith(k8s.pod.name, "myaxabackend-"))
                and contains(content, "api-jp-cert.corp.intraxa", caseSensitive:false)
                and contains(content, "java.net.SocketTimeoutException", caseSensitive:false)
              ) or (
                contains(host.name, "EEAA2015", caseSensitive:false)
                and contains(log.source, "/SYSLOG/APIGW/prod/local4.log", caseSensitive:false)
                and contains(content, "Problem routing to", caseSensitive:false)
                and contains(content, "timed out", caseSensitive:false)
                and contains(content, "myaxa-api.alj.intraxa", caseSensitive:false)
              )
          | fieldsAdd part = if(contains(host.name, "EEAA2015", caseSensitive:false), "apigw", else:"myaxabackend")
          | summarize timeouts = count(),
                      backend_timeouts = countIf(part == "myaxabackend"),
                      apigw_timeouts = countIf(part == "apigw"),
                      hosts = collectDistinct(host.name),
                      sample = takeFirst(content)
          | filter timeouts > 20
          | fieldsAdd scope = "emma-be-to-esg-timeout"
        EOT
      }
      analyzer_input_field {
        key   = "alertIdentityFields[0]"
        value = "scope"
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
        value = "Emma BE timeout to ESG Production"
      }
      property {
        key   = "event.description"
        value = "More than 20 timeouts in 5 minutes on calls from Emma BE (myaxabackend pods on OpenPaaS) to ESG (CoreIT), counted from the pods and the API gateway host EEAA2015. See timeouts, backend_timeouts, apigw_timeouts, hosts and sample on the problem."
      }
      property {
        key   = "alert.severity"
        value = "high"
      }
      property {
        key   = "app.name"
        value = "emma"
      }
      property {
        key   = "pagerduty.enabled"
        value = "1"
      }
    }
  }

  execution_settings {}
}
```

### Things to check

| Check | Why |
|---|---|
| Check query 1 | Confirms EEAA2015 and local4.log exist in Dynatrace with the same names. The domain looks like `ppprivmgmt` on screen; the filter uses only `EEAA2015` so spelling does not matter. |
| Check query 2 | Shows where the pod names are stored. |
| Check query 3 | Gateway timeouts over 30 days. |
| Check query 4 | Busiest 5 minute windows. Confirms whether more than 20 is realistic. |

## Data flow map

```
Emma BE pods (myaxabackend-*) ── SocketTimeoutException ──┐
                                                           ├→ Dynatrace Grail logs
API gateway → syslog → EEAA2015                            │
   /SYSLOG/APIGW/prod/local4.log ── "Problem routing to    │
   ... timed out" (myaxa-api.alj.intraxa) ─────────────────┘
  → detector every minute, last 5 min, count both parts
       more than 20 → problem (high), one open problem
  → workflow: pagerduty.enabled = "1" → PagerDuty + email
  → 20 or fewer → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `26-emma-be-esg-timeout-both-hosts-tf.tf` | Full Terraform. |
| `26-emma-be-esg-timeout-both-hosts-tf-check.dql` | Four check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `26.sh` | Commands, one per line. |

## Commands

All commands are in [`26.sh`](./26.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/26-emma-be-esg-timeout-both-hosts-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/26-emma-be-esg-timeout-both-hosts-tf
git commit -m "Emma BE ESG timeout detector scoped to pod and gateway hosts"
git push
```
