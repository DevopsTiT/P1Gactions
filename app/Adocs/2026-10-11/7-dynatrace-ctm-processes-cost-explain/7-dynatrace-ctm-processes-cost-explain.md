# Control-M Processes And Cost Query

## Decision tree

```
Screenshot?
 End of the Processes query, 17 rows          → cell P result: ctm-ag-uploader.jar on 17 hosts, all healthy
     healthIndicators null, availability 100  → no health issues, process up the whole window
     containerRecord null                      → runs on normal servers, not in containers
 CoPilot: hosts running p_ctmat or p_ctmag    → 24 process rows (2 agent processes per host)
     want to find broken agents?              → group by host, flag hosts missing one process (Q2)
 Long billing query with a price list         → cost estimate for product "EIP"
     if("product"=="costcenter", ...)          → a template switch, always false → splits by product tag
     traces handled in a separate append       → traces are billed by ingested bytes
     lookup data json                          → list prices in EUR per unit
```

## Short takeaway

| Item | What it does | What it shows |
|---|---|---|
| Cell P end | Adds container, availability and final columns | 17 uploader processes, no health issues, 100% available |
| CoPilot query | Lists hosts that run Control-M agent processes | 24 rows, about two processes per host |
| Cost query | Estimates Dynatrace cost for product EIP | Usage per capability multiplied by a price list |

## Summary

The Processes query ends with two more lookups and returns 17 healthy `ctm-ag-uploader.jar` processes on Windows and Linux servers. The CoPilot query is correct but repeats the same values in several columns; grouping by host makes it a real health check for the Control-M agent. The cost query is a Dynatrace template that turns billing records into money for one product tag.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| Control-M agent | Software on each server that runs the batch jobs Control-M sends. | Without it, jobs on that server do not run. |
| `p_ctmag` | The agent listener: receives job orders from the Control-M server. | Must run on every agent host. |
| `p_ctmat` | The agent tracker: reports job status back to the server. | Must run next to the listener. |
| `ctm-ag-uploader.jar` | Java part of the agent that uploads job output. | Checked in cell P. |
| Availability | Percent of time the process was running. | 100 means it never stopped in the window. |
| Container group instance | A running container, such as a Kubernetes pod. | Null means the process is not in a container. |
| Cost allocation | Splitting billed usage by tags such as product or cost center. | Lets each team see its share. |
| DPS | Dynatrace Platform Subscription, the pay-per-use licence. | Billing records follow this model. |

### Part 1: end of the Processes query (cell P)

#### Container lookup

```
timeseries { avg(dt.process.cpu.usage), avg(dt.process.availability), sum(dt.host.zos.gcp_time) },
  by:{ dt.entity.container_group_instance, id = dt.entity.process_group_instance }, union:true
| fields containerRecord = record(containerId = dt.entity.container_group_instance,
                                  containerName = entityName(dt.entity.container_group_instance)), id
```

Same trick as the host and group lookups: use any metric that exists to learn which container each process ran in.

#### Availability lookup

```
timeseries a1 = sum(dt.process.availability, rollup: sum),
  filter: availability.state == "available",
  by:{ availability.state, id = dt.entity.process_group_instance },
  nonempty: true, from: ..., to: ...
| parse replaceString(toString(a1[]), "null", "0"), "'[' ARRAY{ DOUBLE:i ', ' }{1,10000}:a1 ']'"
| fieldsAdd intervalToMinutes = toLong(interval) / 60000000000
| fieldsAdd a1 = if(a1[] > intervalToMinutes, intervalToMinutes, else: a1[])
| fieldsAdd a1 = (a1[] / intervalToMinutes) * 100
| fieldsAdd availability = round(arrayAvg(a1), decimals: 2)
```

| Step | What it does | Plain example |
|---|---|---|
| `sum(dt.process.availability)` with state `available` | Minutes the process was up in each bucket | A 5-minute bucket fully up gives 5 |
| `parse replaceString(..., "null", "0")` | Turns empty buckets into 0 | No data counts as down |
| `intervalToMinutes` | Bucket length in minutes. `interval` is in nanoseconds, and 60,000,000,000 ns is 1 minute | 5 |
| Cap at bucket length | A bucket can never be more than 100% up | 6 becomes 5 |
| Divide and times 100 | Percent per bucket | 5 of 5 gives 100 |
| `arrayAvg` and round | One availability number for the window | 100.00 |

#### Final columns

`id, healthIndicators, name, groupName, hostRecord, containerRecord, customAlerts, availability, softwareTechnologies, tags, eventsThreshold`

#### The 17 rows

| Column | Value seen | Meaning |
|---|---|---|
| name and groupName | `ctm-ag-uploader.jar` | The uploader, one process group |
| hostRecord | CEAA204F, CEAA206E, CEAA211G, WPALJA0092, ceaaa00a and others | 17 servers, a mix of Windows and Linux |
| healthIndicators | null | No health events such as process unavailable or high GC |
| customAlerts | null | No custom alerts on the process |
| containerRecord | null | Runs directly on servers, not in containers |
| availability | 100.00 on every row | Up the whole window |
| softwareTechnologies | APACHE_HTTP_CLIENT_SYNC, JAVA, QOS_LOGBACK | A Java app that makes HTTP calls and logs with Logback |
| tags | Starts with `AGO_AXA_...` (cut) | Ownership or support group tags |

Conclusion: at that time, the Control-M uploader was running and healthy on all 17 hosts.

### Part 2: CoPilot prompt "list host name and process name which is running processes p_ctmat or p_ctmag"

```
fetch dt.entity.process_group_instance
| filter in(entity.name, {"p_ctmat", "p_ctmag"})
| fieldsAdd host_id = belongs_to[dt.entity.host]
| lookup [ fetch dt.entity.host | fieldsAdd host_name = entity.name ],
    sourceField:host_id, lookupField:id, prefix:"host."
| fieldsAdd process_name = entity.name
```

| Line | What it does |
|---|---|
| `filter in(entity.name, {...})` | Keeps the two Control-M agent processes |
| `host_id = belongs_to[dt.entity.host]` | The host each process runs on |
| `lookup ... prefix:"host."` | Adds the host table fields with `host.` in front of every name |
| `process_name = entity.name` | A copy of the process name |

| Result | Meaning |
|---|---|
| 24 records | 24 agent processes. With two processes per agent, that is about 12 hosts. |
| Hosts | CEAA204F, CEAA20F7, CEAA2116, CEAA2115, CEAA20C8, CEAA2090, CEAA20B8, WPALJA2162, ceaaa00a, ceaa901a, ceaa901b and more |
| Repeated columns | `host_id` and `host.id` are the same. `host.entity.name` and `host.host_name` are the same. `process_name` and `entity.name` are the same. |

The useful question is not "list them" but "which host is missing one". If a host has the listener but not the tracker, job status stops coming back. Query Q2 shows only those hosts.

Also worth noting: the uploader runs on 17 hosts, but the agent processes come to about 12 hosts in this list. Query Q1 puts them side by side to check whether some uploader hosts have no listener or tracker visible.

### Part 3: cost estimate query

#### Usage part

```
fetch dt.system.events
| filter event.kind == "BILLING_USAGE_EVENT"
| filterOut event.type == "Traces - Ingest & Process"   //traces need special handling
| dedup event.id
| filter in(event.type, {"Full-Stack Monitoring", "Infrastructure Monitoring",
                         "Log Management & Analytics - Ingest & Process", "Log Management & Analytics - Retain",
                         "Metrics - Ingest & Process", "Traces - Ingest & Process"})
| fieldsAdd costallocation = if("product" == "costcenter", dt.cost.costcenter, else: dt.cost.product)
| fieldsRemove dt.cost.costcenter, dt.cost.product
| expand costallocation
| fieldsAdd filter = coalesce(costallocation[key], costallocation)
| filter in(filter, {"EIP"})
| fieldsAdd billed_bytes = coalesce(costallocation[billed_bytes], billed_bytes)
| fieldsAdd usage = coalesce(billed_host_hours, billed_gibibyte_hours,
                             toDouble(billed_bytes) / (1024*1024*1024), billed_invocations, ingested_bytes, 1)
| fieldsAdd entityName(dt.entity.host)
| fieldsAdd usage.start = if(isNull(usage.start), timestamp, else: usage.start)
```

| Line | What it does | Note |
|---|---|---|
| `filter BILLING_USAGE_EVENT` | Only billing records | |
| `filterOut Traces` then `filter in(..., Traces)` | Removes traces, then the list still names traces | The second mention does nothing. Traces are handled in the append below. |
| `dedup event.id` | One copy per record | |
| `if("product" == "costcenter", ...)` | Compares two fixed words, so it is always false and always uses `dt.cost.product` | A template switch. Change the first word to `costcenter` to split by cost center. |
| `expand costallocation` | One row per product share of a record | One record can be shared by several products |
| `filter in(filter, {"EIP"})` | Keeps only the EIP product share | |
| `billed_bytes` from the share | Uses the bytes assigned to EIP, not the full record | |
| `usage = coalesce(...)` | Picks the right unit for each capability | Host-hours for Infrastructure, GiB-hours for Full-Stack, GiB for logs and metrics, invocations for AppEngine, 1 for a workflow run |
| `usage.start` | Uses the record time when the usage start is missing | |

#### Traces append

```
| append [
    fetch dt.system.events
    | filter event.kind == "BILLING_USAGE_EVENT" and event.type == "Traces - Ingest & Process"
    | (same product split and EIP filter)
    | fieldsAdd usage = toDouble(ingested_bytes) / (1024*1024*1024)
  ]
```

Traces are billed by ingested data, so their usage becomes GiB of ingested bytes.

#### Price list lookup

```
| lookup [ data json:"[ {\"key\":\"AUTOMATIONS\", \"name\":\"Automation Workflow\", \"price\":\"...\", \"currencyCode\":\"EUR\"}, ... ]" ]
```

| Part | Meaning |
|---|---|
| `data json:` | Builds a small table inside the query, here a price list |
| Rows | One per capability: Automation Workflow, Events Query, Events Ingest, Full-Stack Monitoring, Infrastructure Monitoring, Kubernetes Platform Monitoring, Log Ingest, Log Retain, Log Query, Metrics, Runtime Application Protection, Runtime Vulnerability Analytics, Security Posture Management, Serverless Functions and more |
| `price` and `currencyCode` | Price per unit in EUR |
| After the lookup (cut off) | Most likely `cost = usage * price`, then a sum per capability |

Important: these are list prices typed into the template. Your contract price may differ, so treat the result as an estimate.

## Result

| Item | Verdict | Use |
|---|---|---|
| Cell P result | Uploader healthy on 17 hosts | Good baseline for the Control-M agent |
| CoPilot query | Correct, repeated columns | Use Q2 to find hosts missing an agent process |
| Cost query | Works as a template | Check the price list against your contract; switch to cost center if needed |

Common mistakes:

| Mistake | How to avoid it |
|---|---|
| Trusting list prices as real cost | Replace prices with contract rates |
| Forgetting `dedup event.id` | Usage counted twice |
| Counting the whole record instead of the product share | Use `costallocation[billed_bytes]` as the template does |
| Listing processes when you want gaps | Group by host and look for missing ones |

## Data flow map

```
Control-M agent on each server
  p_ctmag (listener) + p_ctmat (tracker) + ctm-ag-uploader.jar
    → OneAgent → process instances in Smartscape
    → Processes query: health events, host, group, container, availability → 17 healthy rows
    → CoPilot query: 24 agent process rows → group by host → find gaps

Billing
  dt.system.events (BILLING_USAGE_EVENT)
    → split by product (dt.cost.product) → keep EIP
    → usage in the right unit per capability (+ traces append)
    → lookup price list (EUR) → usage × price → estimated cost
```

## Related files

| File | What it is |
|---|---|
| `7-dynatrace-ctm-processes-cost-explain-improved.dql` | Agent gap check, cleaner CoPilot list, availability, EIP usage |
| `6-dynatrace-billed-hosts-smartscape-processes-explain/` | Start of the Processes query |
| `3-glossary.md` | Terms |
| `7.sh` | Git one-liners |

## Commands

The queries run in the Dynatrace Notebook. `7.sh` has only git lines. Nothing has been run.
