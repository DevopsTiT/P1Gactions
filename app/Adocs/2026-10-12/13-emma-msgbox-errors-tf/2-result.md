# Emma MsgBox Errors Result

Use `13-emma-msgbox-errors-tf.tf`. Query:

```
fetch logs, from:now()-5m
| filter contains(aws.log_group, "message-box-api")
| filter contains(status, "error", caseSensitive:false)
    or contains(status, "warn", caseSensitive:false)
| filter not contains(content, "DeprecationWarning", caseSensitive:false)
| summarize matches = count(), log_groups = collectDistinct(aws.log_group), sample = takeFirst(content)
| filter matches > 5
| fieldsAdd scope = "message-box-api"
```

| Step | Why |
|---|---|
| Run the check queries | Confirm log groups, status values and how often it would fire. |
| Set up email in the workflow | The detector does not send email. |
| Run `terraform validate` and `terraform plan` from `13.sh` | Checks the file before apply. |
