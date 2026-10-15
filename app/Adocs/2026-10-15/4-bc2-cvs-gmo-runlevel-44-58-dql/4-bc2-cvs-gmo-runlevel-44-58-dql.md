# BC2 CVS GMO RunLevel DQL

## Decision tree

```
Splunk line → what kind of search?
 index=xxx* → src = pod or host name → startsWith(src, "xxx")
 bare word (ERROR, Values) → matchesPhrase (whole word, ignores case)
 "quoted phrase" → contains(..., caseSensitive:false)
 field=value (errcode=E01) → parse the field → compare exactly
 NOT word → not matchesPhrase
 stats count by + where count > 1 → summarize by:{ } → filter count > 1
 Japanese text garbled or line cut off → placeholder → fill in from the real Splunk query
```

## Short takeaway

| Question | Answer |
|---|---|
| How many queries? | 15 numbered lines (#44 to #58). Two are repeats, so there are 13 distinct DQL queries. |
| Which are repeats? | #53 is the same as #49. #56 is the same as #55. |
| Which need your input? | #54 (unreadable Japanese text) and #58 (cut off in the screenshot). |
| Trickiest one? | #50, because `errcode=E01` is an exact field match, not a text search. |

## Summary

Most of these are "find log lines with this text in this app" searches, which become `startsWith(src, ...)` plus `contains` or `matchesPhrase`. #47 counts duplicate payment records, and #50 needs the errcode field parsed so that `E01` does not also match longer codes like `E01390002`.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| `src` | The pod name or host name, lower-cased. It stands in for the Splunk index. |
| `matchesPhrase` | Matches a whole word or phrase, ignoring case. Used for Splunk bare words. |
| `contains` | Plain substring match. Used for Splunk quoted phrases. |
| `parse` | Pulls a value out of the log text into its own field. |
| `summarize` | DQL version of Splunk `stats`. |

### Line by line

| # | Splunk idea | DQL idea |
|---|---|---|
| 44 | bc2-ui line with `errcode=E01&errinfo=E01050004` | `contains` the full string |
| 45 | bc2 ERROR in Integration.CVS for CvsOfflinePaymentNotification | Two `matchesPhrase` plus one `contains` |
| 46 | bc2 MultipleMatchesException on ContactID_Adj | Three `matchesPhrase` |
| 47 | bc2-batch duplicate CVS Offline quick records | parse 3 fields, `summarize`, keep count > 1, sort by date |
| 48 | "API - Exception when executing" in 3 apps | Three `startsWith` joined by `or` |
| 49 | GMO EXECTRAN exception in 3 apps | Same pattern as #48 |
| 50 | "Map returned by method call" with errcode E01, excluding 3 codes | parse errcode, `== "E01"`, three `not matchesPhrase` |
| 51 | saveCardWithOrderID errors on `MW-Writer-[54]` | The Splunk `\[54\]` escapes become a plain `[54]` in `contains` |
| 52 | GMO SearchTrade confirm ExecTran | `contains` in 3 apps |
| 53 | Same as #49 | Reuse #49 |
| 54 | pc2-ui or bc2-ui "Operation failed" for a Producer | Japanese text unreadable, so placeholders |
| 55 | "Producer Contact is missing for Producer" | `contains` in bc2 |
| 56 | Same as #55 | Reuse #55 |
| 57 | bc2 Server.RunLevel ready | Two `matchesPhrase` |
| 58 | bcsubledger plus unknown text | Starter query only |

## Result

All queries are in `4-bc2-cvs-gmo-runlevel-44-58-dql.dql`. Paste one block at a time into a Dynatrace Notebook.

| Item | What to do |
|---|---|
| #54 | Copy the exact Japanese words from Splunk into `<JP_TEXT_1>` and `<JP_TEXT_2>`. |
| #58 | Send the full Splunk line and I will finish the filter. |
| #47 delimiter | If no rows appear, check whether the fields end with `,` or a space, and adjust the parse. |

## Data flow map

```
Pods (bc2-ui, bc2-batch, bcsubledger, pc2-ui)
 → OneAgent ships logs → Dynatrace Grail
 → fetch logs → src = pod or host name → startsWith(app)
 → text filters (contains, matchesPhrase, parse)
 → sort newest first → rows you read
```

## Related files

| File | Purpose |
|---|---|
| `4-bc2-cvs-gmo-runlevel-44-58-dql.dql` | All DQL queries |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Mapping details |
| `2-result.md` | What to do next |
| `3-glossary.md` | Terms |
| `4.sh` | Git one-liners (not run) |

## Commands

See `4.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/4-bc2-cvs-gmo-runlevel-44-58-dql
git commit -m "bc2 cvs gmo runlevel 44-58 dql"
git push
```
