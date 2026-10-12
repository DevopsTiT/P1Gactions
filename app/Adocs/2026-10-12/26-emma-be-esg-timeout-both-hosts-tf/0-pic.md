# Emma BE ESG Timeout Both Hosts Pic

## Decision tree

```
Backend → myaxabackend-* pods → SocketTimeoutException to api-jp-cert
Gateway → host EEAA2015 + source local4.log → Problem routing to ... timed out
either → count → more than 20 in 5 min → problem high → PagerDuty + email
```

## Data flow

```
pods ───────────────┐
EEAA2015 local4.log ┴→ Grail → detector (5 min, > 20) → problem high → workflow
```
