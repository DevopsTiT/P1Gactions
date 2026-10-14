# Splunk PayWithCreditCard Query Explained

## Decision tree

```
sourcetype="portals-amp-backend" earliest=-1h
 → step 1: pick the logs (which app, which time)
| eval _raw=replace(_raw,"\\\\\"","\"")
 → step 2: turn \" into "          (unescape quotes)
| eval _raw=replace(_raw,"\\\\","")
 → step 3: delete leftover \        (clean backslashes)
| spath
 → step 4: read the JSON into fields (level, message.url, message.type, ...)
| search message.url=*payWithCreditCard_Adj* message.type="EXECUTION_COMPLETED"
 → step 5: keep only completed credit-card payment calls

0 events? → step 4 failed (JSON not parsed) or wrong time range
too slow? → add raw words to step 1 so Splunk reads fewer events
```

## Short takeaway

| Question | Answer |
|---|---|
| What does the query answer? | How many credit-card payment calls finished in the last hour, and their details. |
| Why the two `replace` steps? | The JSON in the log has escaped quotes. Splunk cannot read it until they are cleaned. |
| What does `spath` do? | Turns the JSON text into fields like `message.url`. |
| Why `*` around payWithCreditCard_Adj? | `url` holds the full URL. The stars mean "contains". |
| Result in the screenshot | 75 events, all `level: info`, from 2 pods. |

## Summary

The query has five steps: choose the logs, clean the escaped JSON twice, parse the JSON into fields, then filter on two of those fields. The cleaning steps exist only because the log line arrives with backslash-escaped quotes, which `spath` cannot parse.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| `sourcetype` | Splunk label for this kind of log. Here, the AMP backend app. |
| `earliest=-1h` | Start the time range 1 hour ago. |
| `_raw` | The full original log line. |
| `eval` | Create or change a field. |
| `replace(field, regex, new)` | Find text that matches a regex and swap it. |
| Escaped quote `\"` | A quote written with a backslash so it can sit inside another string. |
| `spath` | Splunk command that reads JSON and makes fields from it. |
| `search` (after a pipe) | Filter the results so far. |

### Step 1: choose the logs

```
sourcetype="portals-amp-backend" earliest=-1h
```

| Part | What it does |
|---|---|
| `sourcetype="portals-amp-backend"` | Only logs from the AMP backend pods. |
| `earliest=-1h` | Only the last hour. No `latest`, so it runs up to now. |

### Step 2: unescape the quotes

```
| eval _raw=replace(_raw,"\\\\\"","\"")
```

The pattern looks scary because it is escaped twice: once for the Splunk string, once for the regex.

| Layer | What `"\\\\\""` becomes | Why |
|---|---|---|
| As typed in SPL | `\\\\\"` | Five characters of backslashes and a quote inside the string. |
| After Splunk reads the string | `\\"` | Each `\\` becomes `\`, and `\"` becomes `"`. |
| As a regex | backslash then quote | In regex, `\\` means one real backslash. |
| Replacement `"\""` | `"` | Just a plain quote. |

Before and after:

| Before | After |
|---|---|
| `{\"level\":\"info\",\"message\":{\"type\":\"EXECUTION_COMPLETED\"}}` | `{"level":"info","message":{"type":"EXECUTION_COMPLETED"}}` |

### Step 3: delete leftover backslashes

```
| eval _raw=replace(_raw,"\\\\","")
```

| Layer | What `"\\\\"` becomes |
|---|---|
| As typed | `\\\\` |
| After Splunk reads the string | `\\` |
| As a regex | one real backslash |
| Replacement `""` | nothing, so the backslash is deleted |

This catches backslashes that were not in front of a quote, for example in `\/` or doubled escapes.

### Step 4: parse the JSON

```
| spath
```

With no arguments, `spath` reads the whole `_raw` as JSON and creates a field for every key. Nested keys get dotted names.

| JSON key | Field name after spath | Example value from the screenshot |
|---|---|---|
| `level` | `level` | `info` |
| `message.method` | `message.method` | `post` |
| `message.request_id` | `message.request_id` | a UUID |
| `message.target_system` | `message.target_system` | `PC_CUSTOMER` |
| `message.type` | `message.type` | `EXECUTION_COMPLETED` |
| `message.url` | `message.url` | `https://portals-api-gateway-inssuite-prod.../payWithCreditCard_Adj` |
| `timestamp` | `timestamp` | `2026-10-14T06:57:03.016Z` |

### Step 5: filter on the fields

```
| search message.url=*payWithCreditCard_Adj* message.type="EXECUTION_COMPLETED"
```

| Part | What it does |
|---|---|
| `message.url=*payWithCreditCard_Adj*` | URL contains `payWithCreditCard_Adj` anywhere. The stars are wildcards. |
| (space between the two) | Means AND. Both must be true. |
| `message.type="EXECUTION_COMPLETED"` | The call finished. Splunk ignores case here. |

### Why filter after spath and not at the start?

| Reason | Detail |
|---|---|
| Fields do not exist yet at step 1 | `message.url` is created by `spath` in step 4. |
| Cost | Splunk reads every AMP backend event in the hour, cleans it, and parses it before filtering. |

### Faster version (same result)

Add the two words to step 1 as plain text. Splunk then only reads events that contain them.

```
sourcetype="portals-amp-backend" earliest=-1h "payWithCreditCard_Adj" "EXECUTION_COMPLETED"
| eval _raw=replace(_raw,"\\\\\"","\"")
| eval _raw=replace(_raw,"\\\\","")
| spath
| search message.url=*payWithCreditCard_Adj* message.type="EXECUTION_COMPLETED"
```

### Common mistakes

| Mistake | What happens |
|---|---|
| Removing the replace steps | `spath` cannot parse. Fields are empty. 0 results. |
| `message.url="payWithCreditCard_Adj"` without stars | 0 results, because the value is a full URL. |
| Swapping the order of the two replaces | Step 3 deletes the backslashes first, which also works here, but it can break strings that really contain `\"`. Keep the order. |
| Forgetting `earliest` | Uses the time picker range, which may be much larger. |

## Result

| Step | Command | Output |
|---|---|---|
| 1 | `sourcetype=... earliest=-1h` | All AMP backend events in the hour |
| 2 | `replace \" → "` | Quotes unescaped |
| 3 | `replace \ → nothing` | Backslashes removed |
| 4 | `spath` | JSON fields created |
| 5 | `search url and type` | 75 completed credit-card payment calls |

DQL version of the same logic is in answer 19 (`contains(msg_url, "payWithCreditCard_Adj") and msg_type == "EXECUTION_COMPLETED"`).

## Data flow map

```
AMP backend pods -> S3 -> Splunk index
  -> step 1 pick sourcetype + last hour
  -> step 2 \" becomes "
  -> step 3 stray \ removed
  -> step 4 spath: level, message.url, message.type, ...
  -> step 5 url contains payWithCreditCard_Adj AND type EXECUTION_COMPLETED
  -> 75 events
```

## Related files

| File | What it holds |
|---|---|
| `0-pic.md` | Step tree and data flow |
| `1-investigation.md` | Step-by-step notes |
| `2-result.md` | Result table |
| `3-glossary.md` | Glossary |
| `20-splunk-paywithcreditcard-query-explained-faster.spl.txt` | Faster version of the SPL |
| `20.sh` | Git one-liners |

## Commands

See `20.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/20-splunk-paywithcreditcard-query-explained
git commit -m "Splunk payWithCreditCard query explained"
git push
```
