# Dynatrace Notebook Queries Part 3

## Decision tree

```
Notebook cell result?
 Service → host list, some host.name null      → cell G: external, database or remote services have no host
 Services on ADJ hosts, 134 rows, no warning   → cell H works
     but rows show non-ADJ hosts too?          → filter ran before expand → move the filter after expand
 CPU of "Windows" hosts, 0 records             → cell I: no host has a tag exactly "Windows"
     → look at real tags first, or filter on osType == "WINDOWS"
 Tag filter across many entity types, blurry   → cell J: exact tag strings rarely match
     → expand tags, use contains(), check real tag text first
```

## Short takeaway

| Cell | What it tries | What happened | Fix |
|---|---|---|---|
| G | Service name to host name | 1,000 rows, cut; some hosts null | Works. Null means no monitored host. |
| H | Services on hosts tagged ADJ | 134 rows, complete | Works. Move the filter after `expand` for an exact list. |
| I | Average CPU of Windows hosts | 0 records | The tag "Windows" does not exist as written. Use `osType`. |
| J | Entities with certain tags (blurry) | Looks like 0 records | Tag text must match exactly. Use `contains()` after checking real tags. |

## Summary

Cell H is the good pattern: `classicEntitySelector` lets you reuse the old Dynatrace tag selector inside DQL. Cells I and J return nothing for the same reason: they compare tags to a text that is not exactly how the tags are stored. Always look at the real tag values before you filter on them.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| Tag | A label on an entity, such as `ADJ`, `env:prod` or `[AWS]Name:web01`. | Used to group hosts and services. |
| Tag format | Tags can have a context in brackets, a key and a value: `[context]key:value`. | An exact filter must match all of it. |
| `classicEntitySelector()` | Runs an old-style selector like `type(HOST),tag(ADJ)` and returns matching IDs. | Easy way to filter by tag in DQL. |
| `in(x, list)` | True when x is in the list. | Checks if a host is in the ADJ set. |
| `entityAttr()` | Reads a field of an entity from inside a `timeseries` query. | Gets tags or OS type for each host line. |
| `iAny()` | True if any item of a list matches a condition. | Used on tag lists. |
| `arrayAvg()` | Average of all points in a time series. | Turns a line into one number. |

### Cell G: service to host name (seen before, more rows)

| Row | Meaning |
|---|---|
| `Requests on 10.94.88.71:7010` on `cm-flowable-bpm-service-...` | A service named after the IP and port it listens on, running in a pod |
| `AXAAsia_UnderwritingReject...` on `EIP - th-bpms-...` | One service on several hosts gives several rows |
| `ClaimCenter (/cc)` with host `null` | No monitored host. Usually a service seen only from the caller side |
| `party-compass-system-api.alj.intraxa` with host `null` | A remote or external service, known only by its address |
| `Elasticsearch SAG_EventDataStore on port 9240` on 4 `WPALJA21xx` hosts | A cluster: same service, four servers |
| `wm.server.dispatcher` on `id-local-apis-...` | webMethods dispatcher running in three pods |
| 1,000 records with a warning | Cut at the default limit |

### Cell H: services on ADJ-tagged hosts (works)

```
fetch dt.entity.service
| filter in(runs_on[dt.entity.host], classicEntitySelector("type(HOST),tag(ADJ)"))
| expand dt.entity.host = runs_on[dt.entity.host]
| fieldsAdd service.name = entity.name, host.name = entityName(dt.entity.host)
| fields service.name, host.name
```

| Line | What it does |
|---|---|
| `classicEntitySelector("type(HOST),tag(ADJ)")` | Gets the IDs of all hosts tagged ADJ |
| `filter in(runs_on[...], ...)` | Keeps services where at least one host is an ADJ host |
| `expand` | One row per host of each kept service |
| `fieldsAdd ... entityName()` | Readable service and host names |

| Result | Meaning |
|---|---|
| 134 records, no warning | The full list, nothing cut |
| `PolicyCenter (/pc)` on `pc2-ui-insuite-prod-0` to `-6` | Seven pods of PolicyCenter |
| `Alfresco (/alfresco)` on `alfrescoacr-insuite-prod-0` to `-3` | Four Alfresco pods |
| `digital-portal-adj-claim-customer-frontend` and `nodejs-api-base` | Portal pods |
| `SWXMIGP` on `lp1gwd02.axa-direct-jp.intraxa` | A classic Linux server |

One subtle point. The filter runs before `expand`. If a service runs on one ADJ host and one non-ADJ host, both hosts appear. Put the filter after `expand` and test each host to get only ADJ hosts. That version is in the improved DQL file.

### Cell I: Windows CPU, 0 records

```
timeseries cpu_usage = avg(dt.host.cpu.usage), by:{dt.entity.host}
| fieldsAdd tags = entityAttr(dt.entity.host, "tags")
| filter iAny(tags[] == "Windows")
| fieldsAdd entityName(dt.entity.host)
| fieldsAdd average_usage = arrayAvg(cpu_usage)
```

| Line | What it does |
|---|---|
| `timeseries avg(dt.host.cpu.usage) by host` | One CPU line per host |
| `entityAttr(dt.entity.host, "tags")` | Adds each host's tag list |
| `iAny(tags[] == "Windows")` | Keeps hosts where some tag is exactly `Windows` |
| `arrayAvg(cpu_usage)` | One average number per host |

Why 0 records:

| Possible cause | Explanation |
|---|---|
| No tag is exactly `Windows` | Real tags usually look like `OS:Windows`, `[Environment]Windows` or `os_type:windows`. An exact compare fails. |
| Case | `windows` and `Windows` are different in an exact compare. |
| Windows is not a tag at all | The operating system is a host field, `osType`, with the value `WINDOWS`. |

The query logic is fine. Only the filter value is wrong. Filter on `osType` instead. It is more reliable than a tag that someone has to set by hand.

### Cell J: tags across many entity types (blurry)

The photo is out of focus, so this is the general shape, not exact text:

```
fetch dt.entity.host
| append [ fetch dt.entity.service ]
| append [ fetch dt.entity.process_group_instance ]
// | append [ ... another entity type, commented out ]
| append [ fetch dt.entity.aws_lambda_function ]   (or a similar cloud type)
// Expand the tags array to filter individual entities
| expand tags
// Apply your environment filters
| filter tags == "[AWS]...:..." or tags == "..." or tags == "env:..." or ...
| fields entity.name, tags
```

| Line | What it does |
|---|---|
| `append` | Stacks several entity tables into one result |
| Lines starting with `//` | Comments. The line does nothing. |
| `expand tags` | One row per tag, so each tag can be compared alone |
| `filter tags == ... or ...` | Keeps rows whose tag equals one of several exact strings |

It seems to end with 0 records. The likely reason is the same as cell I: each `==` needs the full tag text, including the `[AWS]` context, the key and the value, with the same case. One wrong character and nothing matches. Run the tag check query first, then match with `contains()`.

Send a sharper photo of cell J to get an exact line-by-line explanation.

## Result

| Cell | Verdict | Fix |
|---|---|---|
| G | Works, cut at 1,000 | `| limit 10000` |
| H | Works | Filter after `expand` for an exact host list |
| I | Wrong filter value | `entityAttr(dt.entity.host, "osType") == "WINDOWS"` |
| J | Exact tag match fails (likely) | Look at real tags, then use `contains()` |

Common mistakes:

| Mistake | How to avoid it |
|---|---|
| Guessing tag text | Run `fetch dt.entity.host | fields entity.name, tags | limit 20` first |
| Using a tag for something Dynatrace already knows | Use built-in fields such as `osType` |
| Filtering a list before `expand` | Expand first when you want each item tested |
| Exact `==` on tags | `contains()` or `matchesPhrase()` with case-insensitive matching |

## Data flow map

```
Old selector:  type(HOST),tag(ADJ) → classicEntitySelector → list of host IDs
                                               ↓
dt.entity.service ── runs_on ──→ host IDs ── in(...) ──→ cell H (134 rows)

dt.host.cpu.usage → timeseries by host → entityAttr(tags or osType) → filter → cell I

dt.entity.host + service + process + cloud → append → expand tags → filter → cell J
```

## Related files

| File | What it is |
|---|---|
| `4-dynatrace-notebook-queries-part3-explain-improved.dql` | Fixed versions of cells H, I and J, plus a tag check |
| `3-dynatrace-notebook-queries-part2-explain/` | Part 2 |
| `2-dynatrace-notebook-queries-explain/` | Part 1 |
| `3-glossary.md` | Terms |
| `4.sh` | Git one-liners |

## Commands

The queries run in the Dynatrace Notebook. Copy them from the improved DQL file. `4.sh` has only git lines. Nothing has been run.
