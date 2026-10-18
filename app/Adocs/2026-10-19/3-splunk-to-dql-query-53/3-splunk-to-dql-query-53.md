# Splunk To DQL Query 53

## Decision tree

```
53: index bc2-ui|bc2-batch|bcsubledger + "Exception during GMO call EXECTRAN"
  → same pattern as 54 in your file
  → src = lower(coalesce(k8s.pod.name, host.name))
  → startsWith(src, …) for each index name
  → contains(content, exception phrase)
```

## Short takeaway

| Splunk | DQL |
|---|---|
| `index=bc2-ui` | `startsWith(src, "bc2-ui")` |
| `index=bc2-batch` | `startsWith(src, "bc2-batch")` |
| `index=bcsubledger` | `startsWith(src, "bcsubledger")` |
| `"Exception during GMO call EXECTRAN"` | `contains(content, "…", caseSensitive:false)` |

## Summary

Query 53 is the same shape as your already-converted GMO / bc2 blocks: map Splunk indexes to `src` prefixes, then filter the exception phrase in `content`.

## Investigation

### Splunk (source)

```
(index=bc2-ui OR index=bc2-batch OR index=bcsubledger)
AND "Exception during GMO call EXECTRAN"
```

### DQL

```dql
fetch logs, from:now()-24h
| fieldsAdd src = lower(coalesce(k8s.pod.name, host.name))
| filter startsWith(src, "bc2-ui")
    or startsWith(src, "bc2-batch")
    or startsWith(src, "bcsubledger")
| filter contains(content, "Exception during GMO call EXECTRAN", caseSensitive:false)
| sort timestamp desc
| fields timestamp, src, content
```

If indexes live in Grail buckets instead of pod/host names, add:

```dql
| filter startsWith(lower(dt.system.bucket), "bc2-ui")
    or startsWith(lower(dt.system.bucket), "bc2-batch")
    or startsWith(lower(dt.system.bucket), "bcsubledger")
    or startsWith(src, "bc2-ui")
    or startsWith(src, "bc2-batch")
    or startsWith(src, "bcsubledger")
```

## Result

| Check | Pass |
|---|---|
| Index scope | bc2-ui / bc2-batch / bcsubledger |
| Phrase | Exception during GMO call EXECTRAN |
| Pattern | Matches query 54 style in your notes |

## Data flow map

```
Splunk indexes + phrase
  → DQL fetch logs
  → src from pod/host
  → filter src prefixes
  → filter content phrase
  → sort / fields
```

## Related files

| File | Purpose |
|---|---|
| `3-splunk-to-dql-query-53.md` | This note |
| `3-splunk-to-dql-query-53.dql` | Pasteable DQL |
| `3.sh` | Git one-liners (not run) |

## Commands

See `3.sh`. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-19/3-splunk-to-dql-query-53
git commit -m "splunk to dql query 53"
git push
```
