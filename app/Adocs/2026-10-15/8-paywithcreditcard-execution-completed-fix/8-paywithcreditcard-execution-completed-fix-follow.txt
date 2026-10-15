# PayWithCreditCard Execution Completed Fix

## Decision tree

```
Splunk 68 events, Dynatrace 0 records
 Step 1: contains(content, "payWithCreditCard_Adj") over 1h
  0 rows → logs are not in Dynatrace (same finding as 2026-10-14 answers 21 and 25)
          → onboarding request is the fix, not the query
  rows → note the real pod, container and log.source names
        → Step 2 fixed query
         rows → done
         0 rows → check type value and url field in one raw line
```

## Short takeaway

| Question | Answer |
|---|---|
| Why 0 records? | Three reasons. The query looks for a different type, uses exact match on a full URL, and the logs are probably not in Dynatrace. |
| Wrong type | Splunk looks for `EXECUTION_COMPLETED`. The notebook looks for `CAUGHT_EXCEPTION_ON_BACKEND`. |
| Wrong URL match | `msg_url == "payWithCreditCard_Adj"` never matches, because url holds the full `https://...` address. |
| Missing logs | portals-amp logs go to S3 and Splunk only. Earlier checks found 0 records. |

## Summary

The notebook query is not the same search as Splunk. It filters for an exception type instead of `EXECUTION_COMPLETED`, and it compares the full URL with `==`. Fix both, but first run Step 1. If Step 1 also returns 0, the logs are simply not in Dynatrace and no query change will help.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| `spath` | Splunk command that reads JSON fields, such as `message.url`. |
| `parse raw, "JSON:j"` | DQL version of `spath`. It puts the JSON into a record called `j`. |
| `message.type` | The event type inside the JSON, for example `EXECUTION_COMPLETED`. |
| `==` | Exact match. The whole value must be equal. |
| `contains` | Substring match. Part of the value is enough. |

### Splunk compared with the notebook

| Part | Splunk | Notebook DQL | Problem |
|---|---|---|---|
| Source | `sourcetype="portals-amp-backend"` | container, pod or log.source contains portals-amp-backend | Probably not in Dynatrace |
| Time | `earliest=-1h` | `from:now()-1h` | Same |
| Unescape | `replace(_raw, "\\\"", "\"")` | `replaceString` twice | Second replace removes every backslash, which is not in Splunk |
| URL | `message.url="*payWithCreditCard_Adj*"` (wildcards) | `msg_url == "payWithCreditCard_Adj"` | Exact match never hits a full URL |
| Type | `EXECUTION_COMPLETED` | `CAUGHT_EXCEPTION_ON_BACKEND` | Different search |

### Evidence from the screenshots

| Item | Value |
|---|---|
| Splunk result | 68 events between 10:37 and 11:37 on 10/15/26 |
| Example url | `https://portals-api-gateway-inssuite-prod.../pc/rest/renewal/renewal/v1/payWithCreditCard_Adj` |
| Example type | `EXECUTION_COMPLETED` |
| Example target_system | `PC_CUSTOMER` |
| Dynatrace result | 0 records, 8.89 GiB scanned |

## Result

Queries are in `8-paywithcreditcard-execution-completed-fix.dql`.

| Step | What it does |
|---|---|
| Step 1 | Searches all logs for `payWithCreditCard_Adj` and shows where they come from. |
| Step 2 | Fixed query: `contains` on url and `EXECUTION_COMPLETED` type. |
| Step 3 | Same as Step 2 but for `CAUGHT_EXCEPTION_ON_BACKEND`, if you want exceptions instead. |

## Data flow map

```
portals-amp-backend pods
 → stdout JSON logs
 → log forwarder → S3 (axa-gi-jp-logforwarders-prod) → Splunk   (68 events found)
 → Dynatrace Grail?   (not onboarded, 0 records)
```

## Related files

| File | Purpose |
|---|---|
| `8-paywithcreditcard-execution-completed-fix.dql` | Step 1, Step 2 and Step 3 queries |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Splunk compared with the notebook |
| `2-result.md` | What to do next |
| `3-glossary.md` | Terms |
| `8.sh` | Git one-liners (not run) |

## Commands

See `8.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/8-paywithcreditcard-execution-completed-fix
git commit -m "paywithcreditcard execution completed fix"
git push
```
