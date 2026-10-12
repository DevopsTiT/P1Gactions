# HPM SharePoint API Lambda Error Result

Use `10-hpm-sharepoint-api-lambda-error-tf.tf`. Query:

```
fetch logs, from:now()-24h
| filter contains(aws.log_group, "/aws/lambda/hpm-sharepoint-api")
| filter contains(content, "ERROR", caseSensitive:false)
```

| Step | Why |
|---|---|
| Run the check queries | Confirm log group, noise and daily volume. |
| Decide: detector or 10:00 workflow | Daily schedule cannot be kept in a detector. |
| Set up email in the workflow | The detector does not send email. |
| Run `terraform validate` and `terraform plan` from `10.sh` | Checks the file before apply. |
