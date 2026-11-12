# CloudWatch Entity Variable

```
default 0 on the log group
  fieldsAdd dt.entity.host
  {dt.entity.host}
  above -1
  disable after the problem shows
```
