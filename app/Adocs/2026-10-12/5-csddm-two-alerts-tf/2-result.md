# CSDDM Two Alerts Result

Use `5-csddm-two-alerts-tf.tf`.

Alert 1 query:

```
fetch logs, from:now()-24h
| filter contains(aws.log_group, "cs-digital-document-management")
| filter contains(content, "error", caseSensitive:false)
| filter not contains(content, "elivery not possible", caseSensitive:false)
| filter not contains(content, "errorEmailNotification", caseSensitive:false)
```

Alert 2 query:

```
fetch logs, from:now()-5m
| filter contains(aws.log_group, "/aws/lambda/cs-digital-document-management-prod")
| filter contains(content, "error")
| filter not contains(content, "elivery not possible")
```

| Step | Why |
|---|---|
| Run the three check queries | Confirm log groups, case misses and recent matches. |
| Decide on alert 1's daily schedule | Keep the detector, or use a 10:00 scheduled workflow. |
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `5.sh` | Checks the file before apply. |
