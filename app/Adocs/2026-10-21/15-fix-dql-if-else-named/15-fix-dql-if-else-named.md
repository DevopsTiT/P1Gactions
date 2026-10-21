# Fix DQL If Else Named

```
Error: Too many positional parameters… Potential parameters are: else
 → You wrote if(cond, "text", null)
 → DQL wants if(cond, "text")  OR  if(cond, "text", else: null)
 → Remove the bare , null  → rerun
```

| Key point | Detail |
|---|---|
| Broken part | `if(matchesPhrase(...), "CC Error", null)` |
| Why it fails | Third argument of `if` must be named `else:` |
| Fix | Drop `, null` (false → null automatically) |

## Summary

Your BILoss keyword query was fine except every `if(..., null)`. DQL does not allow a third positional value; use two args only, or `else: null`.

## Correct query

```
fetch logs, from:now()-24h
| filter host.name == "BILoss-processing-prod"
    or host.name == "BILoss-pre-processing-prod"
    or host.name == "BILoss-link-data-to-cc-prod"
| filter matchesPhrase(content, "CC Error")
    or matchesPhrase(content, "Camunda Error")
    or matchesPhrase(content, "callCamundaProcess error")
    or matchesPhrase(content, "RuntimeException")
    or matchesPhrase(content, "Failed to initialize clients")
    or matchesPhrase(content, "PSQLException")
    or matchesPhrase(content, "IllegalArgumentException")
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(matchesPhrase(content, "CC Error"), "CC Error"),
    if(matchesPhrase(content, "Camunda Error"), "Camunda Error"),
    if(matchesPhrase(content, "callCamundaProcess error"), "callCamundaProcess error"),
    if(matchesPhrase(content, "RuntimeException"), "RuntimeException"),
    if(matchesPhrase(content, "Failed to initialize clients"), "Failed to initialize clients"),
    if(matchesPhrase(content, "PSQLException"), "PSQLException"),
    if(matchesPhrase(content, "IllegalArgumentException"), "IllegalArgumentException")
  ))
| fieldsAdd time = formatTimestamp(timestamp, format:"yyyy-MM-dd HH:mm:ss z", timezone:"Asia/Tokyo")
| fields time, host.name, matched_keywords, content
```

## What changed

| Before (wrong) | After (correct) |
|---|---|
| `if(matchesPhrase(content, "CC Error"), "CC Error", null)` | `if(matchesPhrase(content, "CC Error"), "CC Error")` |
| Same pattern on all 7 `if` lines | Same — no bare `null` |

Optional other form (same meaning):

```
if(matchesPhrase(content, "CC Error"), "CC Error", else: null)
```

## Dummy verify (no live logs)

```
data record(
    host.name: "BILoss-processing-prod",
    content: "2026-10-21 ERROR callCamundaProcess error RuntimeException in worker"
  )
| filter host.name == "BILoss-processing-prod"
    or host.name == "BILoss-pre-processing-prod"
    or host.name == "BILoss-link-data-to-cc-prod"
| filter matchesPhrase(content, "CC Error")
    or matchesPhrase(content, "Camunda Error")
    or matchesPhrase(content, "callCamundaProcess error")
    or matchesPhrase(content, "RuntimeException")
    or matchesPhrase(content, "Failed to initialize clients")
    or matchesPhrase(content, "PSQLException")
    or matchesPhrase(content, "IllegalArgumentException")
| fieldsAdd matched_keywords = arrayRemoveNulls(array(
    if(matchesPhrase(content, "CC Error"), "CC Error"),
    if(matchesPhrase(content, "Camunda Error"), "Camunda Error"),
    if(matchesPhrase(content, "callCamundaProcess error"), "callCamundaProcess error"),
    if(matchesPhrase(content, "RuntimeException"), "RuntimeException"),
    if(matchesPhrase(content, "Failed to initialize clients"), "Failed to initialize clients"),
    if(matchesPhrase(content, "PSQLException"), "PSQLException"),
    if(matchesPhrase(content, "IllegalArgumentException"), "IllegalArgumentException")
  ))
| fields host.name, matched_keywords, content
```

Pass when `matched_keywords` includes `callCamundaProcess error` and `RuntimeException`.

## Data flow map

```
if(cond, then, null)     → ERROR (positional else not allowed)
if(cond, then)           → OK (else is null by default)
if(cond, then, else: x)  → OK (named else)
  → arrayRemoveNulls keeps only matched keyword strings
```

## Related files

| File | Role |
|---|---|
| `15-biloss-keywords-fixed.dql` | Copy-paste fixed query |
| `15.sh` | Mirror commands |

## Commands

See [15.sh](./15.sh).
