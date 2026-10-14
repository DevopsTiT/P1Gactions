# BC2 Index Errors And SSL DQL

## Decision tree

```
Which SPL?
 #32 many indexes + SSL / timeout / socket / connect → count per app
 #33 to #40, #42 to #44 → app prefix filter + phrase filter
 #41 duplicate CVS records → parse key=value → count > 1 → sort by date
Every query: "index" does not exist in Dynatrace
 → src = pod name, or host name if no pod name
 → index=bc2* becomes startsWith(src, "bc2")
 0 rows? → run the check query → fix the prefix
 still 0? → logs not in Dynatrace → onboarding request (S3-forwarded apps like pc2 and bc2 are at risk)
```

## Short takeaway

| SPL | What it finds |
|---|---|
| #32 | Network-type errors (SSL, timeout, socket, connect) counted per app |
| #33 | pc2-batch lines with both `bcCancellationFinished_Adj` and `WaitForMidNight` |
| #34 | bc2 GMO SEARCHTRADE exception |
| #35 | bc2-batch DirectDebit rows with a different PaymentDueDate |
| #36 | bc2 ConcurrentDataChangeException in PolicyDlnqProcess |
| #37 | bcsubledger lines with Exception, ERROR, or WARN |
| #38 and #44 | bc2-ui GMO error code `E01050004` (the two SPLs are identical) |
| #39 | bc2 CVS offline payment notification exception |
| #40 | bc2 MultipleMatchesException on ContactID_Adj |
| #41 | bc2-batch CVS Offline quick records that appear more than once |
| #42 | "API - Exception when executing" in bc2-ui, bc2-batch, bcsubledger |
| #43 | GMO EXECTRAN exception in the same three apps |

## Summary

These are mostly "app plus phrase" searches. The repeated problem is Splunk `index`, which Dynatrace does not have. Each query builds `src` from the pod name (or host name) and matches its prefix. #32 counts results per app. #41 needs key=value parsing and a duplicate check.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| `index` | Splunk storage area. Not present in Dynatrace. |
| `src` | Helper field in these queries: pod name, or host name if no pod name. |
| `startsWith()` | True when text begins with a value. Replaces `index=bc2*`. |
| `matchesValue()` | Matches against a list of wildcard patterns, ignoring case. |
| `matchesPhrase()` | Whole-word match, ignoring case. Same as a Splunk bare term. |
| GMO | Payment gateway used by bc2. |
| CVS | Convenience store payment channel. |

### Splunk rules that change the translation

| Splunk rule | Effect in DQL |
|---|---|
| `OR` binds tighter than the implicit `AND` | #32 is (index list) AND (SSL or timeout or socket or connect). |
| A bare word matches a whole word | `matchesPhrase()` rather than `contains()`. |
| `*` inside quotes is a wildcard | #35 splits the phrase into three `contains()` parts. |
| `" ERROR "` with spaces | Still a whole-word search. `matchesPhrase(content, "ERROR")`. |
| `#OR "Operation started"` | It is commented out in the SPL. Left out. |
| Auto key=value fields | #41 parses `Identifier=`, `Amount=`, `PaymentDate=` with `parse`. |

### Things to verify

| Item | Why |
|---|---|
| App prefixes | Confirm the names with the check query. |
| #32 grouping | Grouped by namespace, then workload, then src. Pick the one closest to Splunk index. |
| #34 Japanese text | Unreadable in the screenshot. Filter uses the English part only. |
| #41 delimiter | Assumes a comma after each value. Change it if the log is different. |
| #41 timezone | Assumes JST in PaymentDate. |

## Result

All queries are in `14-bc2-index-errors-ssl-dql.dql`. The chat reply has every query in full.

## Data flow map

```
#32  logs -> src in app list -> SSL / timeout / socket / connect -> count per app
#33–#40, #42–#44  logs -> src prefix -> phrase(s) -> newest first
#41  logs -> bc2-batch -> CVS Offline quick record -> dedup line
     -> parse Identifier, Amount, PaymentDate -> count > 1 -> sort by date
```

## Related files

| File | What it holds |
|---|---|
| `14-bc2-index-errors-ssl-dql.dql` | All queries and the check query |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Mapping notes |
| `2-result.md` | Result summary |
| `3-glossary.md` | Glossary |
| `14.sh` | Git one-liners |

## Commands

See `14.sh`. Nothing is run automatically.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-14/14-bc2-index-errors-ssl-dql
git commit -m "BC2 index errors and SSL DQL"
git push
```
