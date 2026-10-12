# eopt Onboarding Flow Explained

## Decision tree

```
One log line is written by a pod
 Is its namespace in the Dynatrace forwarder pipeline?
   yes (11 sibling namespaces) → ingest API → Grail → fetch logs sees it ✔
   no  (eopt-prod-axa-li-jp)   → only S3 → Splunk ✔ → Grail 0 lines → alerts 31, 34 silent
 After onboarding (eopt added to the pipeline)
   line lands in Grail → alert query runs
     host.name holds the pod name? → yes → alerts fire as written
                                   → no  → switch filter to k8s.pod.name, then they fire
```

## Short takeaway

| Block | What it says |
|---|---|
| 11 namespaces | Their pods' logs go through the OpenShift forwarder into Dynatrace and are searchable. |
| eopt today | Its logs go only to Splunk through S3. Dynatrace gets nothing, so both eopt alerts can never fire. |
| After onboarding | Add eopt to the same forwarder. Lines land in Grail and the alerts start working. |
| Hidden catch | Alerts 31 and 34 filter on `host.name`. Forwarder logs may carry the pod name in `k8s.pod.name` instead. |

## Summary

The diagram compares two apps on the same OpenShift cluster. Both write logs the same way. The only difference is one forwarder setting that decides whether a namespace's logs are copied to Dynatrace. Following one line through each block shows exactly where eopt's line stops, and what changes after onboarding.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Namespace | A folder for one app's pods, for example `eopt-prod-axa-li-jp`. | The forwarder chooses logs by namespace. |
| OpenShift log forwarder | The cluster setting (ClusterLogForwarder) that copies pod logs to destinations. | It is the switch that is off for eopt. |
| Pipeline | One rule in the forwarder: these namespaces go to this destination. | eopt needs its own rule, or to be added to an existing one. |
| `/api/v2/logs/ingest` | Dynatrace's door for log lines sent over HTTPS. | Forwarded lines enter here. |
| Grail | Dynatrace's store. `fetch logs` and alerts read from here. | Zero lines in Grail means zero alerts. |
| Onboarding | Adding the namespace to the forwarder pipeline. | The one change needed. |

## Block 1: The 11 sibling namespaces (working)

Example: a capportalsystemapi pod prints an error.

```
2026-10-13T00:40:01.123Z ERROR c.a.c.PortalController - timeout calling backend
```

| Step | Where the line is | What it looks like |
|---|---|---|
| 1 | Container stdout | The raw text above. |
| 2 | Node file | `/var/log/pods/capportalsystemapi-prod-axa-li-jp_<pod>_<uid>/app/0.log` |
| 3 | Collector | Raw text plus labels: namespace, pod name, container name. |
| 4 | Forwarder pipeline | Namespace is on the list, so a copy goes to `log-handler-dynatrace`. |
| 5 | Ingest API | HTTPS POST to `/api/v2/logs/ingest` with a token that has the logs.ingest permission. |
| 6 | OpenPipeline | Dynatrace stamps where it came from. |
| 7 | Grail record | See the table below. |

Grail record (what `fetch logs` returns):

| Field | Value |
|---|---|
| `timestamp` | 2026-10-13T00:40:01.123Z |
| `content` | `2026-10-13T00:40:01.123Z ERROR c.a.c.PortalController - timeout calling backend` |
| `log.source` | multilogforwarder-log-handler-dynatrace |
| `dt.openpipeline.source` | /api/v2/logs/ingest |
| `k8s.namespace.name` | capportalsystemapi-prod-axa-li-jp |
| `k8s.pod.name` | Likely the pod name. Confirm with the check query. |
| `host.name` | Unknown. It may be the node, the pod or empty. Confirm with the check query. |

This is why your query `filter log.source == "multilogforwarder-log-handler-dynatrace"` listed 11 namespaces.

## Block 2: eopt today (not working in Dynatrace)

Example: an eoptsystemapi pod prints an error.

```
2026-10-13T00:40:02.456Z ERROR c.a.e.SystemApiService - ESG call failed
```

| Step | Where the line is | Result |
|---|---|---|
| 1 | Container stdout | Written. |
| 2 | Node file | Written. |
| 3 | Collector | Read and labelled. |
| 4a | Forwarder pipeline to S3 | Namespace is on the S3 rule. A copy goes to bucket `axa-li-jp-logforwarders-prod`. |
| 4b | Forwarder pipeline to Dynatrace | Namespace is not on the rule. No copy is made. |
| 5 | Splunk | Reads the S3 object. The event shows host `eoptsystemapi-...`. Splunk alerts work. ✔ |
| 6 | Dynatrace | Nothing arrives. ✘ |

What the eopt alerts see every minute:

| Alert | Query start | Rows | Problem |
|---|---|---|---|
| 31 Backend | `fetch logs, from:now()-1h \| filter startsWith(host.name, "eoptsystemapi-") or ...` | 0 | Never |
| 34 Frontend | Same filter, then JSON level check | 0 | Never |

The alerts are not broken. They have nothing to read. This is the dangerous part: a silent alert looks the same as a healthy app.

## Block 3: After onboarding

The platform team adds `eopt-prod-axa-li-jp` to the Dynatrace pipeline. Now step 4b makes a copy too.

Expected Grail record:

| Field | Value |
|---|---|
| `timestamp` | 2026-10-13T00:40:02.456Z |
| `content` | `2026-10-13T00:40:02.456Z ERROR c.a.e.SystemApiService - ESG call failed` |
| `log.source` | multilogforwarder-log-handler-dynatrace |
| `k8s.namespace.name` | eopt-prod-axa-li-jp |
| `k8s.pod.name` | eoptsystemapi-564c45bd9f-jqqtl (expected) |
| `host.name` | To be confirmed |

### How alert 31 (Backend) handles this line

| Query line | Result for this line |
|---|---|
| `fetch logs, from:now()-1h` | Line is in the last hour. Kept. |
| `filter startsWith(host.name, "eoptsystemapi-") or ...` | Kept only if `host.name` holds the pod name. |
| `parse content, "NSPACE:log_ts SPACE+ ALPHA:level"` | `log_ts` = 2026-10-13T00:40:02.456Z, `level` = ERROR |
| `filter level == "ERROR"` | Kept. |
| `filter endsWith(log_ts, "Z") and contains(log_ts, "T")` | Kept. It is a real timestamp line, not a stack trace line. |
| `fieldsAdd service = ...` | `service` = eoptsystemapi |
| Identity `service` | One problem for eoptsystemapi. |

### How alert 34 (Frontend) handles a JSON line

```
{"time":"2026-10-13T00:40:03Z","level":"error","msg":"render failed"}
```

| Query line | Result |
|---|---|
| Host filter | Same condition as alert 31. |
| `parse content, "JSON:j"` | Turns the text into a map. |
| `fieldsAdd level = upper(toString(j[level]))` | `level` = ERROR |
| `filter level == "ERROR"` | Kept. |
| `service` | eoptfrontend (or whichever prefix matched). |

The two alerts never fire on the same line. A plain text line fails the JSON parse, and a JSON line fails the timestamp pattern.

### Timeline after onboarding

| Time | What happens |
|---|---|
| 00:40:02 | Pod writes the error. |
| About 00:40:05 to 00:40:30 | Collector batches and sends it. Ingest takes seconds. |
| About 00:41 | Detector runs, sees the line, opens a problem. Workflow sends the email. |
| Until about 01:40 | Problem stays open, because the query looks back 1 hour. |
| About 01:41 (no new errors) | Line falls out of the 1 hour window. Problem closes. |

### The hidden catch: `host.name`

| Case | What happens | Fix |
|---|---|---|
| `host.name` = pod name | Alerts fire as written. | Nothing. |
| `host.name` = node name or empty | The host filter drops every line. Alerts stay silent even after onboarding. | Change the filter and `service` logic to `k8s.pod.name`. |

Filter that works for both cases:

```
| filter startsWith(k8s.pod.name, "eoptsystemapi-")
    or startsWith(k8s.pod.name, "eoptprocessapi-")
    or startsWith(k8s.pod.name, "eoptfrontend-")
    or startsWith(host.name, "eoptsystemapi-")
    or startsWith(host.name, "eoptprocessapi-")
    or startsWith(host.name, "eoptfrontend-")
| fieldsAdd pod = coalesce(k8s.pod.name, host.name)
| fieldsAdd service = if(startsWith(pod, "eoptsystemapi-"), "eoptsystemapi",
                      else: if(startsWith(pod, "eoptprocessapi-"), "eoptprocessapi",
                      else: "eoptfrontend"))
```

You can check this today on a sibling app with check query 1, before eopt is onboarded.

## Result

| Step | Owner | What |
|---|---|---|
| 1 | You | Send the onboarding request (answer 2). |
| 2 | You, today | Run check query 1 on capportalsystemapi to see which field holds the pod name. |
| 3 | Platform team | Add eopt-prod-axa-li-jp to the Dynatrace pipeline. |
| 4 | You | Run check query 2 to see eopt lines arrive. |
| 5 | You | If `host.name` is not the pod name, update alerts 31 and 34 with the filter above in a new answer folder. |
| 6 | You | Compare one day of Dynatrace problems with Splunk alerts, then retire the Splunk ones. |

### Check queries

```
// 1. Today, on a sibling app: which field holds the pod name?
fetch logs, from:now()-1h
| filter k8s.namespace.name == "capportalsystemapi-prod-axa-li-jp"
| fields timestamp, host.name, k8s.pod.name, k8s.node.name, log.source, content
| limit 10

// 2. After onboarding: are eopt lines arriving, and with which names?
fetch logs, from:now()-1h
| filter k8s.namespace.name == "eopt-prod-axa-li-jp"
| summarize lines = count(), by:{ host.name, k8s.pod.name }

// 3. After onboarding: would alert 31 match anything?
fetch logs, from:now()-1h
| filter k8s.namespace.name == "eopt-prod-axa-li-jp"
| parse content, "NSPACE:log_ts SPACE+ ALPHA:level"
| filter level == "ERROR"
| summarize errors = count(), by:{ host.name, k8s.pod.name }
```

## Data flow map

```
capportalsystemapi pod ── stdout ──► collector ──┬──► Dynatrace pipeline ✔ ──► /api/v2/logs/ingest ──► Grail ──► fetch logs ✔
                                                └──► (other outputs)

eopt pod ── stdout ──► collector ──┬──► S3 axa-li-jp-logforwarders-prod ──► Splunk ✔
                                  └──► Dynatrace pipeline ✘ (namespace not listed)
                                         Grail: 0 lines ──► alerts 31, 34: 0 rows, silent

After onboarding:
eopt pod ── stdout ──► collector ──┬──► S3 ──► Splunk ✔ (unchanged)
                                  └──► Dynatrace pipeline ✔ ──► ingest ──► Grail
                                         ──► alert 31 (text ERROR) ─┐
                                         ──► alert 34 (JSON ERROR) ─┴► problem per service ──► email
```

## Related files

| File | What it holds |
|---|---|
| `5-eopt-onboarding-flow-explained-check.dql` | Three check queries. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | One line followed through each block. |
| `2-result.md` | Steps and owners. |
| `3-glossary.md` | Words used. |
| `5.sh` | Git one-liners. |
| `Daily Files/2026-10-13/2-eopt-not-in-log-forwarder-confirmed/` | Request draft. |
| `Daily Files/2026-10-13/4-eopt-log-paths-detailed/` | All three log paths and example forwarder YAML. |
| `Daily Files/2026-10-12/31-eopt-pod-error-backend-hostname-tf/` | Alert 31. |
| `Daily Files/2026-10-12/34-eopt-pod-error-frontend-all-hosts-tf/` | Alert 34. |

## Commands

The checks are DQL. Git one-liners are in [`5.sh`](./5.sh). Nothing was run.

```bash
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-13/5-eopt-onboarding-flow-explained
git commit -m "eopt onboarding flow explained"
git push
```
