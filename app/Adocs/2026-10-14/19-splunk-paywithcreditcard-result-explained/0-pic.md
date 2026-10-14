# Splunk PayWithCreditCard Result Pic

## Decision tree

```
75 events in 1 hour → completed card payments → healthy
url is a full URL → use contains(), not ==
source is S3 → check if logs are in Dynatrace
  found → compare count with 75
  not found → onboarding request
```

## Data flow

```
portal -> api-gateway -> portals-amp-backend (2 pods) -> PolicyCenter
       -> JSON log -> S3 -> Splunk -> 75 events
```
