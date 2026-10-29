# Common DQL Queries

```
Need a Dynatrace answer
  latest errors? → fetch logs, filter ERROR, limit 50
  a service name in the text? → contains on content, caseSensitive:false
  which source is noisiest? → summarize count by log.source
  is a problem open? → fetch dt.davis.problems, status ACTIVE
  which call is slow? → fetch spans, average duration
```

| Question | Query starts with |
|---|---|
| What failed just now? | `fetch logs` |
| Where is this service mentioned? | `fetch logs` plus `contains` |
| Which source produces the most errors? | `fetch logs` plus `summarize` |
| What is still open? | `fetch dt.davis.problems` |
| Which call is slow? | `fetch spans` |

## Summary

A common DQL query loads one kind of data, filters it, then either lists rows or counts them. Paste these in a Notebook DQL section. If you leave out `from:`, Dynatrace uses the time range selected in the page, and the default is the last 2 hours.

## Investigation

| Source | Finding |
|---|---|
| How to use DQL | The starter query is `fetch logs`, then `filter`, then `summarize`. |
| Davis examples | Open problems come from `dt.davis.problems` with `event.status == "ACTIVE"`. |
| Span examples | Duration and database calls come from `fetch spans`. |
| This account | Every `contains` includes `caseSensitive:false`. |

## Result

Paste one query at a time into Notebooks → Add → DQL, then Run.

### Latest error logs

Use this when a page just fired and you want the newest error lines.

```
fetch logs, from: now() - 2h
| filter loglevel == "ERROR"
| fields timestamp, log.source, content
| sort timestamp desc
| limit 50
```

| Line | What it does |
|---|---|
| fetch logs | Loads log records from the last 2 hours. |
| filter | Keeps rows whose level is ERROR. |
| fields | Shows only the time, the source, and the message. |
| sort and limit | Newest 50 lines. |

### Logs that mention a service

Use this when you know the service name and want the lines that contain it. Change the text inside the quotes.

```
fetch logs, from: now() - 2h
| filter contains(content, "ebroker-api", caseSensitive:false)
| fields timestamp, loglevel, content
| sort timestamp desc
| limit 50
```

`caseSensitive:false` means `Ebroker-API` and `ebroker-api` both match.

For a Kubernetes container name:

```
fetch logs, from: now() - 1h
| filter contains(k8s.container.name, "ebroker", caseSensitive:false)
| fields timestamp, k8s.pod.name, k8s.container.name, content
| sort timestamp desc
| limit 50
```

### Which source has the most errors

Use this when the error list is long and you need the noisy source first.

```
fetch logs, from: now() - 2h
| filter loglevel == "ERROR"
| summarize errorCount = count(), by: {log.source}
| sort errorCount desc
| limit 10
```

`summarize` collapses many lines into one row per log source, with a count.

### Open problems

Use this when you want the Davis problems that are still active. A problem is Dynatrace’s detected incident, the same kind of id that can show up on a PagerDuty event.

```
fetch dt.davis.problems, from: now() - 24h
| filter event.status == "ACTIVE"
| fields display_id, event.status, event.category
| limit 20
```

### Slow calls

Use this when the symptom is slowness. `duration` on a span is in nanoseconds, so the last line converts the average to milliseconds.

```
fetch spans, from: now() - 1h
| filter contains(span.name, "ebroker", caseSensitive:false)
| summarize calls = count(), avgMs = avg(duration) / 1000000, by: {span.name}
| sort avgMs desc
| limit 10
```

### The shape to reuse

```
fetch <logs or spans or dt.davis.problems>, from: now() - 2h
| filter <the rows you want>
| summarize <a count>, by: {<the group>}
| sort <the count> desc
| limit 20
```

## Data flow map

```
Notebook DQL box
    -> fetch the data
    -> filter the rows
    -> fields to read lines, or summarize to count
    -> sort and limit
    -> table on the page
```

## Related files

| File | What it is |
|---|---|
| 4-common-dql-queries-follow.txt | The same queries, easy to copy. |
| 0-pic.md | Which question uses which fetch. |
| 1-investigation.md | Which docs these patterns come from. |
| 2-result.md | The five queries. |
| 3-glossary.md | The words in the queries. |
| 4.sh | Copy commands. Run them yourself. |
