# ESBv4 NetSuite HTTP Error Pic

## Decision tree

```
Main DQL rows?
 yes → 5-minute chart → burst = outage, steady = auth or config
 no → esbv4 check query → nothing? → onboarding request
```

## Data flow

```
ESBv4 -> HTTPS to NetSuite fails -> error log -> Grail -> esbv4 filter -> phrase filter -> table
```
