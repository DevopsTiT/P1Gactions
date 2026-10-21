# BILoss Verify Dummy FieldsAdd

```
Want dummy verify like afterBind?
 → fetch logs
 → fieldsAdd dummy = "<piece of real log>"
 → fields dummy
 → filter contains(dummy, …)  (same phrases as live query)
 → Do NOT use data record
```

| Key point | Detail |
|---|---|
| Style | Same as your afterBind `Verify:` block |
| Dummy text | Piece of Splunk `logEvents.message` with `CC Error` |
| Pass | One row with that dummy string still present after filters |

## Summary

Verify BILoss keyword filters the same way as `#2 afterBind`: invent one string in `dummy`, then run `contains` / `matchesPhrase` on `dummy` instead of `content`.

## Verify (like your afterBind example)

```
// Verify: BILoss keywords (same style as afterBind_Adj)
fetch logs
| fieldsAdd dummy = "[main] ERROR jp.co.axa.api.ClaimCenterClient - CC Error while trying to call CC Financial judgement API - Error type: SocketTimeoutException, Message: timeout"
| fields dummy
| filter matchesPhrase(dummy, "CC Error")
    or matchesPhrase(dummy, "Camunda Error")
    or matchesPhrase(dummy, "callCamundaProcess error")
    or matchesPhrase(dummy, "RuntimeException")
    or matchesPhrase(dummy, "failed to initialize clients")
    or matchesPhrase(dummy, "PSQLException")
    or matchesPhrase(dummy, "IllegalArgumentException")
```

**Pass:** you still see the dummy line (it matched `CC Error`).

### Optional — also build matched_keywords on dummy

```
fetch logs
| fieldsAdd dummy = "[main] ERROR jp.co.axa.api.ClaimCenterClient - CC Error while trying to call CC Financial judgement API - Error type: SocketTimeoutException, Message: timeout"
| fields dummy
| filter matchesPhrase(dummy, "CC Error")
    or matchesPhrase(dummy, "Camunda Error")
    or matchesPhrase(dummy, "callCamundaProcess error")
    or matchesPhrase(dummy, "RuntimeException")
    or matchesPhrase(dummy, "failed to initialize clients")
    or matchesPhrase(dummy, "PSQLException")
    or matchesPhrase(dummy, "IllegalArgumentException")
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(matchesPhrase(dummy, "CC Error"), "CC Error"),
    if(matchesPhrase(dummy, "Camunda Error"), "Camunda Error"),
    if(matchesPhrase(dummy, "callCamundaProcess error"), "callCamundaProcess error"),
    if(matchesPhrase(dummy, "RuntimeException"), "RuntimeException"),
    if(matchesPhrase(dummy, "failed to initialize clients"), "failed to initialize clients"),
    if(matchesPhrase(dummy, "PSQLException"), "PSQLException"),
    if(matchesPhrase(dummy, "IllegalArgumentException"), "IllegalArgumentException")
  ))
| fields dummy, matched_keywords
```

**Pass:** `matched_keywords` = `["CC Error"]`.

## Side by side with your afterBind verify

| afterBind | BILoss |
|---|---|
| `fieldsAdd dummy = "Exception occured for job … during afterBind_Adj process"` | `fieldsAdd dummy = "[main] ERROR … CC Error …"` |
| `contains(dummy, "Exception occured for job")` | `matchesPhrase(dummy, "CC Error")` (or `contains`) |
| `and contains(dummy, "during afterBind_Adj process")` | `or` other phrases |

## Live filter (unchanged — uses content)

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

## Data flow map

```
fetch logs
  → fieldsAdd dummy = "<log piece>"
  → fields dummy
  → filter phrases on dummy
  → (optional) matched_keywords from dummy
```

## Related files

| File | Role |
|---|---|
| `18-biloss-verify-dummy-fieldsadd.dql` | Verify + live |
| `../17-biloss-dql-filter-from-log-example/` | Earlier version (had data record) |
| `18.sh` | Mirror |

## Commands

See [18.sh](./18.sh).
