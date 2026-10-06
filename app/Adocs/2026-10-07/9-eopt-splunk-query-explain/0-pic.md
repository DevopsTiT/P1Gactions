# eopt Splunk Query Picture

```
index eopt-prod-axa-li-jp
 Frontend → spath (JSON) → level → upper → ERROR → email
 Backend  → rex (text start) → level → upper → ERROR → email
```
