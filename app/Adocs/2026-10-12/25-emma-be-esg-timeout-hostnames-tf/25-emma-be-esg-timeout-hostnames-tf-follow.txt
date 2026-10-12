# Emma BE ESG Timeout Host Names

## Decision tree

```
Splunk: two searches joined with append, last 5 min, more than 20, throttle 60 s
 Part A (myaxabackend) → host names all start with "myaxabackend-"
   filter → startsWith(host.name) or startsWith(k8s.pod.name)
   plus content → api-jp-cert.corp.intraxa + java.net.SocketTimeoutException
 Part B (API gateway syslog) → no host shown
   filter → content only: Problem routing to + timed out + myaxa-api.alj.intraxa
 append → one filter with "or"
 more than 20 → summarize count() → filter timeouts > 20
 throttle 60 s → identity scope → one open problem
 High + PagerDuty → high, pagerduty.enabled 1
 check query 1 empty? → pod names stored in another field → adjust
 check query 4 never above 20? → threshold may be too high
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it catch? | More than 20 Emma BE to ESG timeouts in 5 minutes. |
| Host names used | Any host or pod name starting with `myaxabackend-`. |
| Why prefix, not exact names? | The 17 names are Kubernetes pods. They change on every deployment. |
| Gateway part | Kept, filtered on content only. |
| Severity | high, PagerDuty on. |

## Summary

The backend host names in Splunk are pod names like `myaxabackend-664dc8cb6c-kw6vl`. Pods get new names each time they restart or deploy, so the detector matches the stable prefix `myaxabackend-`. The two Splunk searches become one query joined with `or`, then counted, and the alert fires above 20 in 5 minutes.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Emma BE | The Emma backend service, running as `myaxabackend` pods on OpenPaaS. | It makes the calls that time out. |
| ESG (CoreIT) | The enterprise service gateway Emma BE calls. | The target that is too slow. |
| Pod | One running copy of an app in Kubernetes. Its name is the app name plus random letters. | Names change, so match the prefix. |
| `SocketTimeoutException` | Java error when a network call waits too long for an answer. | The backend side of the timeout. |
| `append` | Splunk command that adds the results of a second search to the first. | Both parts count toward the 20. |
| `countIf` | DQL count of only the rows that match a condition. | Shows how many timeouts came from each part. |
| Throttle | Splunk quiet period after firing, here 60 seconds. | Dynatrace uses an identity field instead. |

### Host names from Splunk

| Host (top values) | Count |
|---|---|
| myaxabackend-664dc8cb6c-kw6vl | 22 |
| myaxabackend-664dc8cb6c-klqfd | 19 |
| myaxabackend-67dcbd8f47-hdn5n | 18 |
| myaxabackend-664dc8cb6c-lcnvj | 15 |
| myaxabackend-67dcbd8f47-d9gfc | 14 |
| myaxabackend-cf49f98d5-r7p7k | 14 |
| myaxabackend-cf49f98d5-7lg7x | 12 |
| myaxabackend-664dc8cb6c-4f1jf | 10 |
| myaxabackend-664dc8cb6c-nxpzf | 8 |
| myaxabackend-546bcfc7b6-68f2v | 4 |

There are 17 values in total, all starting with `myaxabackend-`. The middle part (for example `664dc8cb6c`) changes with each deployment.

### Splunk to Dynatrace

| Splunk setting | Dynatrace form |
|---|---|
| `index="myaxabackend-prod-axa-li-jp"` | `startsWith(host.name, "myaxabackend-") or startsWith(k8s.pod.name, "myaxabackend-")` |
| `api-jp-cert.corp.intraxa AND "java.net.SocketTimeoutException"` | Two `contains` checks on `content`. |
| `append [search index="apigw_syslog" ...]` | Second group joined with `or`. |
| `"Problem routing to" AND "timed out" AND "myaxa-api.alj.intraxa"` | Three `contains` checks on `content`. |
| Last 5 minutes, cron every 5 minutes | `from:now()-5m`, detector runs every minute. |
| Number of results greater than 20 | `summarize timeouts = count()` then `filter timeouts > 20`. |
| Throttle, suppress 60 seconds | Identity `scope` keeps one open problem. |
| Severity High | `alert.severity = "high"` |
| PagerDuty | `pagerduty.enabled = "1"` |
| Send email | Workflow. No recipients copied. |

## Result

```hcl
resource "dynatrace_davis_anomaly_detectors" "emma_be_timeout_to_esg_production" {
  title       = "Prod_Life_Emma_EmmaBETmeoutToESGProduction_High"
  description = "Monitors the ESG calls from Emma BE (OpenPaaS) to ESG (CoreIT) for timeouts. Fires when more than 20 timeouts are logged in 5 minutes, counting myaxabackend pods and the API gateway together."
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
                contains(content, "Problem routing to", caseSensitive:false)
                and contains(content, "timed out", caseSensitive:false)
                and contains(content, "myaxa-api.alj.intraxa", caseSensitive:false)
              )
          | fieldsAdd part = if(contains(content, "Problem routing to", caseSensitive:false), "apigw", else:"myaxabackend")
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
        value = "More than 20 timeouts in 5 minutes on calls from Emma BE (myaxabackend pods on OpenPaaS) to ESG (CoreIT). See timeouts, backend_timeouts, apigw_timeouts, hosts and sample on the problem."
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
| Check query 1 | Shows whether the pod names sit in `host.name` or `k8s.pod.name`. Once you know, you can drop the other half of the `or`. |
| Check query 2 | Backend timeouts per pod over 30 days. |
| Check query 3 | Shows which host and source the gateway lines come from. If you want, add that host as a filter too. |
| Check query 4 | Busiest 5 minute windows. Splunk shows 152 events in a month, so more than 20 in 5 minutes may be rare. Make sure the threshold matches what the team wants. |
| Name typo | The title says `TmeoutTo`. Kept as is so it matches the Splunk alert. |

## Data flow map

```
Emma BE pods (myaxabackend-*) on OpenPaaS
  → call ESG (CoreIT) via api-jp-cert.corp.intraxa
  → slow answer → java.net.SocketTimeoutException in pod logs
  → API gateway also logs "Problem routing to ... timed out" (myaxa-api.alj.intraxa)
  → both reach Dynatrace Grail logs
  → detector every minute, last 5 min
       count backend + gateway timeouts
       more than 20 → problem (high), one open problem (scope)
  → workflow: pagerduty.enabled = "1" → PagerDuty + email
  → back to 20 or fewer → problem closes
```

## Related files

| File | What it holds |
|---|---|
| `25-emma-be-esg-timeout-hostnames-tf.tf` | Full Terraform. |
| `25-emma-be-esg-timeout-hostnames-tf-check.dql` | Four check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What was checked. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `25.sh` | Commands, one per line. |

## Commands

All commands are in [`25.sh`](./25.sh). Nothing was run.

```bash
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-12/25-emma-be-esg-timeout-hostnames-tf"
terraform init
terraform validate
terraform plan
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/25-emma-be-esg-timeout-hostnames-tf
git commit -m "Emma BE ESG timeout detector scoped to myaxabackend host names"
git push
```
