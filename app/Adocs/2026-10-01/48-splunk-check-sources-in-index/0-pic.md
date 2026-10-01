# Splunk Source Check Pic

```
list of paths
  → search 1 tstats by source (your index)
      FOUND     → check last_seen
      NOT FOUND → search 2 (path*) rotated?
                → search 3 (index=*) other index?
                → search 4 (metadata) stopped long ago?
                → search 5 (_internal) permission or not watched?
                → server: btool inputs list, splunk list monitor, ls -l
```
