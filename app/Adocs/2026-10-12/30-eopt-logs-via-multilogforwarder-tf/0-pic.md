# eopt Logs Via Multilogforwarder Pic

## Decision tree

```
search hits → Splunk internal logs only
other apps → multilogforwarder → Dynatrace ✔
eopt → not on forwarder ✘
 → ask: add eopt-prod-axa-li-jp
 → check query 1 rows → detector live → switch off Splunk alert
```

## Data flow

```
eopt pods → multilogforwarder → (add Dynatrace handler) → Grail
  → detector (namespace + pod prefix + ERROR) → problem → email
```
