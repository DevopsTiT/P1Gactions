# eopt Not In Log Forwarder Confirmed Pic

## Decision tree

```
PRD? → 134 GiB per hour → yes
eopt in any field, 24 h? → 0 → no
eopt in forwarder namespaces? → not in the 11 → no
→ request onboarding of eopt-prod-axa-li-jp
→ after onboarding → check fields → adjust alerts 31 and 34
```

## Data flow

```
11 namespaces → log forwarder → Grail ✔
eopt → S3 → Splunk only → Grail 0 lines ✘
```
