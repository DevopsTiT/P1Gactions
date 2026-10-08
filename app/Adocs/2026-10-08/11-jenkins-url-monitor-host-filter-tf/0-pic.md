# Jenkins URL Monitor Host Filter Pic

```
fetch logs (15 min)
 → host ceaa2099*?        no → drop
 → source has /console?   no → drop
 → "[HTTP Monitor]"?      no → drop
 → per application + check: fails >= 2 and no 200 → problem
```
