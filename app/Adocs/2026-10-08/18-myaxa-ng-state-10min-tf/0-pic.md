# MyAXA NG State Pic

```
NG run 10+ min ago? -> no -> nothing
  yes -> newer run with same NG result? -> no -> nothing
    yes -> maintenance now? -> yes -> nothing
      no -> problem per JobName (medium, pagerduty 0)
```

```
Jenkins MyAXA checks -> ceaa2099 log -> Grail -> detector (60m)
  -> old NG vs newest run + maintenance lookup -> problem -> email
```
