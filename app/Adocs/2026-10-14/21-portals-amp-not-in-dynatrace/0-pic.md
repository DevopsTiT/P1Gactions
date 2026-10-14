# Portals AMP Not In Dynatrace Pic

## Decision tree

```
0 records for portals-amp (171 GiB scanned)
 A: text search finds rows? → use that field
 B: bucket missing? → permission request
 neither → logs not forwarded → onboarding request
```

## Data flow

```
pods -> S3 -> Splunk (75/h)
pods -X-> Dynatrace (0)
fix: add namespace to ClusterLogForwarder Dynatrace output
```
