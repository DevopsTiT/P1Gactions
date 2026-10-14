# CC ESBv4 Ebroker Silent Apps DQL

## Decision tree

```
Which SPL?
 #66, #68, #70, #71, #73, #75 → app prefix + phrase
 #69, #74 → phrase with "*" wildcard → split into parts
 #67 → parse log level from line start → keep ERROR → group by time
 #72 → Splunk subsearch → DQL lookup on request ID
 #76 → last log time per app → silent > 1 hour
 0 rows? → check app names (answer 14 check query) → still 0? → onboarding request
```

## Short takeaway

| SPL | What it finds |
|---|---|
| #66 | cc apps with `NoUpdatePaymentError` |
| #67 | ERROR lines from sonpov and temp-receipt-accounting, grouped by time |
| #68 | cc-ui `removeDocument called for document with DocUID` |
| #69 | esbv4 call to ebroker failed with 503 |
| #70 | ebroker address conversion failures |
| #71 | ebroker startup lines (restarts) |
| #72 | esbv4 ebroker requests that later hit an Interceptor exception |
| #73 | ebroker `POST /request/ottif` started |
| #74 | esbv4 call to pc quote endpoint failed |
| #75 | esbv4 cannot reach `localhost:8082` |
| #76 | Apps that stopped logging more than 1 hour ago |

## Summary

Most are app-plus-phrase searches. #72 is the interesting one: Splunk uses a subsearch to collect request IDs, then finds exception lines with those IDs. DQL does the same with `lookup`. #76 is the sourcetype version of #18 (silent hosts).

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| Subsearch `[ ... ]` | Splunk runs the inner search first and feeds its results to the outer search. |
| `lookup` | DQL command that joins a second query's results onto each row. |
| `collectDistinct()` | DQL version of Splunk `values()`: unique values as a list. |
| UUID | A 36-character ID like `1a2b3c4d-....`. Used here as the request ID. |
| `matchesValue()` | Wildcard match against a list of patterns. |

### Mapping highlights

| Splunk piece | DQL piece |
|---|---|
| `"*NoUpdatePaymentError*"` | `contains(content, "NoUpdatePaymentError")` |
| `rex "...(?<loglevel>[A-Z]+)"` | `parse content, "INT '-' INT '-' INT SPACE INT ':' INT ':' INT SPACE ALPHA:loglevel_parsed"` |
| `stats values(x) by _time` | `summarize collectDistinct(x), by:{ timestamp }` |
| `'.../*' failed: service unavailable (503).` | Two `contains()`: before and after the `*` |
| `[ search ... \| rex ... \| fields query \| format ]` | `lookup [ ... ], sourceField:query, lookupField:query` |
| `"Interceptor for*has thrown exception"` | `contains("Interceptor for") and contains("has thrown exception")` |
| `metadata type=sourcetypes` | `summarize max(timestamp) by app` |
| `like(sourcetype, "agrex%")` | `matchesValue(app, "agrex*")` |
| `NOT like(sourcetype, "ebroker_batch")` | `not in(app, array("ebroker_batch", ...))` |

### Things to verify

| Item | Why |
|---|---|
| Screenshot readability | Some text was blurry: `NoUpdatePaymentError`, `localhost:8082`, `ottif`. Check them against the source. |
| #67 line format | Assumes the line starts with the date and time. |
| #72 parse pattern | Character-class parse. Test it on one line first. |
| #76 app field | Sourcetype has no Dynatrace equal. Pick workload, container, or host. |
| #76 bottom lines | The SPL is cut off after `sort "Minutes Behind" desc`. |

## Result

All queries are in `16-cc-esbv4-ebroker-silent-dql.dql`. The chat reply has every query in full.

## Data flow map

```
Phrase SPLs  logs -> app prefix -> phrase parts -> newest first
#67          logs -> sonpov / temp-receipt -> parse level -> ERROR -> group by time
#72          step 1: "Sending request to /esb/ebroker" -> request IDs
             step 2: Interceptor exception lines -> ID in step 1 list -> list
#76          logs (7d) -> app list minus exclusions -> last log per app -> > 1 hour
```

## Related files

| File | What it holds |
|---|---|
| `16-cc-esbv4-ebroker-silent-dql.dql` | All queries |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Notes |
| `2-result.md` | Result summary |
| `3-glossary.md` | Glossary |
| `16.sh` | Git one-liners |

## Commands

See `16.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/16-cc-esbv4-ebroker-silent-dql
git commit -m "CC, esbv4, ebroker, silent apps DQL"
git push
```
