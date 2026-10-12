# Cost Result, Management Zones And Spans

## Decision tree

```
Screenshot?
 Cost query end, rows show "< 0.01" EUR        → each row is one 15-minute billing record, far too small to read
     want a real number?                      → summarize cost by capability or by day (C1, C2)
     1,000 records with warning               → the list is cut; any total from it is wrong
     log ingest rows ~10 KB each              → EIP sends very little log data (check with C3)
 Management zones list with repeats (blurry)  → one row per host and zone → summarize by zone (Z1)
 Stacked bar chart of endpoints              → one service's top 10 endpoints over 7 days
     daily waves, peaks around midday         → business-hours traffic, quiet nights
     fetch spans is heavy                      → use the request metric instead (S1, S2)
```

## Short takeaway

| Item | What it does | What it shows |
|---|---|---|
| Cost query end | Joins the price list, works out cost, keeps the useful columns | 1,000 tiny rows for EIP, each under 0.01 EUR |
| Management zones | Lists the zones hosts belong to | Zones such as ALJ, ALJ_PRD and several AGO_OS and AGO_INFRA zones (photo is blurry) |
| Spans chart | Request count per endpoint for one service over a week | Clear business-hours pattern every day |

## Summary

The cost query works, but it lists every 15-minute billing record, so each cost rounds to "< 0.01" and the 1,000-row cut makes any total wrong. Add a `summarize` to get one number per capability. The zones query is fine for a peek but needs grouping to be useful. The spans chart is a good traffic picture; the same chart from the request metric is faster and does not scan raw traces.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| Rate card | The price list: price per unit for each capability. | Typed into the query as `data json`. |
| Capability | A billed feature, such as Log Ingest or Full-Stack Monitoring. | Cost is shown per capability. |
| Billing record | One usage record, usually per 15 minutes. | Very small on its own. |
| Management zone | A classic Dynatrace grouping of entities, used for permissions, dashboards and alert routing. | Shows who owns which hosts. |
| Span | One step of a request inside a trace, such as one call to an endpoint. | `fetch spans` reads raw trace data. |
| Endpoint | The URL path or method a service exposes, like `/images`. | The chart splits traffic by endpoint. |
| `dt.service.request.count` | A built-in metric that counts service requests. | Same answer as counting spans, much cheaper. |

### Part 1: end of the cost query

```
| lookup [ data json:"[ ...price list... ]" ],
    sourceField:event.type, lookupField:name, prefix:"ratecard."
| fieldsAdd cost = if(event.type == "Traces - Ingest & Process", "not applicable", else: usage * toDouble(ratecard.price))
| fieldsRename currency = ratecard.currencyCode, capability = event.type, price = ratecard.price
| fieldsKeep usage.start, usage.end, capability, filter, usage, cost, price, currency,
             dt.entity.host.name, billed_bytes, application_only_type, dt.openpipeline.pipelines,
             dt.entity.host, billed_container_hours, dt.openpipeline.source, ...
| sort filter asc, usage.start, capability
```

| Line | What it does |
|---|---|
| `lookup ... sourceField:event.type, lookupField:name` | Matches each billing record to its price by capability name, such as "Log Management & Analytics - Ingest & Process" |
| `prefix:"ratecard."` | Price list fields arrive as `ratecard.price` and `ratecard.currencyCode` |
| `cost = usage * price` | The estimated cost. Traces appear to be marked "not applicable" as a special case. |
| `fieldsRename` | Friendlier column names |
| `fieldsKeep` | Drops everything except the listed columns |
| `sort` | By product filter, then time, then capability |

The price list itself has one row per capability, for example Automation Workflow, Events Query, Events Ingest, Events Retain, Code Monitoring, AppEngine Functions, Foundation and Discovery, Full-Stack Monitoring, Infrastructure Monitoring, Kubernetes Platform Monitoring, Log Query, Log Ingest, Log Retain, Mainframe, Custom Metrics, Runtime Application Protection, Runtime Vulnerability Analytics, Security Posture Management, Serverless, Synthetic browser, HTTP and third-party monitors, Traces ingest, query and retain, and Real User Monitoring with and without session replay. All prices are in EUR.

#### The result rows

| Column | Value seen | Meaning |
|---|---|---|
| filter | EIP on every row | Only the EIP product share |
| capability | Mostly "Log Management & Analytics - Ingest & Process", some "Retain" | EIP's billed usage is mainly logs |
| billed_bytes on Ingest rows | About 10,000 to 11,000 | About 10 KB of logs per 15-minute record |
| billed_bytes on Retain rows | About 3 million | About 3 MB of stored logs |
| price | 0.0948 for Ingest, 0.000332 for Retain | Price per GiB from the rate card |
| usage and cost | "< 0.01" | 10 KB is about 0.00001 GiB, so the cost per row is a millionth of a euro |
| 1,000 records with warning | Cut | More rows exist, so do not add these up by hand |

What it tells you:

| Point | Explanation |
|---|---|
| Row-level cost is not useful | Each record is too small to read. Group them. |
| EIP's log volume looks very small | About 10 KB per 15 minutes is roughly 1 MB a day. Either EIP sends very few logs, or most of its logs are tagged to another product. Check with C3. |
| The 1,000 cut hides the total | A `summarize` returns one row per capability, well under the limit. |

### Part 2: management zones (blurry photo)

```
fetch dt.entity.host   // or any other entity type like dt.entity.service
| fields managementZones
| expand managementZones
| fields managementZones
```

| Line | What it does |
|---|---|
| `fetch dt.entity.host` | All hosts. The comment says you can use services or other types too. |
| `fields managementZones` | Keeps only the list of zones each host belongs to |
| `expand managementZones` | One row per host and zone |
| `fields managementZones` | Shows only the zone name |

| Result | Meaning |
|---|---|
| 1,000 records with warning | Cut |
| Zone names (blurry) | Something like ALJ, ALJ_PRD, an ALJ web production zone, AGO_OS_LINUX_PRD, AGO_OS_WIN_PRD, AGO_OS_OVERALL_PRD, AGO_OS_OVERALL_SILVA_ROLLOUT_PRD, AGO_INFRA_OVERALL, AGO_OS_Linux_Japan_AGO_PRD and a banks production zone |
| Same names again and again | Because every host repeats its zones. The list has no counts. |

A host can sit in several zones at once, for example an OS zone, an infra zone and a country zone. Grouping by zone (Z1) shows how many hosts each zone holds. Hosts in no zone (Z2) are worth finding, because zone-based permissions and alert routing will not see them.

After this cell, the notebook starts a new section called "AppEngine Functions usage".

### Part 3: endpoint traffic from spans

```
fetch spans
| filter isNotNull(endpoint.name)
| filter dt.entity.service == "SERVICE-87E0B847048C5C0B"
| makeTimeseries count(), by:{ endpoint.name }, time: start_time
| sort arrayAvg(`count()`) desc
| limit 10
```

The service ID is read from the photo and may have a character wrong.

| Line | What it does |
|---|---|
| `fetch spans` | Raw trace data |
| `filter isNotNull(endpoint.name)` | Only spans that belong to an endpoint |
| `filter dt.entity.service == ...` | One service |
| `makeTimeseries count(), by:{endpoint.name}, time:start_time` | Number of spans per endpoint per time slice |
| ``sort arrayAvg(`count()`) desc`` | Busiest endpoints first. The backticks are needed because the column is literally named `count()`. |
| `limit 10` | Top 10 endpoints |

| Result | Meaning |
|---|---|
| 10 records, timeframe about 4/8 to 4/15 | Top 10 endpoints over 7 days |
| Stacked bars in waves | Traffic rises each morning, peaks around midday, and drops at night |
| Some days lower | Probably weekend days |
| Legend | `/images` and several API paths for login, tokens, agent checks, topics and configuration |
| Biggest band | One endpoint carries a large share, likely `/images` or a login call |

Why switch to the metric:

| `fetch spans` | `dt.service.request.count` |
|---|---|
| Reads raw traces, which can scan a lot of data | Reads a small pre-built metric |
| Slower over 7 days | Fast over 7 days |
| Query cost depends on data scanned | Much cheaper |
| Needed for span details like attributes or exceptions | Enough for counts, failures and response time |

## Result

| Item | Verdict | Fix or use |
|---|---|---|
| Cost query | Works, but row level and cut | Summarize by capability or day (C1, C2) |
| EIP logs | Very small volume | Confirm with C3 |
| Zones query | Works, no counts | Summarize by zone (Z1); find hosts with no zone (Z2) |
| Spans chart | Works, good picture | Use the request metric for routine views (S1, S2) |

Common mistakes:

| Mistake | How to avoid it |
|---|---|
| Reading cost row by row | Always summarize billing data |
| Adding up a cut list | Check for the 1,000 warning first |
| Listing zones without counts | Summarize by zone |
| Using `fetch spans` for simple counts | Use `dt.service.request.count` |
| Forgetting backticks on names like `count()` | Use backticks or name the column, for example `requests = count()` |

## Data flow map

```
Cost
  billing records (EIP share) → usage in units → lookup rate card (EUR) → usage × price
    → row list (tiny, cut at 1,000) → better: summarize by capability or day

Management zones
  dt.entity.host → managementZones list → expand → one row per host and zone → summarize by zone

Endpoint traffic
  OneAgent traces → spans → filter one service → count per endpoint per slice → top 10 stacked bars
  same answer, cheaper: dt.service.request.count by endpoint.name
```

## Related files

| File | What it is |
|---|---|
| `8-dynatrace-cost-zones-spans-explain-improved.dql` | Cost totals, zone counts, metric-based endpoint chart |
| `7-dynatrace-ctm-processes-cost-explain/` | First part of the cost query |
| `3-glossary.md` | Terms |
| `8.sh` | Git one-liners |

## Commands

The queries run in the Dynatrace Notebook. `8.sh` has only git lines. Nothing has been run.
