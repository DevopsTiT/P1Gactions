# Claim Job Over Run TF Explained Pic

## Decision tree

```
tf
 setup → Dynatrace plugin
 resource → detector
   query rows? → yes → problem per job_name → email
               → no → close
 claims_jobs filled? → no → never fires
```

## Data flow

```
STARTED line → Grail → detector (pair start and end per run, 15+ min open) → problem → workflow → email
```
