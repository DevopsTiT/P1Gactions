# BILoss From Splunk Example

```
Splunk shows CC Error on biloss-link-data-to-cc-prod?
 → Use lowercase biloss-* hosts (not BILoss-*)
 → Also match /aws/lambda/biloss-… (CloudWatch Lambda)
 → if() without bare null — use if(cond, "text") then coalesce or arrayRemoveNulls
 → Dummy: paste the real CC Error message → expect matched_keywords = CC Error
```

| Key point | Detail |
|---|---|
| Example host | `biloss-link-data-to-cc-prod` |
| Example hit | `CC Error while trying to call CC financial judgement API` |
| Log shape | AWS Lambda JSON → `message` holds the Java line |
| Splunk `null()` | In DQL: omit else, or `else: null` — never `, null` |

## Summary

Your Splunk search tags BILoss Lambda lines with one of seven phrases. The DQL below follows that example: same hosts (lowercase), same phrases, and a dummy row built from the CC Error line you already have in Splunk.

## Splunk → DQL mapping (from your screen)

| Splunk | DQL |
|---|---|
| `host="biloss-…"` / index | `host.name` **or** `aws.log_group` / `log.source` containing `/aws/lambda/biloss-` |
| `match(_raw, "CC Error")` | `matchesPhrase(content, "CC Error")` or `contains(content, "CC Error")` |
| nested `if(..., null())` first match | `coalesce(if(...), if(...), …)` |
| `mvappend`-style many tags | `arrayRemoveNulls(array(if(...), …))` (richer than Splunk nested if) |
| `strftime(_time, …)` | `formatTimestamp(timestamp, …, timezone:"Asia/Tokyo")` |
| `table time host _raw matched_keywords` | `fields time, host.name, matched_keywords, content` |

### Keyword strings (match Splunk)

| # | Phrase |
|---|---|
| 1 | `CC Error` |
| 2 | `Camunda Error` |
| 3 | `callCamundaProcess error` |
| 4 | `RuntimeException` |
| 5 | `Failed to initialize client` |
| 6 | `PSQLException` |
| 7 | `IllegalArgumentException` |

Note: use **client** (singular), like Splunk — not `clients`.

---

## A) Main DQL — all matching keywords (recommended)

Closest to “tag every phrase that appears” (handy on-call).

```
fetch logs, from:now()-24h
| filter in(host.name, array(
      "biloss-processing-prod",
      "biloss-pre-processing-prod",
      "biloss-link-data-to-cc-prod"
    ))
    or contains(aws.log_group, "/aws/lambda/biloss-", caseSensitive:false)
    or contains(log.source, "/aws/lambda/biloss-", caseSensitive:false)
    or contains(content, "/aws/lambda/biloss-", caseSensitive:false)
| filter matchesPhrase(content, "CC Error")
    or matchesPhrase(content, "Camunda Error")
    or matchesPhrase(content, "callCamundaProcess error")
    or matchesPhrase(content, "RuntimeException")
    or matchesPhrase(content, "Failed to initialize client")
    or matchesPhrase(content, "PSQLException")
    or matchesPhrase(content, "IllegalArgumentException")
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(matchesPhrase(content, "CC Error"), "CC Error"),
    if(matchesPhrase(content, "Camunda Error"), "Camunda Error"),
    if(matchesPhrase(content, "callCamundaProcess error"), "callCamundaProcess error"),
    if(matchesPhrase(content, "RuntimeException"), "RuntimeException"),
    if(matchesPhrase(content, "Failed to initialize client"), "Failed to initialize client"),
    if(matchesPhrase(content, "PSQLException"), "PSQLException"),
    if(matchesPhrase(content, "IllegalArgumentException"), "IllegalArgumentException")
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, matched_keywords, content
```

---

## B) Splunk-like — first keyword only (`coalesce`)

Matches nested `if(match(...), …, null())` (one tag per row).

```
fetch logs, from:now()-24h
| filter in(host.name, array(
      "biloss-processing-prod",
      "biloss-pre-processing-prod",
      "biloss-link-data-to-cc-prod"
    ))
    or contains(aws.log_group, "/aws/lambda/biloss-", caseSensitive:false)
    or contains(log.source, "/aws/lambda/biloss-", caseSensitive:false)
| filter matchesPhrase(content, "CC Error")
    or matchesPhrase(content, "Camunda Error")
    or matchesPhrase(content, "callCamundaProcess error")
    or matchesPhrase(content, "RuntimeException")
    or matchesPhrase(content, "Failed to initialize client")
    or matchesPhrase(content, "PSQLException")
    or matchesPhrase(content, "IllegalArgumentException")
| fieldsAdd matched_keywords = coalesce(
    if(matchesPhrase(content, "CC Error"), "CC Error"),
    if(matchesPhrase(content, "Camunda Error"), "Camunda Error"),
    if(matchesPhrase(content, "callCamundaProcess error"), "callCamundaProcess error"),
    if(matchesPhrase(content, "RuntimeException"), "RuntimeException"),
    if(matchesPhrase(content, "Failed to initialize client"), "Failed to initialize client"),
    if(matchesPhrase(content, "PSQLException"), "PSQLException"),
    if(matchesPhrase(content, "IllegalArgumentException"), "IllegalArgumentException")
  )
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| sort timestamp desc
| fields time, host.name, matched_keywords, content
```

---

## C) Dummy verify — your Splunk CC Error example

```
data record(
    timestamp: toTimestamp("2024-10-28T15:00:00+09:00"),
    host.name: "biloss-link-data-to-cc-prod",
    aws.log_group: "/aws/lambda/biloss-link-data-to-cc-prod",
    content: "[MAIN] ERROR jp.co.axa.api.ClaimCenterClient - CC Error while trying to call CC financial judgement API - Error type: SocketTimeoutException, Message: timeout"
  )
| filter in(host.name, array(
      "biloss-processing-prod",
      "biloss-pre-processing-prod",
      "biloss-link-data-to-cc-prod"
    ))
    or contains(aws.log_group, "/aws/lambda/biloss-", caseSensitive:false)
| filter matchesPhrase(content, "CC Error")
    or matchesPhrase(content, "Camunda Error")
    or matchesPhrase(content, "callCamundaProcess error")
    or matchesPhrase(content, "RuntimeException")
    or matchesPhrase(content, "Failed to initialize client")
    or matchesPhrase(content, "PSQLException")
    or matchesPhrase(content, "IllegalArgumentException")
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(matchesPhrase(content, "CC Error"), "CC Error"),
    if(matchesPhrase(content, "Camunda Error"), "Camunda Error"),
    if(matchesPhrase(content, "callCamundaProcess error"), "callCamundaProcess error"),
    if(matchesPhrase(content, "RuntimeException"), "RuntimeException"),
    if(matchesPhrase(content, "Failed to initialize client"), "Failed to initialize client"),
    if(matchesPhrase(content, "PSQLException"), "PSQLException"),
    if(matchesPhrase(content, "IllegalArgumentException"), "IllegalArgumentException")
  ))
| fields host.name, matched_keywords, content
```

**Pass:** one row, `matched_keywords` = `["CC Error"]` (same tag as Splunk).

---

## Common mistakes (from your earlier DQL)

| Mistake | Why Splunk worked / DQL failed |
|---|---|
| `host.name == "BILoss-…"` | Splunk host is lowercase `biloss-…` |
| `Failed to initialize clients` | Splunk uses **client** |
| `if(..., "x", null)` | DQL needs `if(..., "x")` or `else: null` |
| Only `host.name` | Lambda may land under `aws.log_group` / `log.source` |

## Check: where are biloss Lambda logs?

```
fetch logs, from:now()-7d
| filter contains(host.name, "biloss", caseSensitive:false)
    or contains(aws.log_group, "biloss", caseSensitive:false)
    or contains(log.source, "biloss", caseSensitive:false)
| summarize lines = count(), by:{ host.name, aws.log_group, log.source }
| sort lines desc
```

## Data flow map

```
AWS Lambda biloss-link-data-to-cc-prod
  → CloudWatch log group /aws/lambda/biloss-…
  → Dynatrace content (Java line inside)
  → filter hosts / log group
  → match phrases (CC Error, …)
  → matched_keywords (coalesce = 1 tag like Splunk; array = all tags)
  → table time, host, keywords, content
```

## Related files

| File | Role |
|---|---|
| `16-biloss-from-splunk-example.dql` | Main + coalesce + dummy |
| `../15-fix-dql-if-else-named/` | Why `, null` broke |
| `16.sh` | Mirror |

## Commands

See [16.sh](./16.sh).
