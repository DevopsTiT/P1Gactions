# ActiveGate Entity And Process Network Load

## Decision tree

```
Screenshot?
 ACTIVE_GATE and node-count cells          → same as answer 9, nothing new
 fetch dt.entity.apm_security_gateway, 0   → right table for ActiveGates, but the filter found nothing
     run without the filter first          → V0: is the table empty?
     rows exist                            → "eastasia" is not in the tags → look at the real tags (V1)
     health_status = entity.type           → wrong: that is the type name, not health
 fetch logs (one line)                     → reads all logs in the timeframe, first 1,000 rows
 Network load chart for one process        → works (instance ID matches the instance field)
     one wave per day                      → daily usage pattern
     one tall spike near Jun 25            → check what happened that day
```

## Short takeaway

| Cell | What it does | Result | Main point |
|---|---|---|---|
| T and U | ActiveGate node and node counts | Same as answer 9 | Nothing new |
| V | ActiveGates tagged "eastasia" | 0 records | Correct table, but the filter matched nothing. Two columns are mislabeled. |
| W | `fetch logs` | Not shown | Works, but returns raw logs with no focus |
| X | Network load of one process over June | 1 series | Daily waves with one spike near Jun 25 |

## Summary

`dt.entity.apm_security_gateway` is the classic entity table for ActiveGates ("security gateway" is the old name), so this is the right place to look after the Smartscape query failed. It returns nothing because no ActiveGate has "eastasia" in its tags, or the table is empty in this view. The network load charts work this time because the ID type matches the field.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| ActiveGate | A Dynatrace relay server between agents and Dynatrace, also used for cloud and remote checks. | The V cell looks for them. |
| `dt.entity.apm_security_gateway` | The classic entity table for ActiveGates. | Works where `smartscapeNodes("ACTIVE_GATE")` did not. |
| Network zone | A Dynatrace setting that routes agents to nearby ActiveGates. | Not the same thing as tags. |
| `eastasia` | Looks like an Azure region name (East Asia, Hong Kong). | The filter assumes it is in the tags. |
| `queryId` comment | A note left when a chart is opened from a Dynatrace page in a notebook. | Shows where the query came from. |

### Cells T and U (repeat)

Same as answer 9: `ACTIVE_GATE` is not a Smartscape node type here, and the node count shows 2,327 hosts, 35,280 processes and so on.

### Cell V: ActiveGates in "eastasia", 0 records

```
fetch dt.entity.apm_security_gateway
| fields entity.name, entity.type, tags
| filter contains(toString(tags), "eastasia")
| fieldsAdd network_groups = tags, health_status = entity.type
| sort entity.name asc
```

| Line | What it does |
|---|---|
| `fetch dt.entity.apm_security_gateway` | All ActiveGates |
| `fields entity.name, entity.type, tags` | Keeps name, type and tags |
| `filter contains(toString(tags), "eastasia")` | Keeps ActiveGates whose tags contain the text "eastasia" |
| `fieldsAdd network_groups = tags` | Copies tags into a column called network_groups |
| `fieldsAdd health_status = entity.type` | Copies the type into a column called health_status |

What is wrong:

| Problem | Explanation | Fix |
|---|---|---|
| 0 records | Either the table is empty for this window, or no tag contains "eastasia" in that exact case | Run V0 without a filter, then V1 to read the real tags |
| Case | `contains` is case sensitive by default, so "EastAsia" would not match | `caseSensitive:false` |
| `network_groups = tags` | Tags are labels. Network zones are a separate setting. The name is misleading. | Drop it, or look up the network zone separately |
| `health_status = entity.type` | The type is just "ActiveGate". It says nothing about health. | Drop it. Check ActiveGate health in Deployment Status. |

This looks like a CoPilot query. The error just above it ("couldn't generate a valid DQL query") suggests the prompt was retried and this was the result.

### Cell W: fetch logs

```
fetch logs
```

| Point | Explanation |
|---|---|
| What it does | Reads every log line in the notebook timeframe |
| What you get | The first 1,000 rows, newest first, with every field |
| Better habit | Add a time range, pick columns, and filter. See query W. |

### Cell X: network load of one process

```
//queryId=ProcessPerformanceNetworkRequests
timeseries avg(dt.process.network.load), by:{dt.entity.process_group_instance},
  filter: dt.entity.process_group_instance == "PROCESS_GROUP_INSTANCE-38F231AB4892E434"
| fieldsAdd metricName = "Requests"
```

| Part | What it does |
|---|---|
| `//queryId=...` | A comment. It shows the chart came from the process page "Network requests" view. |
| `avg(dt.process.network.load)` | Average network load of the process |
| `filter ... == "PROCESS_GROUP_INSTANCE-..."` | One process instance. The ID type matches the field, so it works. |
| `fieldsAdd metricName = "Requests"` | Only a label for the chart legend |

| Result | Meaning |
|---|---|
| 1 record, 6/1 to 7/1 | One process over June |
| Regular up and down, about once a day | A daily pattern: busy by day, quiet at night |
| Values mostly in one band | Steady load |
| One tall spike around Jun 25 | About double the usual peak. Worth checking: a batch run, a retry storm, or a release that day. |
| Second chart below | Another process instance, with a spikier pattern |

Compare with answer 2, cell 2: there a `PROCESS_GROUP-` ID was used on the instance field and gave 0 records. Here the instance field gets a `PROCESS_GROUP_INSTANCE-` ID, which is correct.

## Result

| Cell | Verdict | Fix or use |
|---|---|---|
| V | Right table, filter finds nothing | V0 and V1 first; case-insensitive filter; drop the mislabeled columns |
| W | Works, unfocused | Add time range, columns and a limit |
| X | Works | Hourly interval, peak vs normal (X2), check the Jun 25 spike |

Common mistakes:

| Mistake | How to avoid it |
|---|---|
| Filtering before you know the data | Run the table with no filter first |
| Naming a column after something it is not | `health_status = entity.type` misleads readers |
| Case-sensitive `contains` | Add `caseSensitive:false` |
| Reading a spike without the date | Use X2 and match the time to deploys or batches |

## Data flow map

```
ActiveGates
  smartscapeNodes("ACTIVE_GATE") → not a node type → 0
  dt.entity.apm_security_gateway → right table → filter "eastasia" in tags → 0
    → check without filter → read real tags → filter on what is really there

Logs
  fetch logs → all fields, first 1,000 rows → add range, columns, filter

Process network load
  OneAgent → dt.process.network.load → one PROCESS_GROUP_INSTANCE → daily waves + Jun 25 spike
```

## Related files

| File | What it is |
|---|---|
| `10-dynatrace-activegate-entity-network-load-explain-improved.dql` | ActiveGate checks, focused logs, process chart with peak check |
| `9-dynatrace-appengine-smartscape-explain/` | Cells T and U |
| `2-dynatrace-notebook-queries-explain/` | The earlier 0-record network load cell |
| `3-glossary.md` | Terms |
| `10.sh` | Git one-liners |

## Commands

The queries run in the Dynatrace Notebook. `10.sh` has only git lines. Nothing has been run.
