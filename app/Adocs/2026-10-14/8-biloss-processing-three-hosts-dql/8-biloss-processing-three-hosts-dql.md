# BILoss Processing Three Hosts DQL

## Decision tree

```
Splunk → DQL
 (host="BILoss-processing-prod" OR host="BILoss-pre-processing-prod" OR host="BILoss-link-data-to-cc-prod")
                                → in(lower(host.name), array(3 names in lowercase))
 search (7 phrases, OR)         → 7 contains(..., caseSensitive:false) joined by or
 mvappend(if(match(...))) x7    → arrayRemoveNulls(array(if(contains(...)) x7))  case sensitive
 strftime, table                → formatTimestamp, fields
 empty? → check query → name in log.source or pod field? → swap the host filter
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it find? | Error lines from three BILoss services with any of 7 phrases, tagged with the phrases found. |
| Hosts | BILoss-processing-prod, BILoss-pre-processing-prod, BILoss-link-data-to-cc-prod. |
| Host match | Case insensitive, using `lower(host.name)`. |
| Search | Case insensitive. |
| Tags | Case sensitive, like Splunk `match()`. |

## Summary

Same structure as answer 6, with three hosts instead of one and a different phrase list. Each Splunk stage maps to one DQL step.

## Investigation

### Phrases

| Phrase | What it usually means |
|---|---|
| CC Error | Error reported while talking to the CC system. |
| Camunda Error | Error from the Camunda workflow engine. |
| callCamundaProcess error | The service failed when starting a Camunda process. |
| RuntimeException | General Java runtime failure. |
| Failed to initialize clients | API or database clients could not start. |
| PSQLException | PostgreSQL database error. |
| IllegalArgumentException | Bad input passed to a Java method. |

### Splunk to DQL

| Splunk | DQL |
|---|---|
| `(host="BILoss-processing-prod" OR host="BILoss-pre-processing-prod" OR host="BILoss-link-data-to-cc-prod")` | `filter in(lower(host.name), array("biloss-processing-prod", "biloss-pre-processing-prod", "biloss-link-data-to-cc-prod"))` |
| `search (7 phrases)` | Seven `contains(content, "...", caseSensitive:false)` joined by `or` |
| `if(match(_raw, "X"), "X", null())` x7 | `if(contains(content, "X"), "X")` x7 inside `arrayRemoveNulls(array(...))` |
| `eval time=strftime(_time, "%Y-%m-%d %H:%M:%S %Z")` | `formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")` |
| `table time host matched_keywords _raw` | `fields time, host.name, matched_keywords, content` |

## Result

```
fetch logs, from:now()-24h
| filter in(lower(host.name), array("biloss-processing-prod", "biloss-pre-processing-prod", "biloss-link-data-to-cc-prod"))
| filter contains(content, "CC Error", caseSensitive:false)
    or contains(content, "Camunda Error", caseSensitive:false)
    or contains(content, "callCamundaProcess error", caseSensitive:false)
    or contains(content, "RuntimeException", caseSensitive:false)
    or contains(content, "Failed to initialize clients", caseSensitive:false)
    or contains(content, "PSQLException", caseSensitive:false)
    or contains(content, "IllegalArgumentException", caseSensitive:false)
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(contains(content, "CC Error"), "CC Error"),
    if(contains(content, "Camunda Error"), "Camunda Error"),
    if(contains(content, "callCamundaProcess error"), "callCamundaProcess error"),
    if(contains(content, "RuntimeException"), "RuntimeException"),
    if(contains(content, "Failed to initialize clients"), "Failed to initialize clients"),
    if(contains(content, "PSQLException"), "PSQLException"),
    if(contains(content, "IllegalArgumentException"), "IllegalArgumentException")
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, matched_keywords, content
```

### Example output row

| time | host.name | matched_keywords | content |
|---|---|---|---|
| 2026-10-14 10:20:11 JST | BILoss-processing-prod | ["callCamundaProcess error", "RuntimeException"] | `ERROR callCamundaProcess error ... java.lang.RuntimeException: ...` |

### If it returns 0

| Check query shows the names in | Change the first filter to |
|---|---|
| `log.source` | `filter contains(log.source, "biloss-processing-prod", caseSensitive:false) or contains(log.source, "biloss-pre-processing-prod", caseSensitive:false) or contains(log.source, "biloss-link-data-to-cc-prod", caseSensitive:false)` |
| `k8s.pod.name` | Same three names with `startsWith(lower(k8s.pod.name), ...)` |
| Nowhere | Logs not in Dynatrace. Use 2026-10-13 answer 3. |

The `.dql` file also has a count per host and keyword.

## Data flow map

```
BILoss-processing-prod, BILoss-pre-processing-prod, BILoss-link-data-to-cc-prod
  → Dynatrace Grail ? (check query)
  → fetch logs, last 24 h → these 3 hosts (any case)
  → keep lines with any of 7 phrases (any case)
  → tag with exact-case phrases
  → JST time → newest first → time, host, keywords, line
```

## Related files

| File | What it holds |
|---|---|
| `8-biloss-processing-three-hosts-dql.dql` | Main query, check and count per host and keyword. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | Stage mapping. |
| `2-result.md` | Final query. |
| `3-glossary.md` | Words used. |
| `8.sh` | Git one-liners. |
| `Daily Files/2026-10-14/6-biloss-retrieve-files-cmx-dql/` | Same pattern for the retrieve-files host. |

## Commands

Run the queries in a Dynatrace Notebook. Git one-liners are in [`8.sh`](./8.sh). Nothing was run.

```bash
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/8-biloss-processing-three-hosts-dql
git commit -m "BILoss processing three hosts DQL"
git push
```
