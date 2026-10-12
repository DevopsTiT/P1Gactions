# InnoRules BRE Alert Result

Use `12-innorules-bre-alert-tf.tf`. Query:

```
fetch logs, from:now()-5m
| filter contains(aws.log_group, "innorules")
| filter contains(content, "ERROR", caseSensitive:false)
| filter getHour(timestamp) >= 1 and getHour(timestamp) <= 5
```

| Step | Why |
|---|---|
| Confirm the old cron timezone | UTC keeps the query; JST needs the Asia/Tokyo filter. |
| Run the check queries | Confirm log groups, noise and hourly pattern. |
| Rotate the PagerDuty key if committed | It was in plain text. |
| Run `terraform validate` and `terraform plan` from `12.sh` | Checks the file before apply. |
