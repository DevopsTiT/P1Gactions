# BC2 GMO Duplicate OrderID DQL Pic

## Decision tree

```
bc2 pods + GMO parameter lines
 → orderid between "&orderid=" and "&"
 → dedup → cut 0-18, 18-24, 24-end → pattern
 → count per pattern > 1 → duplicates
 empty? → check 1 logs exist? → check 2 cut correct?
```

## Data flow

```
bc2 pods → S3 → Splunk ✔ ; Dynatrace ? → orderid → pattern → count > 1
```
