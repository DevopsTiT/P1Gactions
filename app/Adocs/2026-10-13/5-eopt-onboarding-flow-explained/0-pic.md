# eopt Onboarding Flow Explained Pic

## Decision tree

```
namespace in Dynatrace pipeline?
 yes → Grail → alerts can fire
 no (eopt) → Splunk only → alerts silent
after onboarding → host.name = pod? → yes fire / no → use k8s.pod.name
```

## Data flow

```
sibling pod → collector → Dynatrace pipeline → ingest → Grail ✔
eopt pod → collector → S3 → Splunk ✔ ; Dynatrace ✘
after: eopt pod → collector → Dynatrace pipeline → Grail → alerts 31, 34
```
