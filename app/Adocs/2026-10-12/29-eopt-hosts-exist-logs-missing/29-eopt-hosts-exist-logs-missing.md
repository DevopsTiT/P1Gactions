# eopt Hosts Exist Logs Missing

## Decision tree

```
Query 1 (hosts) → 15 eopt hosts found → OneAgent sees the pods
Queries 2 to 6 (logs) → 0 records → no eopt log lines linked to those hosts
 why?
   App only OneAgent → usually does not collect container log files
   Splunk gets eopt logs from an S3 forwarder → not from OneAgent
 next check → queries A to E (search by text, k8s fields, S3 path)
   found under other fields → change detector filter to those fields
   found nowhere → logs not in Dynatrace
     fix → Dynatrace Operator log module, or forward the S3 logs to Dynatrace
     meanwhile → keep Splunk alert, or use trace-based failures (query F)
```

## Short takeaway

| Question | Answer |
|---|---|
| Are the eopt pods in Dynatrace? | Yes. 15 hosts: 5 eoptfrontend, 5 eoptprocessapi, 5 eoptsystemapi. |
| Are their logs in Dynatrace? | Not under `host.name` or `dt.entity.host`. All log queries returned 0. |
| Most likely reason | The pods use App only monitoring, and Splunk receives these logs through an S3 forwarder, not through OneAgent. |
| Does the answer 27 detector work today? | No. It would never fire, because there are no lines to match. |
| Next step | Run queries A to E to rule out other field names. |

## Summary

Dynatrace knows about all 15 eopt pods, but no log lines are attached to them. With App only monitoring, the agent watches the Java app, not the container's log output. In Splunk, the eopt lines arrive from an S3 log forwarder bucket. Unless that pipeline also feeds Dynatrace, the logs are simply not there, and the log detector cannot fire.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Host entity | Dynatrace's record of a monitored host. | Proves the agent is running in the pod. |
| Log record | One log line stored in Grail. | What the detector reads. Here there are none. |
| App only monitoring | The agent runs inside the app process. | It monitors requests and code, but usually not the container's log output. |
| Log module | Part of the Dynatrace Operator on Kubernetes that reads container logs from each node. | The usual way pod logs reach Dynatrace. |
| S3 log forwarder | A pipeline copying pod logs into an AWS S3 bucket, which Splunk reads. | Where Splunk's eopt logs come from. |
| Spans | Records of individual requests captured by the agent. | A fallback signal when logs are missing. |

### What your six checks showed

| Check | Result | What it means |
|---|---|---|
| Query 1: `fetch dt.entity.host`, 7 days | 15 records | All eopt pods are monitored hosts. |
| Query 2: logs, `host.name` starts with eopt, 24 hours | 0 records | No log line has an eopt host name. 149.72 GiB scanned, so the search was real. |
| Query 3: logs, `entityName(dt.entity.host)` | 0 records | No log line is linked to an eopt host ID either. |
| Query 4: logs for eoptsystemapi-564c45bd9f-jqqtl | 0 records | Even the exact pod has no logs. |
| Query 5: cost fields | 0 records | Same reason: no lines to group. |
| Query 6: level parse | 0 records | Nothing to parse. |

### Hosts found by query 1

| Service | Pods |
|---|---|
| eoptfrontend | 5 (dvt9r, flt22, ktnn9, l55mf, vvhrg) |
| eoptprocessapi | 5 (288n5, 5whpq, g6bq9, kdk88, mg6x6) |
| eoptsystemapi | 5 (drgst, jm5qd, jqqtl, l6f4n, nj8q4) |

## Result

### Step 1: rule out other field names

Run these in the Notebook. They are in `29-eopt-hosts-exist-logs-missing-check.dql`.

**A. Search every field for the pod name**

```
fetch logs, from:now()-1h
| search "eoptsystemapi"
| limit 20
```

**B. Search the line text for words seen in Splunk**

```
fetch logs, from:now()-1h
| filter contains(content, "LoggableDispatcherServlet") or contains(content, "eoptsystemapi") or contains(content, "eoptprocessapi")
| summarize lines = count(), by:{ host.name, k8s.pod.name, k8s.namespace.name, log.source, dt.openpipeline.source }
```

**C. Kubernetes fields**

```
fetch logs, from:now()-1h
| filter contains(k8s.pod.name, "eopt", caseSensitive:false)
    or contains(k8s.workload.name, "eopt", caseSensitive:false)
    or contains(k8s.namespace.name, "eopt", caseSensitive:false)
| summarize lines = count(), by:{ k8s.namespace.name, k8s.workload.name, k8s.pod.name }
```

**D. The S3 forwarder path**

```
fetch logs, from:now()-1h
| filter contains(log.source, "logforwarders", caseSensitive:false) or contains(log.source, "eopt", caseSensitive:false)
| summarize lines = count(), by:{ log.source }
| limit 50
```

**E. Which ingest sources exist at all**

```
fetch logs, from:now()-1h
| summarize lines = count(), by:{ dt.openpipeline.source }
| sort lines desc
```

### Step 2: decide

| Result | What to do |
|---|---|
| A, B, C or D returns eopt lines | Logs are there under other fields. Send a screenshot of the fields and I will rewrite the answer 27 filter to use them. |
| All return 0 | eopt logs are not in Dynatrace. Go to step 3. |

### Step 3: if the logs are not in Dynatrace

| Option | What it means | Who does it |
|---|---|---|
| Turn on the Kubernetes log module | The Dynatrace Operator on the OpenPaaS cluster reads pod logs and sends them to Grail. | Dynatrace or OpenPaaS platform team. |
| Forward the S3 logs to Dynatrace | The bucket `axa-li-jp-logforwarders-prod` that feeds Splunk also feeds Dynatrace. | Logging or AWS team. |
| Keep the Splunk alert for now | Do not switch off the Splunk alert until logs reach Dynatrace. | You. |
| Use a trace signal meanwhile | OneAgent already sees requests. Failed requests can stand in for ERROR logs. Check with query F. | You, with a different detector. |

**F. Trace fallback check**

```
fetch spans, from:now()-1h
| filter startsWith(host.name, "eopt")
| summarize spans = count(), failed = countIf(request.is_failed == true), by:{ host.name }
```

If F returns rows, the agent is capturing requests, and a failed-request alert is possible while log ingest is being sorted out.

### What to tell the platform team

> The 15 eopt pods (eoptsystemapi, eoptprocessapi, eoptfrontend) on OpenPaaS are monitored by OneAgent in App only mode, but none of their logs reach Dynatrace Grail. Splunk receives them through the S3 bucket axa-li-jp-logforwarders-prod. To migrate the "eopt - OpenPaaS Pod Error (Backend)" alert, we need these pod logs in Dynatrace, either through the Dynatrace Operator log module or by forwarding the S3 logs.

## Data flow map

```
TODAY
eopt pods (OpenShift)
  ├─ OneAgent App only → Dynatrace host entities (15) + traces ✔
  └─ stdout logs → S3 forwarder → Splunk ✔
                                 → Dynatrace Grail ✘ (0 records)

NEEDED
eopt pods → logs → Dynatrace Operator log module or S3 forward
  → Grail logs (host.name or k8s.pod.name)
  → answer 27 detector → problem → email
```

## Related files

| File | What it holds |
|---|---|
| `29-eopt-hosts-exist-logs-missing-check.dql` | Queries A to F. |
| `../27-eopt-openpaas-pod-error-backend-tf/27-eopt-openpaas-pod-error-backend-tf.tf` | The detector waiting on these logs. |
| `../28-check-eopt-pod-host-in-dynatrace/28-check-eopt-pod-host-in-dynatrace-check.dql` | The six checks you just ran. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | Check results. |
| `2-result.md` | Next steps. |
| `3-glossary.md` | Words used. |
| `29.sh` | Commands, one per line. |

## Commands

All commands are in [`29.sh`](./29.sh). Nothing was run. The checks run in a Dynatrace Notebook.

```bash
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/29-eopt-hosts-exist-logs-missing
git commit -m "eopt hosts exist in Dynatrace but logs are missing"
git push
```
