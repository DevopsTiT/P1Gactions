# HPM SurveyMonkey Lambda Error Result

Use `11-hpm-survey-monkey-lambda-error-tf.tf`. Query:

```
fetch logs, from:now()-60m
| filter contains(aws.log_group, "/aws/lambda/hpm-survey-monkey")
| filter contains(content, "ERROR", caseSensitive:false)
```

| Step | Why |
|---|---|
| Run the check queries | Confirm the log group and look for noise. |
| Set up email in the workflow | The detector does not send email. |
| Run `terraform validate` and `terraform plan` from `11.sh` | Checks the file before apply. |
