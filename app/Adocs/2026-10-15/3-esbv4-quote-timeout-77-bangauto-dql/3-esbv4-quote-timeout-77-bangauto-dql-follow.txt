# ESBv4 Quote Timeout 77 Bangauto

## Decision tree

```
Run #77 list query
 rows returned? → yes → these bangauto quote requests timed out at pc quote
                       → check the times, then check the pc-inssuite quote service
 0 rows? → run the count version
            requests = 0 → no bangauto traffic in 24h, or esbv4 logs are missing in Dynatrace
            requests > 0 and timed_out = 0 → bangauto is healthy
```

## Short takeaway

| Question | Answer |
|---|---|
| What does #77 find? | bangauto quote requests whose request ID also has a pc quote "Timeout exceeded" error. |
| How is it different from #78? | Only the channel name changes, from `inswebauto` to `bangauto`. |
| How does the Splunk subsearch map to DQL? | It becomes a `lookup` on the request ID. |

## Summary

Splunk #77 first collects the request IDs of every pc quote timeout. It then keeps only the bangauto `_quote` requests that have one of those IDs. The DQL does the same thing with `parse` to pull out the ID and `lookup` to match it.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| Subsearch | The `[ ... ]` part in Splunk. It runs first and feeds its results into the outer search. |
| `rex` | Splunk command that pulls a value out of the raw log text with a regex. |
| `parse` | The DQL equivalent of `rex`. It uses DPL patterns. |
| `lookup` | A DQL join. It adds fields from another query when a key matches. |
| Request ID | The UUID after `LD ` in the esbv4 log line. It links the request line to the error line. |

### Splunk to DQL line by line

| Splunk | DQL |
|---|---|
| `index=esbv4` | `filter startsWith(src, "esbv4")` |
| `search "Error(esb-ebroker.xml) ... Timeout exceeded."` | `filter contains(content, "/pc/service/edge/ebroker/quote' failed: Timeout exceeded.")` |
| `rex field=_raw "(?<query>UUID)"` | `parse content, "LD (UUID pattern):query"` |
| `fields query` then `format` | `dedup query` then `fields query` inside `lookup [ ]` |
| `AND "Sending request to /esb/ebroker/bangauto/online/_quote"` | `filter contains(content, "Sending request to /esb/ebroker/bangauto/online/_quote")` |
| Subsearch IDs match the outer events | `filter isNotNull(err.query)` |

## Result

The DQL is in `3-esbv4-quote-timeout-77-bangauto-dql-77-bangauto.dql`. It contains the list query and a one-row count query.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "esbv4")
| filter contains(content, "Sending request to /esb/ebroker/bangauto/online/_quote", caseSensitive:false)
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

## Data flow map

```
esbv4 pod logs (Dynatrace Grail)
 → inner query: pc quote "Timeout exceeded" lines → request IDs
 → outer query: bangauto "_quote" request lines → request IDs
 → lookup: match on request ID
 → keep only matched rows → list of timed-out bangauto requests
```

## Related files

| File | Purpose |
|---|---|
| `3-esbv4-quote-timeout-77-bangauto-dql-77-bangauto.dql` | List query and count query |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Splunk to DQL mapping |
| `2-result.md` | Final query and how to read it |
| `3-glossary.md` | Terms |
| `3.sh` | Git one-liners (not run) |

## Commands

See `3.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/3-esbv4-quote-timeout-77-bangauto-dql
git commit -m "esbv4 quote timeout 77 bangauto dql"
git push
```
