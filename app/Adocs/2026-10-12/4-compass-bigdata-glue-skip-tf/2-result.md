# Compass BigData Glue Skip Result

Use `4-compass-bigdata-glue-skip-tf.tf`. Query:

```
fetch logs, from:now()-5m
| filter contains(aws.log_group, "/aws-glue/jobs/custom/compass-sales-performance/error")
| filter contains(content, "skipping table", caseSensitive:false)
```

| Step | Why |
|---|---|
| Run the check queries | Confirm the log group and see past matches. |
| Set up email in the workflow | The detector does not send email. |
| Run `terraform validate` and `terraform plan` from `4.sh` | Checks the file before apply. |
