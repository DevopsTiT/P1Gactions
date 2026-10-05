# AGPO EIP Claims Picture

## Decision Tree

```
AGPO Auth0 errors  → > 1 in 5 min → rolling-sum detector → pages
EIP MQ timeout     → > 0 in 1 min → detector → email
Claims API ERROR   → > 0 in 10 min → detector → email (high)
no data? → check.dql 1 to 3 → fix namespace / pod / host
```

## Data Flow

```
pods and hosts → Grail logs → 3 detectors → problems → standard SILVA / PagerDuty flow
```
