# Emma BE ESG Timeout Pic

## Decision tree

```
Part A → host or pod starts with myaxabackend- → api-jp-cert + SocketTimeoutException
Part B → Problem routing to + timed out + myaxa-api.alj.intraxa
A or B → count → more than 20 in 5 min → problem high → PagerDuty
pod names not in host.name? → check query 1
```

## Data flow

```
myaxabackend pods → ESG timeout → pod logs ─┐
API gateway → routing timed out → syslog ───┤→ Grail → detector (5 min, > 20)
                                             → problem high → PagerDuty + email
```
