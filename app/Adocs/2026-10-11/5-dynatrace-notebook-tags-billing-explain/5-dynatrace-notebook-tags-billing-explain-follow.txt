# Dynatrace Notebook Tags And Billing

## Decision tree

```
Tag query returns 0 records?
 Did the fetch add tags (| fieldsAdd tags)?        no → tags is empty → add it (cells J and K)
 Is tags compared with == as one string?           yes → tags is a list → use in(...) or expand first (cell K)
 Does the text match exactly (case, [context], key:value)? no → check real tags, compare in lower case (cell J)
 Does the last line use a real field (entity.name)? no → "hosts" does not exist (cell K)

Billing cells
 Per day bar chart flat, first and last bars short → normal; the window starts and ends mid-day (cell L)
 Per host 720.00 hours                             → host was monitored every hour of the 30 days (cell M)
 Per host less than 720                            → part-time host: autoscaled, new, removed, or off at times
 1,000 records with a warning                      → list cut → | limit 10000
```

## Short takeaway

| Cell | What it does | Result | Main point |
|---|---|---|---|
| I | CPU of Windows hosts by tag | 0 records | Explained in part 3. Use `osType == "WINDOWS"`. |
| J | Entities with environment tags across types | 0 records | `tags` was never loaded. Add `fieldsAdd tags` to each fetch. |
| K | Hosts with tag `[AWS]global:env:preprod` | 0 records | Three bugs: tags not loaded, list compared with `==`, `hosts` is not a field. |
| L | Infrastructure Monitoring host-hours per day | 1 series, bar chart | About the same every day, so the host count is stable. |
| M | Host-hours per host | 1,000 rows, cut | 720 means "on for all 30 days". |
| N | Number of billed hosts | Cut off | Likely a count of distinct hosts. |

## Summary

The tag queries all fail for the same hidden reason: when you `fetch` an entity table, Dynatrace returns only a few basic fields, and `tags` is not one of them. Without `fieldsAdd tags`, the filter has nothing to compare. The billing cells come from Dynatrace's own billing events and show how many host-hours of Infrastructure Monitoring you pay for, per day and per host.

## Investigation

### Words you need first

| Term | What it means | Why you care |
|---|---|---|
| Default fields | `fetch dt.entity.host` returns only basic fields such as `id` and `entity.name`. | Other fields, like `tags`, must be added with `fieldsAdd`. |
| Tag | A label like `[AWS]global:env:Preprod`: context in brackets, then key, then value. | Must match exactly in an `==` compare. |
| List field | A field holding many values, like `tags`. | `==` against one string never matches a list. |
| `dt.system.events` | Dynatrace's own internal events, including billing records. | Source of the billing cells. |
| `BILLING_USAGE_EVENT` | A record of how much of a product you used in a time slot. | What you are charged for. |
| Infrastructure Monitoring | A OneAgent mode that watches the host only (CPU, memory, disk, network), without code-level tracing. | Billed in host-hours. |
| Host-hour | One host monitored for one hour. | 24 host-hours a day means one host on all day. |
| `makeTimeseries` | Turns records into a time series, here for a bar chart. | Used in cell L. |
| `dedup event.id` | Keeps one copy of each event. | Billing events can be sent more than once; this stops double counting. |

### Cell I (repeat)

Same cell as in part 3: CPU per host, filtered on a tag exactly equal to `Windows`. Returns 0 records. Use the host field `osType` instead.

### Cell J: environment tags across entity types, 0 records

```
fetch dt.entity.host
| append [fetch dt.entity.service]
| append [fetch dt.entity.process_group_instance]
/// append [fetch dt.entity.rds_instance]
| append [fetch dt.entity.aws_lambda_function]
// Expand the tags array to filter individual entries
| expand tags
// Apply your environment filters
| filter
    tags == "[AWS]ADJ:env:openShift:Preprod" or
    tags == "[AWS]global:env:Preprod" or
    tags == "[AWS]ADJ:env:Preprod" or
    tags == "env:Dev" or
    tags == "env:preProd"
| fields entity.name, tags
```

| Line | What it does |
|---|---|
| `fetch dt.entity.host` | All hosts |
| `append [...]` | Adds services, process instances and AWS Lambda functions under the hosts |
| `/// append [... rds_instance]` | Commented out. AWS RDS databases are skipped. |
| `expand tags` | Should give one row per tag |
| `filter tags == ... or ...` | Keeps rows whose tag equals one of five texts |
| `fields entity.name, tags` | Shows the name and the matching tag |

Why 0 records:

| Cause | Explanation | Fix |
|---|---|---|
| `tags` was never loaded | None of the four `fetch` commands adds `tags`, so the field is empty and `expand` gives nothing to compare | `| fieldsAdd tags` after every `fetch`, including inside each `append` |
| Exact text and case | `env:preProd` and `env:Preprod` are different. The first three tags must also have the exact `[AWS]` context and key layout | Compare in lower case, after checking the real tags |
| Tag layout guess | A text like `[AWS]ADJ:env:openShift:Preprod` reads as key `ADJ` with value `env:openShift:Preprod`. The real tag may be built differently | Run query 0 in the improved file to see the real text |

### Cell K: one tag on hosts, 0 records

```
fetch dt.entity.host
| filter
    tags == "[AWS]global:env:preprod"
| fields name = hosts
```

| Bug | Explanation | Fix |
|---|---|---|
| `tags` not loaded | Same as cell J | `| fieldsAdd tags` |
| List compared with `==` | `tags` is a list of many tags. A list is never equal to one string | `in("[AWS]global:env:Preprod", tags)` |
| Lower-case `preprod` | Cell J used `Preprod` | Use the case seen in the real tag, or compare in lower case |
| `fields name = hosts` | There is no field called `hosts` | `fields name = entity.name` |

### Infrastructure Monitoring section

This section looks like Dynatrace's ready-made billing notebook. All cells read `dt.system.events` and keep only Infrastructure Monitoring billing records.

#### Cell L: total usage billed per day

```
fetch dt.system.events
| filter event.kind == "BILLING_USAGE_EVENT" and event.type == "Infrastructure Monitoring"
| dedup event.id
| makeTimeseries total_billed_usage = sum(billed_host_hours), interval: 24h, time: usage.start
```

| Line | What it does |
|---|---|
| `filter event.kind ... event.type ...` | Only billing records for Infrastructure Monitoring |
| `dedup event.id` | One copy per billing record |
| `makeTimeseries ... interval:24h, time:usage.start` | Adds up host-hours per day, using the time the usage happened |

| Result | Meaning |
|---|---|
| One bar per day, end of February to end of March | 30 days |
| Bars almost the same height | The number of monitored hosts is steady |
| First and last bars shorter | The window starts and ends at 10:52, so those days are partial. Not a real drop. |
| Bar height divided by 24 | Roughly how many hosts were on that day |

#### Cell M: total usage per host

```
fetch dt.system.events
| filter event.kind == "BILLING_USAGE_EVENT" and event.type == "Infrastructure Monitoring"
| dedup event.id
| summarize billed_hours = sum(billed_host_hours), by:{dt.entity.host}
| fields host_id = dt.entity.host, host_name = entityAttr(dt.entity.host, "entity.name"), billed_hours
| sort billed_hours DESC
```

| Result | Meaning |
|---|---|
| Timeframe 2/28 10:52 to 3/30 10:52 | Exactly 30 days, which is 720 hours |
| `720.00` on the top hosts | Those hosts were monitored every hour of the 30 days: always-on servers |
| Names like `WPALJA3072.prprivmgmt.intraxa`, `wjp1dba01.axa-direct-jp.intraxa`, `WNCSQL17.krungthai-axa.co.th` | Windows and Linux servers across Japan and Thailand estates |
| 1,000 records with a warning | Cut. Hosts with fewer hours are lower in the list and may be missing. |

How to use it:

| Question | How to answer |
|---|---|
| Which hosts cost the most? | All 720-hour hosts cost the same in this mode. Count them. |
| Which hosts come and go? | Look at hosts under 720 hours (query M2) |
| Are we paying for dead hosts? | A host with 720 hours that nobody uses is a clean-up candidate |

#### Cell N: number of billed hosts

Only the title is visible. It most likely counts distinct hosts in the same billing records. A likely version is in the improved file.

## Result

| Cell | Verdict | Fix |
|---|---|---|
| I | Wrong filter value | `osType == "WINDOWS"` |
| J | Tags not loaded, exact text | `fieldsAdd tags` in every fetch, compare in lower case |
| K | Three bugs | `fieldsAdd tags`, `in(..., tags)`, `entity.name` |
| L | Works | Ignore the short first and last bars |
| M | Works, cut | `| limit 10000`; `entityName()` is simpler than `entityAttr` |
| N | Cut off | Count distinct hosts |

Common mistakes:

| Mistake | How to avoid it |
|---|---|
| Expecting every field from `fetch dt.entity.*` | Add fields you need with `fieldsAdd` |
| Comparing a list with `==` | Use `in(value, list)` or `expand` first |
| Guessing tag text | Run query 0 to list real tags |
| Reading partial days as drops | Check the timeframe start and end times |
| Forgetting `dedup event.id` on billing | Totals become too high |

## Data flow map

```
Tags
  fetch dt.entity.* → (missing: fieldsAdd tags) → expand tags → filter → 0 records
  fetch dt.entity.* → fieldsAdd tags → expand tags → lower-case match → results

Billing
  OneAgent hosts in Infrastructure Monitoring mode
    → Dynatrace billing → dt.system.events (BILLING_USAGE_EVENT)
    → dedup event.id
    ├─ per day  → makeTimeseries 24h → bar chart (cell L)
    ├─ per host → summarize by host → 720 = always on (cell M)
    └─ count    → distinct hosts (cell N)
```

## Related files

| File | What it is |
|---|---|
| `5-dynatrace-notebook-tags-billing-explain-improved.dql` | Fixed tag queries and extra billing queries |
| `4-dynatrace-notebook-queries-part3-explain/` | Part 3, with cell I first explained |
| `3-glossary.md` | Terms |
| `5.sh` | Git one-liners |

## Commands

The queries run in the Dynatrace Notebook. `5.sh` has only git lines. Nothing has been run.
