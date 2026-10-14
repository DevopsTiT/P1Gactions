# BILoss Upload To CMX Pic

## Decision tree

```
Run the main DQL
 rows returned? → done
 0 rows? → run check query
   name in k8s.pod.name? → filter on coalesce(k8s.pod.name, host.name)
   nothing found? → logs not in Dynatrace → onboarding request
 matched_keywords empty? → add caseSensitive:false to if() checks
```

## Data flow

```
BILoss-upload-to-cmx-prod -> Grail -> host filter -> 3-phrase filter -> tag -> JST time -> sort -> table
```
