# PayWithCreditCard Zero Confirmed Pic

## Decision tree

```
payment filter → 0 (84 GiB)
name check → 0 (171 GiB)
 text search, no app filter → rows? use that field : onboarding request
```

## Data flow

```
pods -> S3 -> Splunk (75/h)
pods -X-> Dynatrace (0)
```
