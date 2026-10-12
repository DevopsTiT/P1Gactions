# HPM CMX To SharePoint Lambda Error Result

Use `3-hpm-cmx-sharepoint-lambda-error-tf.tf`. Query:

```
fetch logs, from:now()-60m
| filter contains(aws.log_group, "/aws/lambda/cmx-sharepoint-api")
| filter contains(content, "Error", caseSensitive:false)
```

| Step | Why |
|---|---|
| Run the check queries | Confirm the log group and look for noisy matches. |
| Set up email in the workflow | The detector does not send email. |
| Run `terraform validate` and `terraform plan` from `3.sh` | Checks the file before apply. |
