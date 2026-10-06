# Why FieldsAdd Check Pic

```
8 log rows
 → fieldsAdd check = "datalake_batch_result" (same on every row)
   → alertIdentityFields[0] = "check"
     → all rows share one identity → 1 problem → 1 email
```

```
identity = content → 8 problems (bad)
identity = check   → 1 problem  (good)
```
