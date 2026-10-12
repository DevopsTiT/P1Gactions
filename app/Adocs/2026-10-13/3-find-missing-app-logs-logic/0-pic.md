# Find Missing App Logs Logic Pic

## Decision tree

```
0 records
 1 platform ok? → no → fix tenant
 2 entity exists? → no → onboard monitoring
 3 any log in any field? → yes → fix filter
 4 sibling path? → multilogforwarder
 5 app on path? → no → request onboarding (eopt)
 6 logs elsewhere? → Splunk via S3
```

## Data flow

```
wide → narrow: platform → entity → any log → ingest path → membership → verdict
```
