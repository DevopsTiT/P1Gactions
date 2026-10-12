# Dynatrace Notebook Queries Part 2

## Decision tree

```
Notebook cell result?
 Red error "X isn't allowed here"
   word with a space (Main technology)  → cell A: not a field name → use softwareTechnologies
   SELECT / FROM / GROUP BY             → cell C: SQL, not DQL → rewrite with timeseries
 "1,000 records" with a warning triangle → cells B, D, F, G hit the default row limit → add | limit 10000
 Honeycomb all one color, one odd cell   → cell D: one service has an active problem
 Column always null                      → cell F: oneAgentCustomHostName is a host field, not a service field
 dt.entity.host null on some services    → cell F: external or database services have no host
```

## Short takeaway

| Cell | What it tries | What happened | Fix |
|---|---|---|---|
| A | Node.js processes plus "Main technology" | Error, 0 records | There is no field `Main technology`. Use `softwareTechnologies`. |
| B | Node.js processes with technology versions | 1,000 records, cut | Works. Summarize by version for an inventory. |
| C | SQL-style query for two service metrics | Error "FROM isn't allowed here" | DQL is not SQL. Use `timeseries`. |
| D | Service health honeycomb | 1,000 records, one service flagged | Works. Widen the problem window and lift the row limit. |
| F | Service to host list | 1,000 records, a column always null | That column belongs to the host. Get it with a lookup. |
| G | Service name and host name | 1,000 records | Works. `entityName()` is the easy way. Lift the row limit. |

## Summary

Two cells fail for syntax reasons: a field name with a space, and SQL keywords. The other four work, but all of them stop at 1,000 rows, the notebook's default limit, so the honeycomb and the lists are incomplete. Cell F also shows a common mix-up: asking a service for a field that only hosts have.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| Entity | A thing Dynatrace monitors: host, service, process. | Cells read entity tables with `fetch dt.entity.*`. |
| Service | Something that handles requests, such as an API or controller. | Cells D, F and G. |
| `runs_on[dt.entity.host]` | The list of hosts a service runs on. | Used to link services to hosts. |
| `expand` | Turns one row with a list into one row per list item. | One service on 3 hosts becomes 3 rows. |
| `lookup` | Adds fields from another query, matched on a key. | Brings host names or problems onto rows. |
| `entityName()` | Function that turns an ID into its display name. | A shortcut instead of a lookup. |
| Record limit | Notebooks return at most 1,000 rows unless you raise it. | The warning triangle means data was cut. |

### Cell A: error "technology isn't allowed here"

```
fetch dt.entity.process_group_instance
| filter processType == "NODE_JS"
| fieldsAdd metadata, Main technology, belongs_to[dt.entity.host]
| lookup [ fetch dt.entity.host | fieldsAdd entity.name ], sourceField:belongs_to[dt.entity.host], lookupField:id, fields:{entity.name}
```

| Point | Explanation |
|---|---|
| What broke | `Main technology` has a space. DQL reads `Main` as a field, then finds `technology` where it expects a comma. |
| Why 0 records | The query never ran. |
| Real field | "Main technology" is a label in the Dynatrace UI. In DQL the data is in `softwareTechnologies`. |
| Lesson | UI labels are not DQL field names. Use autocomplete, or `fetch ... | limit 1` to see the real names. |

### Cell B: Node.js processes with versions (works)

```
fetch dt.entity.process_group_instance
| fields entity.name, softwareTechnologies, dt.entity.host = belongs_to[dt.entity.host],
         dt.entity.process_group = instance_of[dt.entity.process_group], dt.entity.process_group_instance = id
| join [fetch dt.entity.host], kind:outer, on:{left[dt.entity.host] == right[id]}, fields:{hostname = entity.name, state}
| expand softwareTechnologies
| parse softwareTechnologies, "... type: ... edition: ... version: ..."
| filter matchesPhrase(toString(softwareTechnologies), "NODE_JS")
```

| Line | What it does |
|---|---|
| `fields ...` | Keeps the name and technologies, and renames the host, group and instance IDs into clear columns. |
| `join ... kind:outer` | Adds host name and state. Outer join keeps processes even if the host is not found. |
| `expand softwareTechnologies` | A process can list several technologies. Each becomes its own row. |
| `parse` | Cuts `type:NODE_JS, edition:null, version:20.9.0` into separate tech, edition and version fields. |
| `filter matchesPhrase(... "NODE_JS")` | Keeps only the Node.js rows. |

| Result | Meaning |
|---|---|
| 1,000 records with a warning | Cut at the default limit. There are more. |
| Versions seen | Several, such as 14.x, 20.x and 22.x. Mixed versions are normal, but very old ones are a security risk. |
| Pod-style names | Names like `hk-claims-frontend-cf64457cb-...` are Kubernetes pods. |

Best use: summarize by version to see how many processes still run an old Node.js. That query is in the improved DQL file.

### Cell C: error "FROM isn't allowed here"

The visible end of the query:

```
  service.alj_ga_report_compassccifa_responsetime',
  service.alj_ga_report_compassccifa_errorcount'
)
AND timestamp >= 1765335600000
AND timestamp <= 1765339200000
GROUP BY time_bucket('1 hour', timestamp)
```

| Point | Explanation |
|---|---|
| What broke | This is SQL (SELECT, FROM, WHERE, GROUP BY). DQL does not have those words. |
| Data wanted | Response time and error count of the Compass CCIFA report service. |
| Time window | `1765335600000` to `1765339200000` are milliseconds since 1970. They mean 2025-12-10 12:00 to 13:00 JST, one hour. |
| `time_bucket('1 hour')` | Group into hourly buckets. In DQL that is `interval:1h`. |

| SQL idea | DQL equivalent |
|---|---|
| `SELECT avg(x)` from metrics | `timeseries avg(x)` |
| `WHERE timestamp >= ... AND <= ...` | `from:"..." , to:"..."` |
| `GROUP BY time_bucket('1 hour')` | `interval:1h` |
| `GROUP BY service` | `by:{ dt.entity.service }` |

First confirm the exact metric keys with `metrics | filter contains(metric.key, "compassccifa")`. Calculated service metrics can have a different key in Grail.

### Cell D: "Service health" honeycomb (works)

```
fetch dt.entity.service
| filter serviceType != "DATABASE_SERVICE"
| lookup [
    fetch dt.davis.problems
    | filter event.status == "ACTIVE"
    | expand affected_entity_ids
  ], sourceField:id, lookupField:affected_entity_ids
| fieldsAdd affected = if(isNotNull(lookup.affected_entity_ids), "yes", else:"no")
| fields affected, id, name = entity.name, event.id = lookup.event.id, event.kind = lookup.event.kind
```

| Line | What it does |
|---|---|
| `fetch dt.entity.service` | Every service. |
| `filter serviceType != "DATABASE_SERVICE"` | Skip database services. |
| `fetch dt.davis.problems` with status ACTIVE | Open problems found by Davis, the Dynatrace AI engine. |
| `expand affected_entity_ids` | One row per affected entity of each problem. |
| `lookup ... sourceField:id` | For each service, find a problem that lists it. |
| `affected = yes or no` | A flag for the honeycomb color. |

| Result | Meaning |
|---|---|
| Honeycomb | One hexagon per service. Almost all blue (no problem). One darker hexagon is a service with an active problem. |
| 1,000 records with a warning | Only 1,000 services are drawn. Some services are missing from the picture. |

Hidden weaknesses:

| Weakness | Why it matters | Fix |
|---|---|---|
| Problem window is the notebook timeframe | A problem that started before the window is not fetched, so its service shows "no" | `fetch dt.davis.problems, from:now()-7d` |
| `lookup` keeps only the first match | A service in two problems shows only one | Use the D2 query for the full list |
| 1,000-row cut | Incomplete honeycomb | `| limit 10000` |

### Cell E: cut off

Only the first two lines of a service query are visible. It is the same start as cell F.

### Cell F: service to host, with a null column

```
fetch dt.entity.service
| expand dt.entity.host = runs_on[dt.entity.host]
| fields entity.name, id, dt.entity.host, oneAgentCustomHostName
| dedup id, dt.entity.host
```

| Result | Meaning |
|---|---|
| One row per service and host pair | `TemplIdRegistrationController` on two hosts gives two rows. |
| `oneAgentCustomHostName` always null | That field belongs to hosts, not services. A service row never has it. |
| `dt.entity.host` null on some rows | Services like an AWS API Gateway URL and `jp-ais-prod-db` do not run on a monitored host. They are external or database services. |
| `dedup` | Harmless here, but `expand` already gives unique pairs. |
| 1,000 records with a warning | Cut. |

Fix: look up the host table to get the host name and `oneAgentCustomHostName`.

### Cell G: service name and host name (works)

```
fetch dt.entity.service
| expand dt.entity.host = runs_on[dt.entity.host]
| fieldsAdd service.name = entity.name,
            host.name = entityName(dt.entity.host)
| fields service.name, host.name
```

| Result | Meaning |
|---|---|
| Readable list | For example `AncillaryServicesController` on `myaxabackend-6697f55d6b-z9p9n`. |
| Pod names as hosts | In Kubernetes with application-only monitoring, each pod shows up as a host. |
| `WRCWEB0LF02.axa-id.intraxa` | A classic Windows server. |
| Why it is good | `entityName()` gives the name without writing a lookup. |

## Result

| Cell | Verdict | Fix |
|---|---|---|
| A | Syntax error | Use `softwareTechnologies` instead of `Main technology` |
| B | Works, but cut | Summarize by version, and lift the limit |
| C | Wrong language | Rewrite with `timeseries`, `from`, `to`, `interval:1h` |
| D | Works, misses older problems | Problems from 7 days, and lift the limit |
| F | Works, one useless column | Get `oneAgentCustomHostName` from the host table |
| G | Works | Lift the limit |

Common mistakes:

| Mistake | How to avoid it |
|---|---|
| Using UI labels as field names | Use autocomplete or look at one record first |
| Writing SQL | Remember: `fetch` or `timeseries`, then pipes `|` |
| Ignoring the warning triangle | It means rows were cut at 1,000 |
| Asking a service for a host field | Join or look up the host table |
| Lookup over the notebook timeframe | Give the subquery its own `from:` |

## Data flow map

```
Entity tables (Smartscape)
  dt.entity.process_group_instance → softwareTechnologies → cells A, B
  dt.entity.service ── runs_on ──→ dt.entity.host → cells E, F, G
  dt.entity.service ←─ affected_entity_ids ── dt.davis.problems → cell D (honeycomb)

Metrics
  service.alj_ga_report_compassccifa_* → timeseries (not SQL) → cell C
```

## Related files

| File | What it is |
|---|---|
| `3-dynatrace-notebook-queries-part2-explain-improved.dql` | Fixed and improved versions of every cell |
| `2-dynatrace-notebook-queries-explain/` | Part 1 (network load, ERROR logs, Node.js hosts) |
| `3-glossary.md` | Terms |
| `3.sh` | Git one-liners |

## Commands

The queries run in the Dynatrace Notebook, not in a terminal. Copy them from the improved DQL file. `3.sh` has only git lines. Nothing has been run.
