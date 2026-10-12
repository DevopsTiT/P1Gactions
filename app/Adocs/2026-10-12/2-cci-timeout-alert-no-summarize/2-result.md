# CCI Timeout Alert Without Summarize Result

Use `2-cci-timeout-alert-no-summarize.tf`. Query:

```
fetch logs, from:now()-6m
| filter contains(aws.log_group, "cci-fa-comm-calc")
| filter contains(content, "Task timed out", caseSensitive:false)
| filter not contains(content, "[DEBUG]")
```

| Step | Why |
|---|---|
| Apply from this folder only, not seq 1 | Both use the same resource name. |
| Run `terraform validate` and `terraform plan` from `2.sh` | Checks the file before apply. |
