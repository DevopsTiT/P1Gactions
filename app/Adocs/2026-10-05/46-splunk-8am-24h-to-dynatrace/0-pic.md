# 8am And 24h Picture

## Decision Tree

```
08:00 timing needed? → yes → workflow (seq 42)
                     → no  → detector (seq 43)
Expires 24h          → storage only → nothing to copy
```

## Data Flow

```
Splunk 08:00 → search → email → kept 24 h
Detector every minute → problem → closes by rule
```
