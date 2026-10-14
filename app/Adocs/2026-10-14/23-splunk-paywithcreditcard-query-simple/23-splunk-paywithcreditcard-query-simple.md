# Splunk PayWithCreditCard Query Simple

## Decision tree

```
The query in one sentence:
"In the last hour, from the AMP backend app, show me every credit-card payment call that finished."

sourcetype="portals-amp-backend" earliest=-1h   → WHICH app, WHEN
| eval _raw=replace(...)  (twice)               → CLEAN the text so it is real JSON
| spath                                         → READ the JSON into named boxes (fields)
| search message.url=*payWithCreditCard_Adj*    → KEEP only credit-card payment calls
         message.type="EXECUTION_COMPLETED"     → KEEP only the ones that finished
→ 75 events on screen
```

## Short takeaway

| Part of the query | Plain English | Where you see it on screen |
|---|---|---|
| `sourcetype="portals-amp-backend"` | Only the AMP backend app. | `sourcetype = portals-amp-backend` under each event |
| `earliest=-1h` | Only the last hour. | `2:58:28 PM to 3:58:27 PM` |
| `eval _raw=replace(...)` twice | Remove the backslashes that break the JSON. | Not visible. It happens before display. |
| `spath` | Turn JSON into fields. | The tidy `level:`, `message:`, `url:` tree |
| `message.url=*payWithCreditCard_Adj*` | URL contains this API name. | `url: https://.../payWithCreditCard_Adj` |
| `message.type="EXECUTION_COMPLETED"` | The call finished. | `type: EXECUTION_COMPLETED` |
| Result | 75 matching calls. | `75 events` at the top |

## Summary

Think of it like sorting mail. First you pick one mailbox (the app) and one hour. Then you open the envelopes (clean the text). Then you read the letters into labelled sections (spath). Finally you keep only letters about credit-card payments that were completed. The pile you end up with has 75 letters.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| Event | One log line. Splunk found 75. |
| `sourcetype` | Splunk's name for one kind of log. Here, one app. |
| `_raw` | The original log text. |
| JSON | Text in `{"key":"value"}` form that programs use to store data. |
| Field | A named value, like `level = info`. |
| `*` | Wildcard. Means "anything can be here". |

### Step 1: pick the app and time

```
sourcetype="portals-amp-backend" earliest=-1h
```

Like saying "open the AMP backend mailbox, only letters from the last hour".

### Step 2: clean the text (the two replace lines)

```
| eval _raw=replace(_raw,"\\\\\"","\"")
| eval _raw=replace(_raw,"\\\\","")
```

The app's log text arrives looking like this:

```
{\"level\":\"info\",\"message\":{\"type\":\"EXECUTION_COMPLETED\"}}
```

The backslashes `\` stop Splunk from seeing it as JSON.

| Line | Plain English | Result |
|---|---|---|
| First replace | Change every `\"` into `"`. | `{"level":"info", ...}` |
| Second replace | Delete any `\` that is left. | Clean JSON |

Why so many backslashes in the query? A backslash is a special character in Splunk text and in patterns, so to mean "one real backslash" you have to type several. You do not need to change them. Copy them as they are.

### Step 3: read the JSON

```
| spath
```

Splunk reads the clean JSON and creates fields. This is the tidy tree you see on screen.

| Field | Value on screen | Meaning |
|---|---|---|
| `level` | `info` | Normal message, not an error. |
| `message.method` | `post` | The portal sent data. |
| `message.target_system` | `PC_CUSTOMER` | The call went to PolicyCenter. |
| `message.type` | `EXECUTION_COMPLETED` | The call finished. |
| `message.url` | `https://portals-api-gateway-.../payWithCreditCard_Adj` | The credit-card payment API. |
| `timestamp` | `2026-10-14T06:57:03.016Z` | App time in UTC. 06:57 UTC is 15:57 JST. |

### Step 4: keep only what you want

```
| search message.url=*payWithCreditCard_Adj* message.type="EXECUTION_COMPLETED"
```

| Condition | Plain English |
|---|---|
| `message.url=*payWithCreditCard_Adj*` | The URL has "payWithCreditCard_Adj" somewhere in it. |
| (space) | AND. Both must be true. |
| `message.type="EXECUTION_COMPLETED"` | The call completed. |

### What the rest of the screen means

| Screen part | Meaning |
|---|---|
| Green bars on the timeline | Calls per time slot. Spread evenly, so steady traffic. |
| `host = portals-amp-backend-5f57cbc7-...` | The pod that handled the call. |
| Left panel `host 2` | Two pods share the work. |
| `source = s3://axa-gi-jp-logforwarders-prod/...` | Splunk read the log from S3. |
| Left panel `source 75` | Each event came from its own S3 file. |

### If you want to see failures instead

Change the last line to:

```
| search message.url=*payWithCreditCard_Adj* message.type="CAUGHT_EXCEPTION_ON_BACKEND"
```

That is SPL #83.

## Result

The query shows 75 successful credit-card payment calls in the last hour from 2 AMP backend pods. Nothing on this screen points to a problem.

In Dynatrace, these logs are not available yet (answer 21). The DQL version is ready in answer 19 for when they are onboarded.

## Data flow map

```
Customer pays by card
  -> portals-api-gateway -> portals-amp-backend pod -> PolicyCenter
  -> app writes JSON log (with backslashes)
  -> S3 -> Splunk
  -> query: pick app + hour -> clean -> spath -> keep card payments that finished
  -> 75 events
```

## Related files

| File | What it holds |
|---|---|
| `0-pic.md` | Step tree and data flow |
| `1-investigation.md` | Step notes |
| `2-result.md` | Result |
| `3-glossary.md` | Glossary |
| `23.sh` | Git one-liners |
| Answer 20 | Detailed version (how the backslash escaping works layer by layer) |

## Commands

See `23.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/23-splunk-paywithcreditcard-query-simple
git commit -m "Splunk payWithCreditCard query simple"
git push
```
