# Why eopt Query Has No Result

## Decision tree

```
fetch logs | filter startsWith(host.name, "eoptsystemapi-") ... → 0 records
 1. wrong tenant? → scanned 3.36 GiB for 1 h (yesterday PRD scanned ~156 GiB for 1 h)
      → check you are in DT PRD, not DT STG → rerun
 2. logs not ingested? → yesterday: 15 eopt host entities, but 0 log lines for 24 h
      → OneAgent is "App only" on OpenShift → it does not ship pod logs
      → Splunk gets eopt logs from S3 (axa-li-jp-logforwarders-prod), not Dynatrace
      → fix: ask platform team to forward eopt logs to Dynatrace
 3. logs exist under other fields? → host.name on k8s logs is often the node
      → check k8s.pod.name / k8s.namespace.name / content
 4. case? → startsWith is case sensitive → check with lower()
```

## Short takeaway

| Question | Answer |
|---|---|
| Is the query wrong? | No. The syntax is fine. It returns 0 because there is nothing to match. |
| Main reason | eopt pod logs are not sent to Dynatrace. Only the hosts (as entities) are monitored. |
| Quick thing to check first | The scan was only 3.36 GiB. In PRD a 1 hour scan was about 156 GiB yesterday, so you may be in STG. |
| What fixes it? | eopt logs must be forwarded to Dynatrace (log ingest), then the query and alerts 31 and 34 work. |

## Summary

The host page you saw yesterday proves Dynatrace knows the eopt pods as hosts, but knowing a host is not the same as having its logs. OneAgent runs in "App only" mode on OpenShift, which collects metrics and traces but does not ship container logs, and Splunk gets eopt logs from an S3 forwarder that does not feed Dynatrace. Also, the small scan size hints this run may be in the STG tenant.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Host entity | Dynatrace's record that a host exists (from OneAgent). | Seeing the host page does not mean logs exist. |
| Log record | One log line stored in Grail. | `fetch logs` only searches these. |
| App only monitoring | OneAgent mode that watches applications inside a container, not the whole node. | It does not collect pod log files. |
| Log ingest | Sending log lines into Dynatrace (OneAgent, API, forwarder). | eopt has no ingest path into Dynatrace today. |
| Scanned bytes | How much log data the query read. | A tiny number for 1 hour means few logs in scope, often the wrong tenant. |
| Tenant | One Dynatrace environment (DT STG or DT PRD). | eopt production lives in PRD. |

### What the screenshot shows

| Item | Value |
|---|---|
| Query | `fetch logs, from:now()-1h \| filter startsWith(host.name, "eoptsystemapi-") or startsWith(host.name, "eoptprocessapi-")` |
| Result | 0 records |
| Timeframe | 2026-10-12 23:15 to 2026-10-13 00:15 |
| Scanned | 3.36 GiB |

### What we already found yesterday (answer 29)

| Check | Result |
|---|---|
| eopt host entities, 7 days | 15 hosts |
| Logs with host.name starting eopt, 24 hours | 0 records (149.72 GiB scanned) |
| Logs linked to eopt host entities, 1 hour | 0 records (156.23 GiB scanned) |
| Logs for eoptsystemapi-564c45bd9f-jqqtl, 1 hour | 0 records |
| Host monitoring mode | App only, OpenShift |
| Where Splunk gets eopt logs | S3 path axa-li-jp-logforwarders-prod |

### Why each reason fits

| Reason | Evidence | How to confirm |
|---|---|---|
| Logs not ingested | 0 lines for 24 h across 150 GiB yesterday. | Check query 2 returns 0 for every eopt field. |
| Wrong tenant | 3.36 GiB for 1 h, about 50 times smaller than yesterday. | Check the tenant in the URL or the bookmark (DT PRD), then rerun check query 1. |
| Different field | k8s logs often put the node name in host.name. | Check query 2 searches k8s.pod.name, k8s.namespace.name and content. |
| Case | `startsWith` is case sensitive. | Check query 3 uses lower(). |

## Result

| Step | What to do |
|---|---|
| 1 | Make sure the notebook is in DT PRD. Rerun the same query. |
| 2 | Run check query 1. If total scan is large and eopt is 0, the tenant is right. |
| 3 | Run check query 2. If 0, eopt logs are not in Dynatrace. |
| 4 | Ask the platform team to forward eopt logs (namespace eopt-prod-axa-li-jp) to Dynatrace, like the other OpenPaaS apps that use multilogforwarder-log-handler-dynatrace. |
| 5 | After logs arrive, rerun. Alerts 31 (backend) and 34 (frontend) from 2026-10-12 then work as written. |

### Check queries

```
// 1. Is this the right tenant? How much log data is there at all in 1 h?
fetch logs, from:now()-1h
| summarize lines = count(), by:{ dt.openpipeline.source }
| sort lines desc

// 2. Any eopt log under any field? (pod name, namespace, host, content)
fetch logs, from:now()-24h
| filter contains(host.name, "eopt", caseSensitive:false)
    or contains(k8s.pod.name, "eopt", caseSensitive:false)
    or contains(k8s.namespace.name, "eopt", caseSensitive:false)
    or contains(log.source, "eopt", caseSensitive:false)
| summarize lines = count(), by:{ host.name, k8s.namespace.name, log.source }

// 3. Case check on host.name
fetch logs, from:now()-24h
| filter startsWith(lower(host.name), "eopt")
| summarize lines = count(), by:{ host.name }

// 4. How other OpenPaaS apps arrive (the path eopt should use)
fetch logs, from:now()-1h
| filter log.source == "multilogforwarder-log-handler-dynatrace"
| summarize lines = count(), by:{ k8s.namespace.name }
| sort lines desc
```

## Data flow map

```
Today:
eopt pods (OpenShift) → stdout logs → S3 forwarder (axa-li-jp-logforwarders-prod) → Splunk ✔
eopt pods → OneAgent (App only) → metrics + traces + host entity → Dynatrace ✔
eopt pods → logs → Dynatrace ✘  (no path)

fetch logs ... eopt → 0 records

Needed:
eopt pods → multilogforwarder-log-handler-dynatrace → /api/v2/logs/ingest → Grail
          → fetch logs works → alerts 31 and 34 fire
```

## Related files

| File | What it holds |
|---|---|
| `1-eopt-query-no-result-why-check.dql` | The four check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | Evidence. |
| `2-result.md` | What to do. |
| `3-glossary.md` | Words used. |
| `1.sh` | Git one-liners. |
| `Daily Files/2026-10-12/29-eopt-hosts-exist-logs-missing/` | Yesterday's checks. |
| `Daily Files/2026-10-12/31-eopt-pod-error-backend-hostname-tf/` | Backend alert. |
| `Daily Files/2026-10-12/34-eopt-pod-error-frontend-all-hosts-tf/` | Frontend alert. |

## Commands

The checks are DQL (run in a Notebook). Git one-liners are in [`1.sh`](./1.sh). Nothing was run.

```bash
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-13/1-eopt-query-no-result-why
git commit -m "Why eopt query has no result"
git push
```
