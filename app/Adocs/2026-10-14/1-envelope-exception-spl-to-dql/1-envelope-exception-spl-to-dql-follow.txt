# Envelope Exception SPL To DQL

## Decision tree

```
Splunk search → DQL
 (host="A" OR host="B")          → filter in(host.name, array("A", "B"))
 search ("Exception" OR "ERROR") → contains(content, ..., caseSensitive:false)  (Splunk search ignores case)
 eval mvappend(if(match(...)))   → arrayRemoveNulls(array(if(contains(...), "name"), ...))
 eval time=strftime(_time, ...)  → formatTimestamp(timestamp, format:..., timezone:"Asia/Tokyo")
 table time host keywords _raw   → fields time, host.name, matched_keywords, content
 main query empty?
   → run the check query → names may be in log.source or content, not host.name → swap the filter
```

## Short takeaway

| Question | Answer |
|---|---|
| Can it be translated one to one? | Yes. Each Splunk stage has a direct DQL step. |
| `_raw` | Becomes `content`. |
| `_time` | Becomes `timestamp`. |
| `mvappend` of `if(..., null())` | Becomes `arrayRemoveNulls(array(if(...), ...))`. |
| Case | Splunk `search` ignores case, so the filter uses `caseSensitive:false`. Splunk `match()` is case sensitive, so the keyword checks are case sensitive too. |
| Risk | The two names may not be in `host.name` in Dynatrace. The check query finds where they live. |

## Summary

The search keeps error lines from two services, tags each line with every exception name it contains, and shows time, host, tags and the raw line. The DQL does the same in the same order. If the Splunk `host` value is not stored as `host.name` in Dynatrace, only the first filter line needs to change.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| `_raw` | Splunk's full log line. | DQL calls it `content`. |
| `mvappend` | Splunk function that builds a multi-value field (a list). | DQL uses `array()`. |
| `null()` | Empty value. `mvappend` skips it. | DQL needs `arrayRemoveNulls` to drop empties. |
| `match(_raw, "x")` | Regex test, case sensitive. | Plain words here, so `contains()` gives the same result. |
| `strftime` | Splunk time to text. | DQL uses `formatTimestamp`. |
| `expand` | DQL command that turns one row with a list into one row per item. | Used in the extra count query. |

### Stage by stage

| Splunk | DQL | Note |
|---|---|---|
| `(host="biloss-envelope-list-prod" OR host="start-envelope-executions-prod")` | `filter in(host.name, array("biloss-envelope-list-prod", "start-envelope-executions-prod"))` | If empty, see the check query. |
| `search ("Exception" OR "ERROR")` | `filter contains(content, "Exception", caseSensitive:false) or contains(content, "ERROR", caseSensitive:false)` | Splunk search terms ignore case. |
| `eval matched_keywords=mvappend(...)` | `fieldsAdd matched_keywords = arrayRemoveNulls(array(...))` | One `if()` per keyword. |
| `if(match(_raw,"RuntimeException"),"RuntimeException",null())` | `if(contains(content, "RuntimeException"), "RuntimeException")` | `if()` without `else` gives null. |
| `eval time=strftime(_time,"%Y-%m-%d %H:%M:%S %Z")` | `fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")` | Splunk used your profile time zone. Change the time zone if needed. |
| `table time host matched_keywords _raw` | `fields time, host.name, matched_keywords, content` | `sort timestamp desc` comes before `fields`, because `fields` drops `timestamp`. |
| Time picker | `fetch logs, from:now()-24h` | Change to match your Splunk range. |

### Format codes

| Splunk `strftime` | DQL `formatTimestamp` | Meaning |
|---|---|---|
| `%Y` | `yyyy` | Year |
| `%m` | `MM` | Month |
| `%d` | `dd` | Day |
| `%H` | `HH` | Hour, 24 hour clock |
| `%M` | `mm` | Minute |
| `%S` | `ss` | Second |
| `%Z` | `z` | Time zone short name, such as JST |

## Result

```
fetch logs, from:now()-24h
| filter in(host.name, array("biloss-envelope-list-prod", "start-envelope-executions-prod"))
| filter contains(content, "Exception", caseSensitive:false)
    or contains(content, "ERROR", caseSensitive:false)
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(contains(content, "RuntimeException"), "RuntimeException"),
    if(contains(content, "CmxApiException"), "CmxApiException"),
    if(contains(content, "NetworkException"), "NetworkException"),
    if(contains(content, "PSQLException"), "PSQLException"),
    if(contains(content, "NullPointerException"), "NullPointerException"),
    if(contains(content, "IllegalArgumentException"), "IllegalArgumentException"),
    if(contains(content, "Exception"), "Exception"),
    if(contains(content, "ERROR"), "ERROR")
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, matched_keywords, content
```

### Example output row

| time | host.name | matched_keywords | content |
|---|---|---|---|
| 2026-10-14 08:59:12 JST | start-envelope-executions-prod | ["PSQLException", "Exception", "ERROR"] | `ERROR ... org.postgresql.util.PSQLException: connection refused` |

A line with a specific exception also gets `"Exception"`, because the word is inside the longer name. Splunk does the same.

### If the main query is empty

Run the check query in the `.dql` file. It shows where the two names appear.

| Check query shows the name in | Change the first filter to |
|---|---|
| `host.name` with different case | `filter in(lower(host.name), array("biloss-envelope-list-prod", "start-envelope-executions-prod"))` |
| `log.source` | `filter contains(log.source, "biloss-envelope-list-prod") or contains(log.source, "start-envelope-executions-prod")` |
| Nowhere | The service's logs are not in Dynatrace yet. Use the missing logs logic from 2026-10-13 answer 3. |

### Extra: count per keyword

The `.dql` file also has a query that counts lines per host and keyword with `expand` and `summarize`. It is handy for a dashboard tile.

## Data flow map

```
service logs (biloss-envelope-list-prod, start-envelope-executions-prod)
  → Dynatrace Grail logs
  → fetch logs, last 24 h
  → keep the two hosts
  → keep lines with Exception or ERROR (any case)
  → tag each line with every keyword it contains
  → format time in JST
  → newest first → time, host, keywords, line
```

## Related files

| File | What it holds |
|---|---|
| `1-envelope-exception-spl-to-dql.dql` | Main query, check query and count query. |
| `0-pic.md` | Decision tree and data flow. |
| `1-investigation.md` | Stage mapping. |
| `2-result.md` | Final query notes. |
| `3-glossary.md` | Words used. |
| `1.sh` | Git one-liners. |

## Commands

Run the queries in a Dynatrace Notebook. Git one-liners are in [`1.sh`](./1.sh). Nothing was run.

```bash
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/1-envelope-exception-spl-to-dql
git commit -m "Envelope exception SPL to DQL"
git push
```
