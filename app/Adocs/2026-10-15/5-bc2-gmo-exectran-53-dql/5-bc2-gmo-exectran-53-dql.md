# BC2 GMO EXECTRAN 53 DQL

## Decision tree

```
Run #53 list query
 rows returned? → GMO card transaction (EXECTRAN) calls are failing
                 → check which app (src) and when → run the hourly count
                 → spike at one time → GMO outage or network issue at that time
                 → steady errors → card data or config problem, read the content
 0 rows? → no EXECTRAN exceptions in 24h
          → if you expected some, run only the fetch and startsWith lines to confirm the logs exist
```

## Short takeaway

| Question | Answer |
|---|---|
| Was #53 missed? | No. It is the same query as #49 and was merged as "#49 and #53". |
| What does it find? | Log lines where a GMO EXECTRAN card call threw an exception. |
| Which apps? | bc2-ui, bc2-batch and bcsubledger. |

## Summary

Splunk #53 searches three indexes for the phrase "Exception during GMO call EXECTRAN". In DQL the three indexes become three `startsWith` checks on the pod or host name, and the quoted phrase becomes `contains`.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| GMO | The GMO Payment Gateway, used for card payments. |
| EXECTRAN | The GMO API call that actually charges the card. |
| `src` | Pod name or host name, lower-cased. It stands in for the Splunk index. |
| `contains` | Plain substring match, used for Splunk quoted phrases. |

### Splunk to DQL

| Splunk #53 | DQL |
|---|---|
| `(index=bc2-ui OR index=bc2-batch OR index=bcsubledger)` | `startsWith(src, "bc2-ui") or startsWith(src, "bc2-batch") or startsWith(src, "bcsubledger")` |
| `AND "Exception during GMO call EXECTRAN"` | `contains(content, "Exception during GMO call EXECTRAN", caseSensitive:false)` |

## Result

The query is in `5-bc2-gmo-exectran-53-dql.dql`, together with an optional hourly count per app.

```
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2-ui") or startsWith(src, "bc2-batch") or startsWith(src, "bcsubledger")
| filter contains(content, "Exception during GMO call EXECTRAN", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

## Data flow map

```
bc2-ui, bc2-batch, bcsubledger pods
 → call GMO EXECTRAN → exception logged
 → OneAgent → Dynatrace Grail
 → fetch logs → startsWith(app) → contains(phrase) → newest first
```

## Related files

| File | Purpose |
|---|---|
| `5-bc2-gmo-exectran-53-dql.dql` | List query and hourly count |
| `0-pic.md` | Decision tree and data flow |
| `1-investigation.md` | Why #53 was merged with #49 |
| `2-result.md` | How to read the result |
| `3-glossary.md` | Terms |
| `5.sh` | Git one-liners (not run) |

## Commands

See `5.sh`. None of these commands have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/5-bc2-gmo-exectran-53-dql
git commit -m "bc2 gmo exectran 53 dql"
git push
```
