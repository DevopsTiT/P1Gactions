# Check eopt Pod Host In Dynatrace

## Decision tree

```
Host page shows eoptsystemapi-564c45bd9f-jqqtl (App only, OpenShift)
 → pod name IS the Dynatrace host name → host.name filter works
 Step 1 UI → host page → Logs tab → do lines appear?
   yes → Step 2
   no  → log ingest not on for this host → fix ingest first
 Step 2 Notebook → query 1 → all eopt hosts listed?
 Step 3 Notebook → query 2 → host.name filled on logs?
   empty → use query 3 (entityName(dt.entity.host)) in the detector
 Step 4 → query 6 → parse level returns ERROR/INFO/DEBUG?
   yes → answer 27 detector is ready
   no  → send a sample line → fix pattern
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the screenshot prove? | Dynatrace sees each eopt pod as its own host, named after the pod. |
| Why "App only"? | OneAgent runs inside the container (OpenShift), not on the node. Each pod becomes a host. |
| Fastest UI check | On the host page, click the **Logs** tab. |
| Best full check | Run the six queries in a Notebook. |
| What it confirms | Whether `host.name` starts with `eoptsystemapi-` on the log lines, which answer 27 needs. |

## Summary

Your screenshot shows the host `eoptsystemapi-564c45bd9f-jqqtl` with monitoring type App only and PaaS type OpenShift. That means the pod name is the Dynatrace host name, so filtering logs on `host.name` with the pod prefix is correct. Use the Logs tab for a quick look, then a Notebook to confirm the fields and the level parse.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Host entity | Dynatrace's record of one monitored machine, with an ID like `HOST-282C6DCE...`. | Logs link to it through `dt.entity.host`. |
| App only monitoring | OneAgent runs inside the app container instead of on the server. | Each pod shows up as its own host, named after the pod. |
| `host.name` | The host name stored on each log line. | The detector filters on it. |
| `dt.entity.host` | The host ID stored on each log line. | Backup way to find the host name. |
| `entityName()` | DQL function that turns an entity ID into its name. | Works even if `host.name` is missing. |
| Notebook | Dynatrace page where you run DQL queries. | Where you run the checks. |

### What the host page shows

| Field on screen | Value | What it means |
|---|---|---|
| Host name | eoptsystemapi-564c45bd9f-jqqtl | Same as the Splunk host. The pod name. |
| Monitoring type | App only | OneAgent inside the container. |
| PaaS type | OpenShift | Runs on the OpenPaaS Kubernetes platform. |
| Tags | app:EOPT, tier:JAVA, env:PRD | Labels you can also filter on. |
| Cost center | ALJ | `dt.cost.costcenter` |
| Product | EOPT | `dt.cost.product` |
| Network zone | openpaas-scarlet-axa-global-asia-prod | The production OpenPaaS cluster. |
| OneAgent version | 1.343.114 | Recent agent, log support included. |
| Lifetime start | 2026-10-11 | Pod started yesterday. Names change on each restart. |

## Result

### Way 1: from the host page (quick)

| Step | What to do |
|---|---|
| 1 | Stay on the host page for `eoptsystemapi-564c45bd9f-jqqtl`. |
| 2 | Click the **Logs** tab (next to Events). |
| 3 | Lines like `2026-10-12T...Z DEBUG [ip: ...]` should appear. |
| 4 | Click one line and look at its fields. Check that `host.name` is filled and see whether `loglevel` exists. |
| 5 | If no lines appear, log ingest is not enabled for this host. Ask the Dynatrace admin to check the log ingest rules. |

### Way 2: in a Notebook (complete)

Open **Notebooks**, add a DQL section, and run these one at a time. They are also in `28-check-eopt-pod-host-in-dynatrace-check.dql`.

**Query 1: which eopt hosts exist**

```
fetch dt.entity.host
| filter startsWith(entity.name, "eopt")
| fields id, entity.name, tags
| sort entity.name asc
```

Expect eoptsystemapi, eoptprocessapi and eoptfrontend pods.

**Query 2: do their logs carry host.name**

```
fetch logs, from:now()-1h
| filter startsWith(host.name, "eopt")
| summarize lines = count(), by:{ host.name, dt.entity.host, k8s.pod.name, log.source }
```

If this returns rows, answer 27's filter works.

**Query 3: backup using the host entity**

```
fetch logs, from:now()-1h
| filter isNotNull(dt.entity.host)
| fieldsAdd host_entity_name = entityName(dt.entity.host)
| filter startsWith(host_entity_name, "eopt")
| summarize lines = count(), by:{ host_entity_name }
```

Use this if query 2 is empty but query 1 shows the hosts.

**Query 4: raw lines from the host in your screenshot**

```
fetch logs, from:now()-1h
| filter host.name == "eoptsystemapi-564c45bd9f-jqqtl"
| fields timestamp, host.name, dt.entity.host, log.source, loglevel, content
| limit 20
```

The pod name is read from a photo. If nothing returns, copy the exact name from the host page.

**Query 5: cost tags on logs**

```
fetch logs, from:now()-1h
| filter startsWith(host.name, "eopt")
| summarize lines = count(), by:{ dt.cost.product, dt.cost.costcenter }
```

**Query 6: the level parse from answer 27**

```
fetch logs, from:now()-1h
| filter startsWith(host.name, "eoptsystemapi-") or startsWith(host.name, "eoptprocessapi-")
| parse content, "NSPACE:log_ts SPACE+ ALPHA:level"
| summarize lines = count(), by:{ level, loglevel }
```

### What the results mean

| Result | What to do |
|---|---|
| Query 2 returns rows | Keep answer 27 as is. |
| Query 2 empty, query 3 returns rows | In answer 27, replace `coalesce(k8s.pod.name, host.name)` with `entityName(dt.entity.host)`. |
| Queries 2 and 3 both empty | Logs are not ingested for these hosts. Fix ingest before the detector can work. |
| Query 6 shows ERROR, INFO, DEBUG in `level` | Parse works. |
| Query 6 shows `loglevel` already filled with ERROR | You can use `filter loglevel == "ERROR"` instead of `parse`. Simpler. |
| Query 6 `level` is empty | Send one raw line from query 4 so the pattern can be fixed. |
| Query 5 shows `dt.cost.product = EOPT` | Optional scope: `filter dt.cost.product == "EOPT"`. Note it also includes the frontend. |

## Data flow map

```
eopt pod on OpenShift (OpenPaaS)
  → OneAgent inside the container (App only)
  → Dynatrace host entity: eoptsystemapi-564c45bd9f-jqqtl (HOST-...)
  → pod logs → Grail logs with host.name + dt.entity.host
  → check: host page Logs tab → Notebook queries 1 to 6
  → confirmed fields → answer 27 detector filters on host.name prefix
```

## Related files

| File | What it holds |
|---|---|
| `28-check-eopt-pod-host-in-dynatrace-check.dql` | Six check queries. |
| `../27-eopt-openpaas-pod-error-backend-tf/27-eopt-openpaas-pod-error-backend-tf.tf` | The detector these checks support. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | What the host page shows. |
| `2-result.md` | What to do with each result. |
| `3-glossary.md` | Words used. |
| `28.sh` | Commands, one per line. |

## Commands

All commands are in [`28.sh`](./28.sh). Nothing was run. The checks themselves run in a Dynatrace Notebook, not a shell.

```bash
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-12/28-check-eopt-pod-host-in-dynatrace
git commit -m "How to check eopt pod hosts and logs in Dynatrace"
git push
```
