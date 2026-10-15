# ESBv4 Quote Timeout 78 To 80 DQL

## Decision tree

```
Run check 1 (esbv4 logs in Dynatrace?)
 0 rows → esbv4 not onboarded → onboarding request (like portals-amp)
 rows → run check 2 (does the ID parse work?)
   query column empty → adjust the parse pattern to the real ID format
   query filled → run #78, #79, #80
     rows → those are the channel's quote requests that timed out at pc
     0 rows → no timeouts for that channel in 24 hours (good)
```

## Short takeaway

| SPL | Channel | What it finds |
|---|---|---|
| #78 | inswebauto | inswebauto car-insurance quote requests that timed out at pc |
| #79 | inswebbike | inswebbike bike-insurance quote requests that timed out at pc |
| #80 | kakakucomauto | kakaku.com car-insurance quote requests that timed out at pc |

The three queries are identical except for the channel name in the first `contains()`.

## Summary

Each query works in two steps. The inner part (inside `lookup`) collects the request IDs of every pc quote call that failed with "Timeout exceeded". The outer part takes the "Sending request" lines for one channel and keeps only those whose ID is in that list. The result is the list of that channel's quote requests that timed out.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| esbv4 | The service bus that forwards quote requests from partner sites to pc. |
| Channel | The partner site sending the quote: inswebauto, inswebbike, kakakucomauto. |
| pc | PolicyCenter, the system that calculates the quote. |
| Request ID | A UUID like `1a2b3c4d-1a2b-1a2b-1a2b-1a2b3c4d5e6f` that ties the request and error lines together. |
| Subsearch | Splunk inner search `[ ... ]` that runs first and feeds its results to the outer search. |
| `lookup` | DQL command that joins rows from a second query by a shared field. |

### How the Splunk query maps to DQL

| Splunk part | DQL part |
|---|---|
| `index=esbv4` | `startsWith(src, "esbv4")` |
| Inner `search "...Timeout exceeded."` | Inner `filter contains(content, "...Timeout exceeded.")` |
| `rex "(?<query>[0-9a-z]{8}-...{12})"` | `parse content, "LD ([0-9a-z]{8} '-' ... [0-9a-z]{12}):query"` |
| `fields query \| format` | `dedup query \| fields query` |
| `[ ... ] AND "Sending request to .../<channel>/online/_quote"` | Outer `contains()` plus `lookup ... \| filter isNotNull(err.query)` |

### Step by step (same for all three)

| Step | Line | What it does |
|---|---|---|
| 1 | `fetch logs, from:now()-24h` | Last day of logs. |
| 2 | `startsWith(src, "esbv4")` | Only esbv4 pods. |
| 3 | `contains(content, "Sending request to /esb/ebroker/<channel>/online/_quote")` | Only this channel's quote requests. |
| 4 | `parse ... :query` | Pull the request ID out of the line. |
| 5 | `lookup [ ... ]` | Inner query: IDs of pc quote timeouts. |
| 6 | `filter isNotNull(err.query)` | Keep only requests whose ID timed out. |
| 7 | `sort` and `fields` | Newest first, show time, pod, ID, line. |

### Things to verify

| Item | Why |
|---|---|
| esbv4 logs in Dynatrace | Check 1. If 0, nothing else will work. |
| ID format | Check 2. The pattern expects lowercase letters and digits in 8-4-4-4-12 form. |
| #78 SPL top | Cut off in the screenshot. Same pattern as #79 assumed. |
| Time range | Splunk used the time picker. DQL uses 24 hours. Change `from:` if needed. |

## Result

### #78 inswebauto

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Sending request to /esb/ebroker/inswebauto/online/_quote", caseSensitive:false)
| parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
| lookup [
    fetch logs, from:now()-24h
    | fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
    | filter startsWith(src, "esbv4")
    | filter contains(content, "Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded.", caseSensitive:false)
    | parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
    | filter isNotNull(query)
    | dedup query
    | fields query
  ], sourceField:query, lookupField:query, prefix:"err."
| filter isNotNull(err.query)
| sort timestamp desc
| fields timestamp, src, query, content
```

### #79 inswebbike

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Sending request to /esb/ebroker/inswebbike/online/_quote", caseSensitive:false)
| parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
| lookup [
    fetch logs, from:now()-24h
    | fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
    | filter startsWith(src, "esbv4")
    | filter contains(content, "Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded.", caseSensitive:false)
    | parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
    | filter isNotNull(query)
    | dedup query
    | fields query
  ], sourceField:query, lookupField:query, prefix:"err."
| filter isNotNull(err.query)
| sort timestamp desc
| fields timestamp, src, query, content
```

### #80 kakakucomauto

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Sending request to /esb/ebroker/kakakucomauto/online/_quote", caseSensitive:false)
| parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
| lookup [
    fetch logs, from:now()-24h
    | fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
    | filter startsWith(src, "esbv4")
    | filter contains(content, "Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded.", caseSensitive:false)
    | parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
    | filter isNotNull(query)
    | dedup query
    | fields query
  ], sourceField:query, lookupField:query, prefix:"err."
| filter isNotNull(err.query)
| sort timestamp desc
| fields timestamp, src, query, content
```

Checks (esbv4 present, ID parse, all three channels in one table) are in `1-esbv4-quote-timeout-78-80-dql-checks.dql`.

## Data flow map

```
Partner site (inswebauto / inswebbike / kakakucomauto)
  -> esbv4: "Sending request to /esb/ebroker/<channel>/online/_quote" (with request ID)
  -> pc quote API
  -> no answer in time -> esbv4: "... /ebroker/quote' failed: Timeout exceeded." (same request ID)

DQL
  inner: timeout lines -> request IDs
  outer: channel request lines -> keep if ID in inner list -> timed-out requests for that channel
```

## Related files

| File | What it holds |
|---|---|
| `1-esbv4-quote-timeout-78-80-dql-78-inswebauto.dql` | #78 |
| `1-esbv4-quote-timeout-78-80-dql-79-inswebbike.dql` | #79 |
| `1-esbv4-quote-timeout-78-80-dql-80-kakakucomauto.dql` | #80 |
| `1-esbv4-quote-timeout-78-80-dql-checks.dql` | Checks and combined table |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Mapping notes |
| `2-result.md` | Result summary |
| `3-glossary.md` | Glossary |
| `1.sh` | Git one-liners |

## Commands

See `1.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/1-esbv4-quote-timeout-78-80-dql
git commit -m "esbv4 quote timeout 78-80 DQL"
git push
```
