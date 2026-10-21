# BILoss DQL Filter From Log Example

```
Have a Splunk hit (CC Error on BILoss-link-data-to-cc-prod)?
 → Copy hosts + phrases exactly from Splunk
 → Filter content for those phrases (message text is inside the Lambda JSON)
 → if(cond, "tag") — no , null
 → Dummy with a piece of the real message → matched_keywords = CC Error
```

| Key point | Detail |
|---|---|
| Example host | `BILoss-link-data-to-cc-prod` |
| Example phrase in message | `CC Error while trying to call CC Financial judgement API` |
| Splunk style | `mvappend` + `if(match(_raw,…), …, null())` → DQL `arrayRemoveNulls(array(if(...)))` |

## Summary

This DQL mirrors your Splunk search. The filter looks for the same three `BILoss-*` hosts and the same seven phrases. A short piece of your real log line is enough for a dummy verify.

## Example log piece (from your Splunk `_raw`)

Use this fragment (the useful part inside `logEvents[].message`):

```
[main] ERROR jp.co.axa.api.ClaimCenterClient - CC Error while trying to call CC Financial judgement API - Error type: SocketTimeoutException, Message: timeout
```

Also present nearby: `logGroup":"/aws/lambda/BILoss-link-data-to-cc-prod"`.

---

## Live DQL filter (paste in Notebook)

```
fetch logs, from:now()-24h
| filter host.name == "BILoss-processing-prod"
    or host.name == "BILoss-pre-processing-prod"
    or host.name == "BILoss-link-data-to-cc-prod"
    or contains(aws.log_group, "BILoss-", caseSensitive:false)
    or contains(log.source, "BILoss-", caseSensitive:false)
| filter matchesPhrase(content, "CC Error")
    or matchesPhrase(content, "Camunda Error")
    or matchesPhrase(content, "callCamundaProcess error")
    or matchesPhrase(content, "RuntimeException")
    or matchesPhrase(content, "failed to initialize clients")
    or matchesPhrase(content, "PSQLException")
    or matchesPhrase(content, "IllegalArgumentException")
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(matchesPhrase(content, "CC Error"), "CC Error"),
    if(matchesPhrase(content, "Camunda Error"), "Camunda Error"),
    if(matchesPhrase(content, "callCamundaProcess error"), "callCamundaProcess error"),
    if(matchesPhrase(content, "RuntimeException"), "RuntimeException"),
    if(matchesPhrase(content, "failed to initialize clients"), "failed to initialize clients"),
    if(matchesPhrase(content, "PSQLException"), "PSQLException"),
    if(matchesPhrase(content, "IllegalArgumentException"), "IllegalArgumentException")
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss.SSS", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, matched_keywords, content
```

Same phrases as Splunk `| search ("CC Error" OR …)` and same tags as `mvappend(if(match(_raw,…)))`.

---

## Dummy verify (part of your log)

```
data record(
    host.name: "BILoss-link-data-to-cc-prod",
    aws.log_group: "/aws/lambda/BILoss-link-data-to-cc-prod",
    content: "[main] ERROR jp.co.axa.api.ClaimCenterClient - CC Error while trying to call CC Financial judgement API - Error type: SocketTimeoutException, Message: timeout"
  )
| filter host.name == "BILoss-processing-prod"
    or host.name == "BILoss-pre-processing-prod"
    or host.name == "BILoss-link-data-to-cc-prod"
    or contains(aws.log_group, "BILoss-", caseSensitive:false)
| filter matchesPhrase(content, "CC Error")
    or matchesPhrase(content, "Camunda Error")
    or matchesPhrase(content, "callCamundaProcess error")
    or matchesPhrase(content, "RuntimeException")
    or matchesPhrase(content, "failed to initialize clients")
    or matchesPhrase(content, "PSQLException")
    or matchesPhrase(content, "IllegalArgumentException")
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(matchesPhrase(content, "CC Error"), "CC Error"),
    if(matchesPhrase(content, "Camunda Error"), "Camunda Error"),
    if(matchesPhrase(content, "callCamundaProcess error"), "callCamundaProcess error"),
    if(matchesPhrase(content, "RuntimeException"), "RuntimeException"),
    if(matchesPhrase(content, "failed to initialize clients"), "failed to initialize clients"),
    if(matchesPhrase(content, "PSQLException"), "PSQLException"),
    if(matchesPhrase(content, "IllegalArgumentException"), "IllegalArgumentException")
  ))
| fields host.name, matched_keywords, content
```

**Pass:** `matched_keywords` = `["CC Error"]` (same as Splunk Statistics).

---

## Splunk → DQL cheat sheet

| Splunk | DQL |
|---|---|
| `host="BILoss-…"` | `host.name == "BILoss-…"` |
| `search ("CC Error" OR …)` | `matchesPhrase(content, "CC Error") or …` |
| `mvappend(if(match(_raw,"x"),"x",null()),…)` | `arrayRemoveNulls(array(if(matchesPhrase(content,"x"),"x"),…))` |
| `strftime(_time,"%Y-%m-%d %H:%M:%S.%Q")` | `formatTimestamp(..., format:"yyyy-MM-dd HH:mm:ss.SSS", timezone:"Asia/Tokyo")` |
| `table time host matched_keywords _raw` | `fields time, host.name, matched_keywords, content` |

## If live query returns 0

```
fetch logs, from:now()-7d
| filter contains(content, "CC Error")
| summarize n = count(), by:{ host.name, aws.log_group, log.source }
| sort n desc
```

Use the field values you see there if `host.name` is not exactly `BILoss-…`.

## Data flow map

```
AWS Lambda logEvents.message
  → "… CC Error while trying to call CC Financial judgement API …"
  → Dynatrace content
  → host / log group filter (BILoss-*)
  → phrase filter
  → matched_keywords tags
```

## Related files

| File | Role |
|---|---|
| `17-biloss-dql-filter-from-log-example.dql` | Live + dummy |
| `17.sh` | Mirror |

## Commands

See [17.sh](./17.sh).
