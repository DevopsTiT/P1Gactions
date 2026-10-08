# Broker Policy Maintenance Pic

```
pod_count < 2 in last 60m?
 yes → kubectl get pods → pod missing? → restart or scale to 2
     → pods running? → forwarder or S3 stopped → check forwarder
 0 pods? → still 1 row → fires
```

```
2 web pods → logs → forwarder → Grail → countDistinct(pod) → < 2 → problem
```
