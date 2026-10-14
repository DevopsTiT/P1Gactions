# BILoss Retrieve Files CMX DQL

## Decision tree

```
Splunk → DQL
 host="BILoss-retrieve-files-cmx-prod"  → lower(host.name) == "biloss-retrieve-files-cmx-prod" (Splunk host match ignores case)
 search (7 phrases, OR)                 → 7 contains(..., caseSensitive:false) joined by or
 mvappend(if(match(...)))               → arrayRemoveNulls(array(if(contains(...))))  case sensitive, like match()
 no "where isnotnull" here              → lowercase-only lines stay, with an empty keyword list
 strftime, table                        → formatTimestamp, fields
 empty? → check query → name in log.source or pod field? → swap the host filter
```

## Short takeaway

| Question | Answer |
|---|---|
| What does it find? | Error lines from BILoss-retrieve-files-cmx-prod with any of 7 phrases, tagged with which phrases matched. |
| Host match | Case insensitive, so `lower(host.name)` is used. |
| Search | Case insensitive, like Splunk `search`. |
| Tags | Case sensitive, like Splunk `match()`. |
| Difference from answer 4 | No `isnotnull` step, so a line with only lowercase "nullpointerexception" still shows, with an empty tag list. Same as Splunk. |

## Summary

Same shape as the envelope search in answer 1. One host, seven phrases, a tag list, a time column and the raw line. Each Splunk stage has a direct DQL step.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| CMX | The external API this service calls to retrieve files. | `CmxApiException` means that call failed. |
| `mvappend` | Splunk list builder. | DQL `array()`. |
| `arrayRemoveNulls` | Drops empty items from a list. | Matches how `mvappend` skips `null()`. |
| `lower()` | Turns text into lowercase. | Makes the host match case insensitive. |

### Splunk to DQL

| Splunk | DQL |
|---|---|
| `host="BILoss-retrieve-files-cmx-prod"` | `filter lower(host.name) == "biloss-retrieve-files-cmx-prod"` |
| `search ("CC Error" OR "CmxApiException" OR "NetworkException" OR "RuntimeException" OR "Failed to initialize clients" OR "Failed getCCInformations" OR "NullPointerException")` | Seven `contains(content, "...", caseSensitive:false)` joined by `or` |
| `if(match(_raw, "CC Error"), "CC Error", null())` and the other six | `if(contains(content, "CC Error"), "CC Error")` and the other six inside `arrayRemoveNulls(array(...))` |
| `eval time=strftime(_time, "%Y-%m-%d %H:%M:%S %Z")` | `formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")` |
| `table time host matched_keywords _raw` | `fields time, host.name, matched_keywords, content` |

## Result

```
fetch logs, from:now()-24h
| filter lower(host.name) == "biloss-retrieve-files-cmx-prod"
| filter contains(content, "CC Error", caseSensitive:false)
    or contains(content, "CmxApiException", caseSensitive:false)
    or contains(content, "NetworkException", caseSensitive:false)
    or contains(content, "RuntimeException", caseSensitive:false)
    or contains(content, "Failed to initialize clients", caseSensitive:false)
    or contains(content, "Failed getCCInformations", caseSensitive:false)
    or contains(content, "NullPointerException", caseSensitive:false)
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(contains(content, "CC Error"), "CC Error"),
    if(contains(content, "CmxApiException"), "CmxApiException"),
    if(contains(content, "NetworkException"), "NetworkException"),
    if(contains(content, "RuntimeException"), "RuntimeException"),
    if(contains(content, "Failed to initialize clients"), "Failed to initialize clients"),
    if(contains(content, "Failed getCCInformations"), "Failed getCCInformations"),
    if(contains(content, "NullPointerException"), "NullPointerException")
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, matched_keywords, content
```

### Example output row

| time | host.name | matched_keywords | content |
|---|---|---|---|
| 2026-10-14 09:55:40 JST | BILoss-retrieve-files-cmx-prod | ["CmxApiException", "Failed getCCInformations"] | `ERROR Failed getCCInformations ... CmxApiException: 503` |

### If it returns 0

| Check query shows the name in | Change the first filter to |
|---|---|
| `log.source` | `filter contains(log.source, "retrieve-files-cmx", caseSensitive:false)` |
| `k8s.pod.name` | `filter startsWith(lower(k8s.pod.name), "biloss-retrieve-files-cmx-prod")` |
| Nowhere | Logs not in Dynatrace. Use 2026-10-13 answer 3. |

The `.dql` file also has a count per keyword.

## Data flow map

```
BILoss-retrieve-files-cmx-prod logs
  → Dynatrace Grail ? (check query)
  → fetch logs, last 24 h → this host (any case)
  → keep lines with any of 7 phrases (any case)
  → tag with exact-case phrases
  → JST time → newest first → time, host, keywords, line
```

## Related files

| File | What it holds |
|---|---|
| `6-biloss-retrieve-files-cmx-dql.dql` | Main query, check and count per keyword. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | Stage mapping. |
| `2-result.md` | Final query. |
| `3-glossary.md` | Words used. |
| `6.sh` | Git one-liners. |
| `Daily Files/2026-10-14/1-envelope-exception-spl-to-dql/` | Same pattern for the envelope services. |

## Commands

Run the queries in a Dynatrace Notebook. Git one-liners are in [`6.sh`](./6.sh). Nothing was run.

```bash
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/6-biloss-retrieve-files-cmx-dql
git commit -m "BILoss retrieve files CMX DQL"
git push
```
