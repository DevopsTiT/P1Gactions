# Why eopt Query Has No Result Pic

## Decision tree

```
0 records
 small scan (3.36 GiB / 1 h)? → check tenant is DT PRD
 PRD and still 0? → eopt logs not ingested (App only OneAgent, S3 to Splunk only)
 → ask platform team to forward eopt logs to Dynatrace
```

## Data flow

```
eopt pods → S3 → Splunk ✔
eopt pods → OneAgent App only → host entity, no logs → Dynatrace logs ✘
```
