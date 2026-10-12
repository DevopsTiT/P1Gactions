# Find Missing App Logs Logic

## Decision tree

```
Query returns 0 records
 Step 1  Is the platform healthy? (any logs at all, right tenant)
           no  → wrong tenant / permissions → fix and rerun
           yes ↓
 Step 2  Does the app exist in Dynatrace? (host / process / k8s entity)
           no  → app not monitored at all → OneAgent / k8s onboarding
           yes ↓
 Step 3  Are its logs anywhere? (search every field, ignore case, 24 h)
           yes → logs exist under another field → fix the filter
           no  ↓
 Step 4  How do sibling apps get logs in? (dt.openpipeline.source, log.source)
           find the ingest path → list who is on it
 Step 5  Is the app on that path?
           no  → onboarding gap → request to platform team
           yes → path broken for this app → check forwarder errors
 Step 6  Where do the logs go today? (Splunk source)
           proves logs exist, just not routed to Dynatrace
```

## Short takeaway

| Question | Answer |
|---|---|
| Idea | Go from wide to narrow. Prove what exists before blaming the query. |
| Order | Platform, then entity, then any log, then ingest path, then membership. |
| Key trick | Search for the app name in every field with case ignored. Zero there means the logs are really absent. |
| Key comparison | Look at how a similar app gets its logs in, then check if your app is on the same path. |
| eopt result | Platform fine, hosts exist, zero logs, forwarder sends 11 namespaces, eopt not one of them. |

## Summary

When a log query returns nothing, there are only a few possible reasons: wrong place, wrong filter, or no data. The logic removes them one at a time, cheapest first. Each step has one query and one yes/no answer, so you always know the next step.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Entity | Something Dynatrace knows exists, such as a host or process. | An entity can exist without any logs. |
| Ingest path | The route a log line takes into Dynatrace. | If the app is not on a path, there are no logs. |
| `dt.openpipeline.source` | Field telling which door a log came through (oneagent, API, extension). | Shows all ingest paths in one query. |
| `log.source` | Field telling the file or sender of the log. | Shows which forwarder sent it. |
| Sibling app | A similar app on the same platform that already works. | Copy its setup to find what yours is missing. |

### Why this order

| Possible reason | How cheap to check | Step |
|---|---|---|
| Wrong tenant or no access | One query | 1 |
| App not monitored at all | One query | 2 |
| Logs exist, filter is wrong | One query | 3 |
| App not on the ingest path | Two queries | 4 and 5 |
| Logs only go elsewhere | Look at Splunk | 6 |

### Step by step with the eopt example

#### Step 1: Is the platform healthy?

Question: do I see lots of logs at all here?

```
fetch logs, from:now()-1h
| summarize lines = count(), by:{ dt.openpipeline.source }
| sort lines desc
```

| What you see | Meaning |
|---|---|
| Millions of lines, several sources | Right tenant, logs flowing. Go to step 2. |
| Few or none | Wrong tenant or no permission. Fix first. |

eopt: 7 sources, 65 million OneAgent lines, 134 GiB. Healthy, PRD.

#### Step 2: Does the app exist in Dynatrace?

Question: does Dynatrace know the app's hosts or pods?

```
fetch dt.entity.host, from:now()-7d
| filter startsWith(lower(entity.name), "eopt")
| fields entity.name, id
```

| What you see | Meaning |
|---|---|
| Hosts listed | App is monitored. Go to step 3. |
| Nothing | App not monitored. Ask for OneAgent or k8s onboarding. |

eopt: 15 hosts (App only monitoring on OpenShift). Exists.

#### Step 3: Are its logs anywhere?

Question: is the app name in any log field, ignoring case, for a whole day?

```
fetch logs, from:now()-24h
| filter contains(host.name, "eopt", caseSensitive:false)
    or contains(k8s.pod.name, "eopt", caseSensitive:false)
    or contains(k8s.namespace.name, "eopt", caseSensitive:false)
    or contains(log.source, "eopt", caseSensitive:false)
| summarize lines = count(), by:{ host.name, k8s.namespace.name, log.source }
```

| What you see | Meaning |
|---|---|
| Rows | Logs exist. Your alert filter uses the wrong field. Copy the field that matched. |
| 0 records | Logs are really not in Dynatrace. Go to step 4. |

eopt: 0 records over 154 GiB. Also 0 with `lower(host.name)`. Really absent.

#### Step 4: How do sibling apps get logs in?

Question: what path do similar apps use?

```
fetch logs, from:now()-1h
| filter dt.openpipeline.source == "/api/v2/logs/ingest"
| summarize lines = count(), by:{ log.source }
| sort lines desc
```

| What you see | Meaning |
|---|---|
| A forwarder name such as `multilogforwarder-log-handler-dynatrace` | That is the path for platform apps. Go to step 5. |

eopt: OpenPaaS apps arrive through `multilogforwarder-log-handler-dynatrace`.

#### Step 5: Is the app on that path?

Question: who is on the path, and is my app in the list?

```
fetch logs, from:now()-1h
| filter log.source == "multilogforwarder-log-handler-dynatrace"
| summarize lines = count(), by:{ k8s.namespace.name }
| sort lines desc
```

| What you see | Meaning |
|---|---|
| App namespace missing | Onboarding gap. Ask the platform team to add it. |
| App namespace present but 0 or low | Path broken for this app. Ask for forwarder error logs. |

eopt: 11 namespaces, `eopt-prod-axa-li-jp` missing. Onboarding gap.

#### Step 6: Where do the logs go today?

Question: do the logs exist somewhere else?

| Check | eopt result |
|---|---|
| Splunk source of eopt events | S3 path axa-li-jp-logforwarders-prod |

This proves the app writes logs. They are just not routed to Dynatrace.

## Result

### Conclusion chain for eopt

| Step | Question | Answer |
|---|---|---|
| 1 | Platform healthy? | Yes, PRD, 134 GiB per hour. |
| 2 | App exists? | Yes, 15 hosts. |
| 3 | Logs anywhere? | No, 0 in 24 hours under any field. |
| 4 | Sibling path? | multilogforwarder. |
| 5 | App on path? | No, not in the 11 namespaces. |
| 6 | Logs elsewhere? | Yes, Splunk through S3. |
| Verdict | | eopt is not onboarded to the Dynatrace log forwarder. |

### Reuse for any app

| Replace | With |
|---|---|
| `"eopt"` | Your app name or prefix. |
| `eopt-prod-axa-li-jp` | Your namespace. |
| `multilogforwarder-log-handler-dynatrace` | The path found in step 4. |

### Common mistakes

| Mistake | Why it misleads |
|---|---|
| Trusting the host page | A host entity does not mean logs exist. |
| Searching only `host.name` | Kubernetes logs often keep the pod name in `k8s.pod.name`. |
| Using a 1 hour window | A quiet app may log nothing in 1 hour. Use 24 hours for existence checks. |
| Reading scanned bytes as data size | Grail skips blocks the filter cannot match, so filtered queries scan less. |
| Matching Splunk text | Splunk hits on the app name can come from Splunk's own logs (license_usage.log), not the app. |

## Data flow map

```
0 records
  │
  ├─ Step 1 platform? ──no──► fix tenant / access
  │        yes
  ├─ Step 2 entity? ────no──► onboard monitoring
  │        yes
  ├─ Step 3 any log? ───yes─► fix filter field
  │        no
  ├─ Step 4 sibling path → multilogforwarder
  │
  ├─ Step 5 app on path? ─no──► request onboarding  ◄── eopt ends here
  │                       yes─► forwarder error for this app
  │
  └─ Step 6 Splunk source → proves logs exist elsewhere
```

## Related files

| File | What it holds |
|---|---|
| `3-find-missing-app-logs-logic-check.dql` | The six step queries in order. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | Steps and eopt evidence. |
| `2-result.md` | Conclusion chain. |
| `3-glossary.md` | Words used. |
| `3.sh` | Git one-liners. |
| `Daily Files/2026-10-13/2-eopt-not-in-log-forwarder-confirmed/` | Results and request draft. |

## Commands

The checks are DQL. Git one-liners are in [`3.sh`](./3.sh). Nothing was run.

```bash
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-13/3-find-missing-app-logs-logic
git commit -m "Logic to find missing app logs"
git push
```
