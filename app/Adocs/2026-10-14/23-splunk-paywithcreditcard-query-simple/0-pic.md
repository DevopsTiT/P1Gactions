# Splunk PayWithCreditCard Query Simple Pic

## Step tree

```
pick app + last hour
 → clean backslashes (2 replaces)
 → spath: JSON to fields
 → keep url has payWithCreditCard_Adj AND type EXECUTION_COMPLETED
 → 75 events
```

## Data flow

```
pod -> S3 -> Splunk -> pick -> clean -> read -> keep -> 75
```
