# ESBv4 Quote Timeout, SSL, AMP DQL

## Decision tree

```
Which SPL?
 #78 to #80 → subsearch: timeout error IDs → matching "Sending request" lines per channel
   → DQL lookup; one query per channel, or the combined count table
 #81 → SSL cert expiry from a Splunk lookup table
   → table uploaded to Grail? → load + filter
   → no table? → Synthetic HTTP monitor with certificate expiry check (recommended)
 #82 to #85 → portals-amp-backend JSON → unescape → parse → url / type / level filter
 0 rows? → check app names → still 0? → onboarding request
```

## Short takeaway

| SPL | What it finds |
|---|---|
| #78 | inswebauto quote requests that hit the pc quote timeout |
| #79 | inswebbike quote requests that hit the pc quote timeout |
| #80 | kakakucomauto quote requests that hit the pc quote timeout |
| #81 | ebroker SSL certificate expiring within 30 days |
| #82 | Error-level logs on save, ampupdateCoverages, quote, bind |
| #83 | payWithCreditCard_Adj with CAUGHT_EXCEPTION_ON_BACKEND, 1 day |
| #84 | payWithCreditCard_Adj with EXECUTION_COMPLETED, 1 day |
| #85 | payWithCreditCard_Adj with EXECUTION_COMPLETED, 1 hour |

## Summary

#78 to #80 answer "which sales channel's quote requests timed out at pc". The Splunk subsearch collects request IDs from timeout errors, then the outer search shows the request lines with those IDs. DQL uses `lookup`. #81 depends on a Splunk lookup table, so in Dynatrace it is better handled by a Synthetic monitor certificate check. #82 to #85 reuse the JSON pattern from answer 13.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| Subsearch | Splunk inner search that feeds IDs to the outer search. |
| `lookup` (DQL) | Joins rows from a second query by a shared field. |
| `makeresults` | Splunk command that makes one empty row to start from. |
| `sslcert_lookup` | A Splunk lookup table with certificate end dates. |
| `load` | DQL command that reads an uploaded lookup file from Grail. |
| Synthetic HTTP monitor | Dynatrace robot that calls a URL on a schedule. It can alert on certificate expiry. |
| Channel | The partner site sending the quote, such as inswebauto, inswebbike, kakakucomauto. |

### Mapping highlights

| Splunk piece | DQL piece |
|---|---|
| `[ search "...Timeout exceeded." \| rex ... \| fields query \| format ]` | `lookup [ ... ], sourceField:query, lookupField:query` |
| `AND "Sending request to /esb/ebroker/inswebbike/online/_quote"` | Outer `contains()` filter |
| `lookup sslcert_lookup dest OUTPUT ssl_end_time` | `load "/lookups/sslcert_lookup"` then filter `dest` |
| `ssl_end_time < relative_time(now(), "+30d")` | `ssl_end < now() + 30d` |
| `search (message.url="save" OR ...)` | `in(msg_url, array("save", ...))` |
| `spath level \| search level=error` | `lower(level) == "error"` |
| `earliest=-1h` | `from:now()-1h` |

### Things to verify

| Item | Why |
|---|---|
| #78 top lines | Cut off in the screenshot. Assumed the same pattern as #79. |
| ID parse pattern | Character-class `parse`. Test on one line. |
| #81 lookup path | `/lookups/sslcert_lookup` exists only if someone uploads it. |
| `ssl_end_time` format | Assumed Unix seconds. |

## Result

All queries are in `17-esbv4-quote-timeout-ssl-amp-dql.dql`. The chat reply has every query in full.

## Data flow map

```
#78–#80
  step 1: pc quote "Timeout exceeded" errors -> request IDs
  step 2: "Sending request to .../<channel>/online/_quote" -> ID in step 1 -> list or count per channel

#81
  Option A: Grail lookup file -> ebroker row -> end date < now + 30d
  Option B: Synthetic monitor -> certificate check -> problem when < 30 days

#82–#85
  portals-amp-backend logs -> unescape -> JSON -> url / type / level -> list
```

## Related files

| File | What it holds |
|---|---|
| `17-esbv4-quote-timeout-ssl-amp-dql.dql` | All queries |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Notes |
| `2-result.md` | Result summary |
| `3-glossary.md` | Glossary |
| `17.sh` | Git one-liners |

## Commands

See `17.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/17-esbv4-quote-timeout-ssl-amp-dql
git commit -m "ESBv4 quote timeout, SSL, AMP DQL"
git push
```
