# CCI Goal Management URL Check Pic

```
"Management" URL check (ceaa2099) -> drop ABORTED
  200 in last 30 min? -> yes -> OK
  no, 2+ non-200 -> problem (high, PagerDuty off)
  next 200 -> closes
```

```
Jenkins -> ceaa2099 log -> Grail -> detector (30m) + configuration lookup -> problem -> email
```
