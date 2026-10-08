# Readiness Probe Pic

```
statusCode on health lines?
 no → Splunk alert dead → log statusCode or use k8s Unhealthy events
 yes → newest status per pod != 200 in 5m?
   yes → problem (per pod) → kubectl describe pod
   no → closed
```

```
Splunk: newest 2 lines → code changed? → mail (also on recovery, silent while broken)
Dynatrace: per pod → newest code != 200 → open; == 200 → close
```
