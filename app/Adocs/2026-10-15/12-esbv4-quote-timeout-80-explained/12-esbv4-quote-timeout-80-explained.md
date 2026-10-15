# ESBv4 Quote Timeout 80 Explained

## Decision tree

```
Question: which kakakucomauto quote requests timed out at the policy center?
 Step 1 (inner): find "quote ... failed: Timeout exceeded." lines → pull out request IDs
 Step 2 (outer): find "Sending request to /esb/ebroker/kakakucomauto/online/_quote" lines
 Step 3: keep only outer lines whose request ID is in the Step 1 list
 Rows returned → those customers' quotes failed → check pc-inssuite quote service at those times
 0 rows → run the ID parse test
  query empty → fix the parse pattern
  query filled → no kakakucomauto timeouts (or esbv4 logs missing)
```

## Short takeaway

| Question | Answer |
|---|---|
| What does #80 find? | kakakucomauto quote requests whose request ID also appears in a pc quote timeout error. |
| Why two searches? | The timeout line does not say which channel it was. The request line does. The request ID links them. |
| Splunk tool | A subsearch `[ ... ]` that returns the IDs as search words. |
| DQL tool | `lookup` that joins the two queries on the ID. |

## Summary

esbv4 writes two separate lines for one quote: "Sending request to .../kakakucomauto/..." when the call starts, and "Timeout exceeded" when the policy center does not answer in time. Only the first line names the channel, and only the second says it failed. Both carry the same request ID (a UUID), so both versions find the failed IDs first and then show the matching kakakucomauto request lines.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| esbv4 | The enterprise service bus. It forwards partner quote requests to the policy center. |
| kakakucomauto | The Kakaku.com car insurance comparison channel. |
| pc quote | The policy center quote API `/pc/service/edge/ebroker/quote`. |
| Request ID | A UUID such as `3f2a9c1e-7b4d-4e2a-9f10-5c6d7e8f9a0b`, written on every line of one request. |
| Subsearch | Splunk search inside `[ ]`. It runs first and its result is pasted into the outer search. |
| `rex` | Splunk command that pulls text out with a regex. |
| `format` | Splunk command that turns subsearch rows into a search string. |
| `lookup` (DQL) | Joins a second query's rows onto the first by a shared field. |
| `parse` (DQL) | Pulls text out with a DPL pattern. |

### The two log lines

| Line | Example | What it tells you |
|---|---|---|
| Request line | `... <request ID> ... Sending request to /esb/ebroker/kakakucomauto/online/_quote` | Which channel sent the quote |
| Error line | `... <request ID> ... Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod...:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded.` | That the pc call timed out |

### The Splunk search

```
index=esbv4
| search
  [| search "Error(esb-ebroker.xml) description: HTTP POST on resource 'https://pc-inssuite-prod.op-prod-lpl.axa-direct-jp.intraxa:443/pc/service/edge/ebroker/quote' failed: Timeout exceeded."
   | rex field=_raw "(?<query>[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{4}-[0-9a-z]{12})"
   | fields query
   | format]
  AND "Sending request to /esb/ebroker/kakakucomauto/online/_quote"
```

### Splunk line by line

| Order | Line | What it does |
|---|---|---|
| 1 (runs first) | `search "Error(esb-ebroker.xml) ... Timeout exceeded."` | Finds every pc quote timeout error. |
| 2 | `rex ... (?<query>UUID)` | Pulls the request ID out of each error line into a field called `query`. |
| 3 | `fields query` | Keeps only the ID. |
| 4 | `format` | Turns the IDs into `( "id1" ) OR ( "id2" ) OR ...`. |
| 5 (outer) | `index=esbv4` | Searches the esbv4 logs. |
| 6 | `[ ... ] AND "Sending request to .../kakakucomauto/online/_quote"` | Keeps lines that contain one of the IDs and the kakakucomauto request text. |

The field is named `query` on purpose. Splunk treats a subsearch field called `query` (or `search`) specially: `format` writes the values as plain words, not as `query="id1"`. So the outer search looks for the ID anywhere in the raw text, without needing a `query` field.

### The DQL

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
    | filter contains(content, "/pc/service/edge/ebroker/quote' failed: Timeout exceeded.", caseSensitive:false)
    | parse content, "LD ([0-9a-z]{8} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{4} '-' [0-9a-z]{12}):query"
    | filter isNotNull(query)
    | dedup query
    | fields query
  ], sourceField:query, lookupField:query, prefix:"err."
| filter isNotNull(err.query)
| sort timestamp desc
| fields timestamp, src, query, content
```

### DQL line by line

| Line | What it does | Splunk equivalent |
|---|---|---|
| `fetch logs, from:now()-24h` | Reads logs from the last 24 hours. | Time picker |
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Makes one lower-case source name from pod or host. | (helper) |
| `filter startsWith(src, "esbv4")` | Keeps esbv4 logs. | `index=esbv4` |
| `filter contains(... kakakucomauto/online/_quote ...)` | Keeps kakakucomauto request lines. | `AND "Sending request to ..."` |
| `parse content, "LD (UUID):query"` | Pulls the request ID out of each request line. | (Splunk does not need this; it matches the ID as raw text) |
| `lookup [ ... ]` inner `filter contains(... Timeout exceeded.)` | Finds the timeout error lines. | Subsearch `search "...Timeout exceeded."` |
| inner `parse ... :query` | Pulls the ID out of each error line. | `rex (?<query>...)` |
| inner `filter isNotNull(query)` then `dedup query` then `fields query` | Makes a clean list of unique failed IDs. | `fields query` |
| `sourceField:query, lookupField:query` | Matches the outer ID to the inner ID. | `format` plus the implicit AND |
| `prefix:"err."` | Names the joined field `err.query`. | (none) |
| `filter isNotNull(err.query)` | Keeps only request lines that found a matching timeout. | Lines without a matching ID are not returned |
| `sort timestamp desc` and `fields ...` | Newest first, readable columns. | Default sort |

### Main differences

| Point | Splunk | DQL |
|---|---|---|
| How IDs are matched | Pasted in as `OR` words and matched anywhere in the text | Parsed on both sides, then joined exactly |
| Limits | Subsearch default 10,000 results and a time limit | `lookup` has no 10,000-ID cut-off of that kind |
| Case | Phrase search ignores case | `caseSensitive:false` added to match |
| ID regex | `[0-9a-z]{8}-...` | DPL `[0-9a-z]{8} '-' ...` (the dash is a quoted literal) |

## Result

Run the ID parse test in `12-esbv4-quote-timeout-80-explained.dql` first. If `query` is filled, run the main query. For a one-row count per channel, use the 2026-10-15 answer 2 query for kakakucomauto.

## Data flow map

```
Customer on Kakaku.com → quote request
 → esbv4 logs "Sending request to /esb/ebroker/kakakucomauto/online/_quote" (with request ID)
 → esbv4 calls pc-inssuite /pc/service/edge/ebroker/quote
 → no answer in time → esbv4 logs "failed: Timeout exceeded." (same request ID)

Query:
 inner: timeout lines → request IDs (unique list)
 outer: kakakucomauto request lines → request ID
 join on ID → only the requests that timed out
```

## Related files

| File | Purpose |
|---|---|
| `12-esbv4-quote-timeout-80-explained.dql` | Main query and ID parse test |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Splunk compared with DQL |
| `2-result.md` | What to run and how to read it |
| `3-glossary.md` | Terms |
| `12.sh` | Git one-liners (not run) |

## Commands

See `12.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/12-esbv4-quote-timeout-80-explained
git commit -m "esbv4 quote timeout 80 explained"
git push
```
