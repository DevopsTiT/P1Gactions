# PayWithCreditCard DQL Final

## Decision tree

```
Splunk step                              → DQL step
sourcetype="portals-amp-backend"         → startsWith(src, "portals-amp-backend")
earliest=-1h                             → fetch logs, from:now()-1h
(speed) words in base search             → contains(content, ...) before parsing
replace \" → " and delete \              → replaceString(...) only if \" is present
spath                                    → parse raw, "JSON:j"
message.url=*payWithCreditCard_Adj*      → contains(msg_url, "payWithCreditCard_Adj")
message.type="EXECUTION_COMPLETED"       → msg_type == "EXECUTION_COMPLETED"

Run it:
 rows ≈ Splunk count → done
 0 rows → logs not onboarded yet (answer 21)
 rows but msg_url empty → JSON not parsed → check one raw line
```

## Short takeaway

| Question | Answer |
|---|---|
| Final DQL | In the Result section and in `24-paywithcreditcard-dql-final.dql`. |
| Main difference from answer 13 | URL uses `contains()`, because the field is a full URL. |
| Why the `if(contains(content, "\\\""))`? | Cleans backslashes only when they exist, so it works whether the logs arrive escaped or clean. |
| Why `contains(content, ...)` before `parse`? | Fewer lines to parse. Same trick as the faster Splunk version. |
| Will it return rows today? | No. portals-amp logs are not in Dynatrace yet. |

## Summary

The DQL follows the Splunk query step by step: pick the app and hour, clean the JSON, parse it, and filter on URL and type. Two small improvements make it safer: a quick text filter before parsing, and cleaning backslashes only when they are present.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| `src` | Helper field: pod name, or host name if there is no pod name. |
| `replaceString()` | DQL text replace (Splunk `replace`). |
| `parse raw, "JSON:j"` | Read JSON into a record `j` (Splunk `spath`). |
| `j[message][url]` | The `url` inside `message`. |
| `toString()` | Turns a value into text so it can be compared. |

### Step by step

| # | Splunk | DQL | Why |
|---|---|---|---|
| 1 | `earliest=-1h` | `fetch logs, from:now()-1h` | Same time window. |
| 2 | `sourcetype="portals-amp-backend"` | `startsWith(src, "portals-amp-backend")` | Splunk shows the pod name as host (`portals-amp-backend-5f57cbc7-...`). |
| 3 | (not in the original) | `contains(content, "payWithCreditCard_Adj") and contains(content, "EXECUTION_COMPLETED")` | Cheap pre-filter. Parsing fewer lines is faster. |
| 4 | `replace(_raw,"\\\\\"","\"")` | `replaceString(content, "\\\"", "\"")` | Turn `\"` into `"`. |
| 5 | `replace(_raw,"\\\\","")` | `replaceString(..., "\\", "")` | Delete leftover `\`. |
| 6 | `spath` | `parse raw, "JSON:j"` | JSON to fields. |
| 7 | `message.url=*payWithCreditCard_Adj*` | `contains(msg_url, "payWithCreditCard_Adj")` | Stars mean "contains". |
| 8 | `message.type="EXECUTION_COMPLETED"` | `msg_type == "EXECUTION_COMPLETED"` | Exact match. |
| 9 | (event list) | `sort timestamp desc` then `fields ...` | Newest first, useful columns. |

### Escaping in DQL strings

| You type in DQL | It means |
|---|---|
| `"\\\""` | backslash then quote |
| `"\""` | one quote |
| `"\\"` | one backslash |

DQL `replaceString` is plain text, not regex, so it needs fewer backslashes than Splunk.

## Result

```
fetch logs, from:now()-1h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "portals-amp-backend")
| filter contains(content, "payWithCreditCard_Adj") and contains(content, "EXECUTION_COMPLETED")
| fieldsAdd raw = if(contains(content, "\\\""),
                     replaceString(replaceString(content, "\\\"", "\""), "\\", ""),
                     else: content)
| parse raw, "JSON:j"
| fieldsAdd level         = toString(j[level]),
            msg_type      = toString(j[message][type]),
            msg_url       = toString(j[message][url]),
            method        = toString(j[message][method]),
            request_id    = toString(j[message][request_id]),
            target_system = toString(j[message][target_system])
| filter contains(msg_url, "payWithCreditCard_Adj") and msg_type == "EXECUTION_COMPLETED"
| sort timestamp desc
| fields timestamp, src, level, msg_type, method, target_system, request_id, msg_url
```

Count to compare with Splunk's 75:

```
fetch logs, from:now()-1h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "portals-amp-backend")
| filter contains(content, "payWithCreditCard_Adj") and contains(content, "EXECUTION_COMPLETED")
| summarize events = count(), by:{ src }
```

Timeline (same as the Splunk bars):

```
fetch logs, from:now()-1h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "portals-amp-backend")
| filter contains(content, "payWithCreditCard_Adj") and contains(content, "EXECUTION_COMPLETED")
| makeTimeseries events = count(), interval:1m
```

| You see | Meaning | Next step |
|---|---|---|
| About 75 rows per hour | Matches Splunk. | Done. |
| 0 rows | Logs not onboarded yet. | Answer 21 request. |
| Rows, but `msg_url` is empty | JSON did not parse. | Look at one raw `content` line and adjust the cleaning. |

## Data flow map

```
portals-amp-backend pod log
  -> (after onboarding) Dynatrace Grail
  -> fetch 1h -> pod prefix -> quick text filter
  -> clean \" if present -> parse JSON
  -> url contains payWithCreditCard_Adj AND type EXECUTION_COMPLETED
  -> newest first -> table
```

## Related files

| File | What it holds |
|---|---|
| `24-paywithcreditcard-dql-final.dql` | Final DQL, count, timeline, failure variant |
| `0-pic.md` | Step map |
| `1-investigation.md` | Mapping notes |
| `2-result.md` | Final query summary |
| `3-glossary.md` | Glossary |
| `24.sh` | Git one-liners |

## Commands

See `24.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/24-paywithcreditcard-dql-final
git commit -m "payWithCreditCard DQL final"
git push
```
