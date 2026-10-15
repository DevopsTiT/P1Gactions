# Why 80 DQL Shape

## Decision tree

```
Splunk #80 uses a subsearch [ ... | format ]
 DQL has no subsearch that pastes text into another search
  → need another way to say "keep lines whose ID is in this list"
   → lookup [inner query] on the ID   (Version 1, closest to Splunk)
   → or one scan + summarize by ID     (Version 2, cheaper)
 Splunk matched the ID as raw text; DQL must compare fields
  → parse the ID on BOTH sides
 Splunk index=esbv4 does not exist in Dynatrace
  → src = pod or host name → startsWith "esbv4"
 Splunk phrase search ignores case; DQL contains does not
  → caseSensitive:false
```

## Short takeaway

| Question | Answer |
|---|---|
| Why not copy the Splunk text? | DQL has no `[ ... ]` subsearch, no `format`, and no `index`. Each must be replaced. |
| What replaces the subsearch? | `lookup`, which joins the timeout-ID list onto the request lines. |
| Why parse the ID twice? | `lookup` compares two fields. The ID must be a field on both sides. |
| Is there a simpler way? | Yes. Version 2 reads the logs once and groups by request ID. |

## Summary

The DQL keeps Splunk's logic (failed IDs first, then the kakakucomauto requests with those IDs) but uses DQL building blocks. Every extra line exists because a Splunk feature has no direct DQL twin, or to stop the query silently returning 0 rows.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| Subsearch | Splunk inner search whose result is pasted into the outer search as text. |
| `format` | Splunk command that builds `( "id1" ) OR ( "id2" )` from subsearch rows. |
| `lookup` (DQL) | Adds fields from a second query to each row when a key matches. Rows with no match get null. |
| `summarize ... by:{ }` | DQL grouping, like Splunk `stats ... by`. |
| Grail scan | Each `fetch logs` reads data. Two fetches read the logs twice. |

### Why each part of the DQL is there

| DQL part | Why it is needed |
|---|---|
| `fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))` | Dynatrace has no `index`. The pod name (or host name if there is no pod) is the closest thing to "which app". `lower` avoids case surprises. |
| `filter startsWith(src, "esbv4")` | Replaces `index=esbv4`. `startsWith` because pod names have random suffixes like `esbv4-7d9f...`. |
| `filter contains(... kakakucomauto/online/_quote ..., caseSensitive:false)` | Replaces the quoted phrase. Splunk ignores case, so `caseSensitive:false` keeps the same behaviour. |
| Outer `parse ... :query` | Splunk found the ID anywhere in raw text. DQL `lookup` matches field to field, so the request line needs a `query` field too. |
| `lookup [ ... ]` | Replaces the subsearch. It is the DQL way to say "is this ID in that list?". |
| Inner `contains(... failed: Timeout exceeded.)` | Same as the Splunk inner search, but shortened to the unique end of the message so small changes in the start of the line do not break it. |
| Inner `parse ... :query` | Replaces `rex (?<query>...)`. |
| `filter isNotNull(query)` | Drops error lines where no ID was found, so null does not match null. |
| `dedup query` | One row per ID. Without it, an ID with two timeout lines could give two matches. |
| `fields query` | Sends only the ID into the join. Smaller and faster. |
| `prefix:"err."` | The joined field becomes `err.query`, so it does not overwrite the outer `query`. |
| `filter isNotNull(err.query)` | `lookup` keeps every outer row. Only rows that found a match have `err.query`. This line is what turns the join into "only the timed-out requests". |
| `from:now()-24h` on both | Both sides must cover the same time, or a request near the edge loses its timeout line. |

### Things that could not be copied directly

| Splunk feature | Why it cannot be copied | DQL replacement |
|---|---|---|
| `[ subsearch ]` | DQL cannot paste one query's result into another as search text. | `lookup` |
| `format` with field `query` | This text trick only exists in Splunk. | Field-to-field match |
| `index=esbv4` | Dynatrace stores logs in buckets, not Splunk indexes. | `startsWith(src, "esbv4")` |
| Raw-text ID match | DQL `lookup` needs a field. | `parse` on the outer side |
| Subsearch 10,000-result limit | Not relevant in DQL. | No change needed |

### Version 1 compared with Version 2

| Point | Version 1: lookup | Version 2: one scan |
|---|---|---|
| How close to Splunk | Very close: list, then match | Different shape, same answer |
| Log reads | Two `fetch logs` | One `fetch logs` |
| Output | The full request line | One row per failed ID with request and timeout times |
| Easy to explain | Yes, step by step like Splunk | Needs `summarize` and `countIf` |
| When to use | Learning and side-by-side checks with Splunk | Daily use and dashboards, cheaper on large data |

## Result

Version 1 was chosen because it mirrors the Splunk logic one step at a time, which makes it easy to compare results with Splunk. Version 2 in `13-why-80-dql-shape.dql` gives the same failed IDs with one log read, so use it if Version 1 is slow or costs too many scanned bytes.

## Data flow map

```
Splunk:
 subsearch: timeout lines → rex ID → format → "id1 OR id2 ..."
 outer: esbv4 + kakakucomauto text + any of those IDs as raw text

DQL Version 1:
 inner fetch: timeout lines → parse ID → dedup → ID list
 outer fetch: kakakucomauto lines → parse ID → lookup ID in list → keep matches

DQL Version 2:
 one fetch: kakakucomauto lines OR timeout lines → parse ID
 → group by ID → keep IDs that have both a request and a timeout
```

## Related files

| File | Purpose |
|---|---|
| `13-why-80-dql-shape.dql` | Version 1 and Version 2 |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Reason for each line |
| `2-result.md` | Which version to use |
| `3-glossary.md` | Terms |
| `13.sh` | Git one-liners (not run) |

## Commands

See `13.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/13-why-80-dql-shape
git commit -m "why 80 dql shape"
git push
```
