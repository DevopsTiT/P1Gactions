# eopt Log Paths In Detail

## Decision tree

```
eopt pod writes a log line (stdout)
 Path A: OpenShift collector → S3 bucket → Splunk          ✔ works today
 Path B: OneAgent inside the pod → metrics, traces, entity  ✔ works today, but no logs
 Path C: OpenShift collector → Dynatrace log forwarder      ✘ eopt not configured
 Fix options
   1. add eopt-prod-axa-li-jp to the Dynatrace forwarder (same as 11 sibling apps)  ← recommended
   2. enable Dynatrace Operator log monitoring for the namespace
 After fix
   check which fields carry the pod name → adjust alerts 31 and 34 if needed → test
```

## Short takeaway

| Question | Answer |
|---|---|
| Where do eopt logs start? | Each eopt container writes to stdout. OpenShift stores it as a file on the node. |
| Why does Splunk have them? | A collector picks up the files and ships them to an S3 bucket. Splunk reads that bucket. |
| Why does Dynatrace see eopt? | OneAgent is injected into the pods in App only mode. It sends metrics and traces and creates a host per pod. |
| Why no logs in Dynatrace? | App only OneAgent does not ship stdout logs, and eopt is not on the Dynatrace log forwarder. |
| What is needed? | Add eopt to the forwarder path that 11 other namespaces already use. |

## Summary

One eopt log line can travel three roads. The Splunk road works. The OneAgent road works but carries no logs. The Dynatrace log road exists for other apps but eopt was never added. Adding eopt to that road makes the logs land in Grail, and the alerts start working.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Pod | The smallest running unit in OpenShift. One eopt pod runs one app container. | Logs start here. |
| stdout | The normal output of a program. In containers, logs are written here. | Collectors read stdout, not files inside the app. |
| Node | The server that runs pods. | stdout ends up as a file on the node under `/var/log/pods/`. |
| Collector | A program on every node (Vector or Fluentd in OpenShift Logging) that reads pod log files. | It is the first hop of every log road. |
| ClusterLogForwarder | OpenShift setting that says which namespaces go to which destination. | eopt must be listed here for the Dynatrace road. |
| S3 bucket | Amazon storage for files. | Splunk's road goes through it. |
| OneAgent App only | Dynatrace agent injected into each pod, watching only that app. | Gives metrics and traces, not stdout logs. |
| Log ingest API | Dynatrace endpoint `/api/v2/logs/ingest` that accepts log lines. | The Dynatrace log road ends here. |
| OpenPipeline | Dynatrace processing step that every log passes before storage. | Sets `dt.openpipeline.source`. |
| Grail | Dynatrace's data store. `fetch logs` reads from it. | No line in Grail means no alert. |

### Confirmed and inferred

| Item | Status | Evidence |
|---|---|---|
| eopt pods run in namespace eopt-prod-axa-li-jp on OpenShift | Confirmed | Host page and earlier checks |
| Splunk receives eopt logs from S3 path axa-li-jp-logforwarders-prod | Confirmed | Splunk source field |
| 15 eopt hosts exist in Dynatrace, App only, OpenShift | Confirmed | Entity query and host page |
| 0 eopt log lines in Dynatrace for 24 hours | Confirmed | Four queries, 154 to 465 GiB scanned |
| 11 namespaces arrive through multilogforwarder-log-handler-dynatrace | Confirmed | Namespace query |
| The collector is OpenShift Logging (Vector or Fluentd) with a ClusterLogForwarder | Inferred | Name "multilogforwarder" matches the OpenShift multi forwarder feature |
| Splunk reads S3 with the Splunk Add-on for AWS | Inferred | Typical setup for an S3 log path |
| "log-handler-dynatrace" is a small service that adds the Dynatrace token and calls the ingest API | Inferred | Name and `/api/v2/logs/ingest` as the source |

## Path A: Splunk (works)

```
eopt container
  → stdout
  → node file /var/log/pods/eopt-prod-axa-li-jp_<pod>_<uid>/<container>/0.log
  → collector on the node reads the file
  → ClusterLogForwarder output for S3
  → S3 bucket axa-li-jp-logforwarders-prod
  → Splunk input reads new objects
  → Splunk index → your Splunk eopt alerts
```

| Hop | What happens | What can break |
|---|---|---|
| Container to stdout | App prints a line such as `2026-10-12T14:00:01Z ERROR ...`. | App logs to a file inside the container instead. Then no collector sees it. |
| stdout to node file | OpenShift (CRI-O) writes every line to a file on the node. | Log rotation on a very busy pod can drop lines. |
| Node file to collector | The collector tails the file and adds k8s labels (namespace, pod, container). | Collector pod down on that node. |
| Collector to S3 | Lines are batched into objects in the bucket. | Bucket permission or network issues. |
| S3 to Splunk | Splunk picks up new objects and indexes them. | Delay of minutes is normal. |

## Path B: OneAgent App only (works, but no logs)

```
eopt pod starts
  → Dynatrace Operator injects OneAgent code modules into the app process
  → OneAgent sends: process metrics, service calls (traces), errors seen in code
  → Dynatrace creates a "host" per pod, named after the pod (eoptsystemapi-564c45bd9f-jqqtl)
  → you see the host page ✔
  → stdout log lines are NOT sent ✘
```

| Point | Why it matters |
|---|---|
| App only means OneAgent lives inside the app process, not on the node. | It cannot read node files like `/var/log/pods/...`. |
| Each pod shows up as a host. | This is why you saw host pages named like pods, and why `host.name` looked like the right filter. |
| Log capture needs a node level agent or the Operator's log module. | Neither is set up for eopt, so this road has no logs. |

## Path C: Dynatrace log forwarder (exists, eopt missing)

```
sibling app container (for example capportalsystemapi)
  → stdout → node file → collector
  → ClusterLogForwarder "multilogforwarder" pipeline includes the namespace
  → output: log-handler-dynatrace
  → POST https://<tenant>/api/v2/logs/ingest  (with a logs.ingest token)
  → OpenPipeline (dt.openpipeline.source = /api/v2/logs/ingest)
  → Grail logs (log.source = multilogforwarder-log-handler-dynatrace,
               k8s.namespace.name = capportalsystemapi-prod-axa-li-jp)
  → fetch logs finds them ✔

eopt container
  → stdout → node file → collector
  → ClusterLogForwarder pipeline does NOT include eopt-prod-axa-li-jp
  → line goes only to the S3 output
  → nothing reaches Dynatrace ✘
```

| Hop | Sibling apps | eopt |
|---|---|---|
| stdout and node file | Yes | Yes |
| Collector reads it | Yes | Yes (Splunk gets it, so the collector works) |
| Namespace in the Dynatrace pipeline | Yes | No |
| Ingest API call | Yes | No |
| Lines in Grail | Yes | 0 |

This table is the core finding. Everything up to the collector already works for eopt. Only the last setting is missing.

## Result

### Needed path

```
eopt container → stdout → node file → collector
  → ClusterLogForwarder: add input eopt-prod-axa-li-jp to the Dynatrace pipeline
  → log-handler-dynatrace → /api/v2/logs/ingest
  → OpenPipeline → Grail
  → fetch logs ... eopt → rows
  → alert 31 (backend, rex style ERROR) and alert 34 (frontend, JSON level ERROR) run every minute
  → problem → workflow → email
```

### Fix options

| Option | What changes | Good | Watch out |
|---|---|---|---|
| 1. Add eopt to the forwarder | One input and pipeline entry in the ClusterLogForwarder. See the example YAML. | Same path as 11 siblings. Splunk road untouched. | Platform team owns it. Needs a change request. |
| 2. Dynatrace Operator log monitoring | Turn on the Operator's log module for the cluster or namespace. | Logs linked to the pod host entity automatically. | Bigger change. Affects licensing and the whole cluster. |

Option 1 is recommended because it copies a working pattern.

### After the fix

| Step | Why |
|---|---|
| Run `filter k8s.namespace.name == "eopt-prod-axa-li-jp"` | Confirms lines arrive. |
| Look at `host.name` and `k8s.pod.name` on those lines | Forwarder logs may carry the pod name in `k8s.pod.name`, while `host.name` may be the node or empty. |
| If needed, change alerts 31 and 34 | Use `startsWith(k8s.pod.name, "eoptsystemapi-")` and the same for processapi and frontend. |
| Compare with Splunk for one day | Same error count in both means the alert is trustworthy. |
| Then switch off the Splunk eopt alerts | Only after the Dynatrace ones are proven. |

### Example forwarder change

See [`4-eopt-log-paths-detailed-clusterlogforwarder-example.yaml`](./4-eopt-log-paths-detailed-clusterlogforwarder-example.yaml). It is an example for the platform team, not something to apply. Their existing config, endpoint and secret names win.

```yaml
inputs:
  - name: eopt-prod
    application:
      namespaces:
        - eopt-prod-axa-li-jp
pipelines:
  - name: eopt-to-dynatrace
    inputRefs:
      - eopt-prod
    outputRefs:
      - log-handler-dynatrace
```

## Data flow map

```
                         ┌──────────────────────────────┐
eopt container ─stdout─► │ node file /var/log/pods/...  │
                         └──────────────┬───────────────┘
                                        │ collector (Vector / Fluentd)
                       ┌────────────────┴────────────────┐
                       ▼                                 ▼
          S3 output (configured)            Dynatrace output (NOT configured for eopt)
                       │                                 │
     S3 axa-li-jp-logforwarders-prod        log-handler-dynatrace
                       │                                 │
                    Splunk ✔                 /api/v2/logs/ingest → OpenPipeline → Grail
                                                         │
                                              fetch logs → alerts 31, 34

eopt process ─ OneAgent (App only) ─► metrics, traces, host per pod ✔   logs ✘
```

## Related files

| File | What it holds |
|---|---|
| `4-eopt-log-paths-detailed-clusterlogforwarder-example.yaml` | Example forwarder change for the platform team. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | Confirmed and inferred items. |
| `2-result.md` | Fix options and after-fix steps. |
| `3-glossary.md` | Words used. |
| `4.sh` | Git one-liners. |
| `Daily Files/2026-10-13/2-eopt-not-in-log-forwarder-confirmed/` | Evidence and request draft. |
| `Daily Files/2026-10-13/3-find-missing-app-logs-logic/` | The step by step logic. |

## Commands

Nothing here needs to be run by you except the Notebook checks. Git one-liners are in [`4.sh`](./4.sh). Nothing was run.

```bash
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-13/4-eopt-log-paths-detailed
git commit -m "eopt log paths in detail"
git push
```
