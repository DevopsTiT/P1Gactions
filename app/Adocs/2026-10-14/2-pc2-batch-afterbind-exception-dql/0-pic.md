# PC2 Batch AfterBind Exception DQL Pic

## Decision tree

```
host prefix pc2-batch-inssuite-prod- (host.name or k8s.pod.name)
 + both phrases → rows
 empty? → check 1 → no pc2 logs → onboarding gap
                  → logs exist → check 2 → fix field
```

## Data flow

```
pc2 pods → S3 → Splunk ✔
pc2 pods → Dynatrace ? → fetch logs → two phrases → table
```
