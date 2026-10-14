# BILoss Upload To CMX DQL

## Decision tree

```
Run the main DQL
 rows returned? → done, check matched_keywords column
 0 rows?
   → run the check query (search "upload-to-cmx")
     name found in k8s.pod.name? → filter on coalesce(k8s.pod.name, host.name)
     name found in host.name with other spelling? → fix the filter value
     nothing found? → logs only go to S3 / Splunk → onboarding request (like eopt)
 rows but matched_keywords empty? → keyword in different case → add caseSensitive:false to the if() checks
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the Splunk search do? | Finds lines from one host that contain any of 3 error phrases. |
| Which host? | `BILoss-upload-to-cmx-prod` |
| Which phrases? | `CMX Error`, `RuntimeException`, `Failed to initialize clients` |
| DQL host filter | `lower(host.name) == "biloss-upload-to-cmx-prod"` |
| DQL keyword filter | `contains(..., caseSensitive:false)` joined with `or` |
| Tag column | `arrayRemoveNulls(array(if(...)))` |

## Summary

This is the same pattern as seq 8, but for one host and three phrases. The filter ignores case like Splunk's `search`, and the tag column is case-sensitive like Splunk's `match()`.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| DQL | Dynatrace Query Language, the query language for Grail. |
| Grail | The Dynatrace storage where logs live. |
| `content` | The raw log line. Same as Splunk `_raw`. |
| `timestamp` | When the line happened. Same as Splunk `_time`. |
| `contains()` | True when the text appears in the field. |
| `arrayRemoveNulls()` | Removes empty entries from a list. |

### Splunk to DQL mapping

| Splunk piece | DQL piece | Why |
|---|---|---|
| `host="BILoss-upload-to-cmx-prod"` | `lower(host.name) == "biloss-upload-to-cmx-prod"` | Splunk `host=` ignores case. `lower()` copies that. |
| `search ("CMX Error" OR ...)` | `contains(..., caseSensitive:false)` | Splunk `search` ignores case. |
| `match(_raw, "CMX Error")` | `contains(content, "CMX Error")` | `match()` is case-sensitive. Plain `contains()` is too. |
| `mvappend(if(...), null())` | `arrayRemoveNulls(array(if(...)))` | Builds the list of matched phrases. |
| `strftime(_time, ...)` | `formatTimestamp(..., timezone:"Asia/Tokyo")` | Readable time in JST. |
| `table time host matched_keywords _raw` | `sort timestamp desc` then `fields ...` | Sort first while `timestamp` still exists. |

## Result

Main DQL (also in `9-biloss-upload-to-cmx-dql.dql`):

```
fetch logs, from:now()-24h
| filter lower(host.name) == "biloss-upload-to-cmx-prod"
| filter contains(content, "CMX Error", caseSensitive:false)
    or contains(content, "RuntimeException", caseSensitive:false)
    or contains(content, "Failed to initialize clients", caseSensitive:false)
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(contains(content, "CMX Error"), "CMX Error"),
    if(contains(content, "RuntimeException"), "RuntimeException"),
    if(contains(content, "Failed to initialize clients"), "Failed to initialize clients")
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, matched_keywords, content
```

Check query (when 0 rows):

```
fetch logs, from:now()-24h
| filter contains(host.name, "upload-to-cmx", caseSensitive:false)
    or contains(log.source, "upload-to-cmx", caseSensitive:false)
    or contains(k8s.pod.name, "upload-to-cmx", caseSensitive:false)
| summarize lines = count(), by:{ host.name, log.source, k8s.pod.name, dt.openpipeline.source }
```

Count per keyword:

```
fetch logs, from:now()-24h
| filter lower(host.name) == "biloss-upload-to-cmx-prod"
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(contains(content, "CMX Error"), "CMX Error"),
    if(contains(content, "RuntimeException"), "RuntimeException"),
    if(contains(content, "Failed to initialize clients"), "Failed to initialize clients")
  ))
| expand matched_keywords
| filter isNotNull(matched_keywords)
| summarize lines = count(), by:{ matched_keywords }
| sort lines desc
```

## Data flow map

```
BILoss-upload-to-cmx-prod
  -> log lines
  -> Dynatrace Grail (fetch logs)
  -> filter: host matches (case ignored)
  -> filter: any of 3 phrases (case ignored)
  -> tag: which phrases matched (case-sensitive)
  -> time: format in JST
  -> sort newest first
  -> table: time | host.name | matched_keywords | content
```

## Related files

| File | What it holds |
|---|---|
| `9-biloss-upload-to-cmx-dql.dql` | Main, check, and count queries |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Mapping details |
| `2-result.md` | Final DQL |
| `3-glossary.md` | Glossary |
| `9.sh` | Git one-liners |

## Commands

See `9.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/9-biloss-upload-to-cmx-dql
git commit -m "BILoss upload to CMX DQL"
git push
```
