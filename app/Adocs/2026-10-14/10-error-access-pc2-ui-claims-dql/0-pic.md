# Error Access And PC2 UI Claims Pic

## Decision tree

```
#11 / #12 → word search + access status codes
  access part empty? → run access check query → fix source field
#13 → pc2-ui + claims URL + FAIL
  0 rows? → run pc2-ui check query
    nothing found? → logs not in Dynatrace → onboarding request
```

## Data flow

```
#11/#12: Grail -> error|failed|severe OR (access_* AND 404|500|503) -> sort -> table
#13:     Grail -> pc2-ui -> ESB host AND claims path -> FAIL -> sort -> table
```
