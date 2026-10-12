# Dynatrace Notebook Queries Explained

## Decision tree

```
Notebook cell result?
 1 record with a line chart     → query 1 works (process group network load, 6-hour buckets)
 0 records                      → query 2: ID type mismatch
     ID starts with PROCESS_GROUP-          → filter dt.entity.process_group
     ID starts with PROCESS_GROUP_INSTANCE- → filter dt.entity.process_group_instance
 642 ERROR logs                 → query 3 works, but most rows are Qualys agent noise
     summarize by log.source → exclude qualys → look at real app errors
 574 rows for "hosts"           → query 4 returns processes, not hosts
     summarize by host → one row per host
```

## Short takeaway

| Cell | What it asks | What happened | What to do |
|---|---|---|---|
| 1 | Network load of one process group | 1 record, chart over 30 days | Fine. Add `interval:1h` for more detail. |
| 2 | Same metric per process group instance | 0 records | The ID is a process group ID. Filter on `dt.entity.process_group`. |
| 3 | AI prompt: logs with status ERROR | 642 records in 2 hours | Mostly Qualys agent errors. Group by `log.source` first. |
| 4 | AI prompt: Node.js hosts and metadata | 574 records | These are Node.js processes. Group by host for a host list. |

## Summary

Cell 1 works. Cell 2 is empty because a process group ID was used as a process group instance ID. Cells 3 and 4 were written by Davis CoPilot, the Dynatrace AI assistant, from plain-English prompts. Both run, but each answers a slightly different question from the one asked.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| Process group | All processes that do the same job, for example "emma-api on every pod". | One ID covers the whole service. |
| Process group instance | One single process of that group on one host or pod. | One ID per running copy. |
| Entity ID | Dynatrace's name for a thing, such as `PROCESS_GROUP-A73B...` or `HOST-1268...`. | The prefix tells you the type. |
| `timeseries` | DQL command that reads metrics and returns a line over time. | Used in cells 1 and 2. |
| `fetch` | DQL command that reads records: logs, or entities like hosts. | Used in cells 3 and 4. |
| Notebook | A Dynatrace page where you run DQL queries cell by cell. | Where all four queries live. |

### Cell 1: process group network load

```
timeseries avg(dt.process.network.load), by:{dt.entity.process_group}, filter:dt.entity.process_group=="PROCESS_GROUP-A73B79EBAEDBF111"
```

| Part | What it does |
|---|---|
| `timeseries` | Read a metric over time. |
| `avg(dt.process.network.load)` | The average network load the OneAgent reports for the processes. |
| `by:{dt.entity.process_group}` | One line per process group. |
| `filter:... == "PROCESS_GROUP-A73B..."` | Keep only this one process group. |

| Result | Meaning |
|---|---|
| 1 record | One process group matched, so one line. |
| Timeframe 6/1 12:00 to 7/1 18:00 | About 30 days was selected. |
| Interval 6.00 h | Dynatrace picked 6-hour buckets automatically because the range is long. Each point is a 6-hour average. |
| The wavy line | A steady daily pattern with one bump near the end. Worth checking if that bump matches a deploy or a batch. |

Tip: add `interval:1h` to see more detail. Short peaks are hidden inside 6-hour averages.

### Cell 2: per instance, 0 records

```
timeseries avg(dt.process.network.load), by:{dt.entity.process_group_instance}, filter:dt.entity.process_group_instance=="PROCESS_GROUP-ADEC3A526994F280"
```

This is the important one. The field is `process_group_instance`, but the value starts with `PROCESS_GROUP-`.

| What the filter expects | What was given |
|---|---|
| An instance ID like `PROCESS_GROUP_INSTANCE-xxxx` | A group ID `PROCESS_GROUP-ADEC...` |

No instance has a group ID, so nothing matches and the result is 0 records. This is not "no data". The query asks for something that cannot exist.

| Fix | When |
|---|---|
| Filter on `dt.entity.process_group == "PROCESS_GROUP-ADEC..."` | You want the whole group |
| Keep `by:{dt.entity.process_group_instance}` but filter on the group | You want one line per running copy of that group |
| Use a real `PROCESS_GROUP_INSTANCE-...` ID | You want one specific process |

The timeframe here, 6/1 18:00 to 7/2 00:00, is also different from cell 1. Keep timeframes the same when you compare cells.

### Cell 3: AI prompt "Show all the logs with log status ERROR"

Davis CoPilot turned the sentence into:

```
fetch logs
| filter loglevel == "ERROR"
```

| Result | Meaning |
|---|---|
| 642 records | 642 error log lines in the last 2 hours. |
| Columns | timestamp, content, host.name, legal entity, loglevel, log.source, status, host group |
| Most `log.source` values | `QualysAgent.log` on Windows and `/var/log/qualys/qualys-agent.log` on Linux |
| Typical content | "Failed to send request", "Failed to get domain", "Failure while attempting..." |
| Legal entities | AXA-LIFE-JAPAN, AXA-GROUP-OPERATIONS-SINGAPORE, AXA-ASIAN-MARKETS-OFFICE |

What this tells an SRE:

| Point | Explanation |
|---|---|
| These are not app errors | Qualys is a security scanning agent. Its errors mean it could not reach its own cloud server, usually because of a proxy or a firewall. |
| They hide real problems | 642 rows of agent noise make real application errors hard to see. |
| `loglevel` and `status` | Both columns say ERROR here. `loglevel` comes from the log line itself. `status` is the level Dynatrace works out. Filtering on `status` catches logs whose own level field is missing. |
| No time range in the query | It used the notebook's "Last 2 hours" setting. |

Better steps: first group by `log.source` to see who is noisy, then exclude Qualys and read what is left. Both queries are in the improved DQL file.

### Cell 4: AI prompt "list of host with process technology = Node.js and metadata"

```
fetch dt.entity.process_group_instance
| filter processType == "NODE_JS"
| fieldsAdd metadata, belongs_to[dt.entity.host]
| lookup [ fetch dt.entity.host | fieldsAdd entity.name ], sourceField:belongs_to[dt.entity.host], lookupField:id, fields:{entity.name}
```

| Line | What it does |
|---|---|
| `fetch dt.entity.process_group_instance` | Read every monitored process, not hosts |
| `filter processType == "NODE_JS"` | Keep only Node.js processes |
| `fieldsAdd metadata, belongs_to[dt.entity.host]` | Add the process details and the ID of the host it runs on |
| `lookup [fetch dt.entity.host ...]` | Join the host table on that ID to get the host name |

| Result | Meaning |
|---|---|
| 574 records | 574 Node.js processes, not 574 hosts. One host can run many. |
| `metadata` column | Details such as Kubernetes namespace, pod name, container name, cluster ID, Node.js script name, command line, and the exe path |
| What metadata shows | Many are Kubernetes pods (for example emma, portals, mypage-style services), started with `node /app/index.js` or similar |
| `belongs_to[dt.entity.host]` | The host ID, like `HOST-1268...` |
| Host name | It comes from the lookup and appears further right as `lookup.entity.name` (off-screen) |

The query answers "which Node.js processes exist", not "which hosts". To list hosts, group by host ID and count the processes on each one. That query is in the improved DQL file.

## Result

| Cell | Verdict | Fix |
|---|---|---|
| 1 | Correct | Optional: `interval:1h` and `entityName()` to show the readable name |
| 2 | Wrong ID type, so 0 records | Filter `dt.entity.process_group` with the `PROCESS_GROUP-` ID |
| 3 | Correct, but noisy | Group by `log.source`, then exclude Qualys |
| 4 | Answers the process question, not the host question | `summarize ... by host_id`, then the lookup for the name |

Common mistakes to remember:

| Mistake | How to avoid it |
|---|---|
| Mixing entity types in a filter | Read the ID prefix: `PROCESS_GROUP-`, `PROCESS_GROUP_INSTANCE-`, `HOST-`, `SERVICE-` |
| Trusting AI-generated DQL without reading it | Check what `fetch` reads and whether you need a `summarize` |
| Comparing cells with different timeframes | Set the same timeframe on every cell |
| Long ranges hiding spikes | Set `interval` yourself |

## Data flow map

```
OneAgent on hosts and pods
  ├─ metrics (dt.process.network.load) → timeseries → cells 1 and 2
  ├─ logs (app logs, Qualys agent logs) → fetch logs → cell 3
  └─ entities (hosts, process groups, instances) → fetch dt.entity.* → cell 4

Entity hierarchy
  HOST-xxxx
   └─ runs PROCESS_GROUP_INSTANCE-xxxx (one process)
         └─ belongs to PROCESS_GROUP-xxxx (all copies of that process)
```

## Related files

| File | What it is |
|---|---|
| `2-dynatrace-notebook-queries-explain-improved.dql` | Fixed and improved versions of all four queries |
| `3-glossary.md` | Terms |
| `2.sh` | Git one-liners |

## Commands

The DQL queries run in the Dynatrace Notebook, not in a terminal. Copy them from `2-dynatrace-notebook-queries-explain-improved.dql`. `2.sh` only has the git lines. Nothing has been run.
