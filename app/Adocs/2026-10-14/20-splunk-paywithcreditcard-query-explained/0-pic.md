# Splunk PayWithCreditCard Query Pic

## Step tree

```
1 sourcetype + earliest=-1h   → pick logs
2 replace \" → "              → unescape quotes
3 replace \ → nothing         → clean backslashes
4 spath                       → JSON to fields
5 search url + type           → completed card payments
```

## Data flow

```
S3 -> Splunk -> pick -> clean -> clean -> parse -> filter -> 75 events
```
