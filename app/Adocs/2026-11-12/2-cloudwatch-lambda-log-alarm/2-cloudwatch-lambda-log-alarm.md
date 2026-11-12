# CloudWatch Lambda Log Alarm

```
The notebook shows a Lambda log line
  the function crashed or timed out
    CloudWatch → All metrics → Lambda → Errors
    alarm when the sum is above 0
  the line says Failed to handle
    CloudWatch → Log groups → that function's group
    metric filter publishes 1 for each matching line
    alarm when the sum of that metric is above 0
  no log line and no Lambda error
    there is nothing for this alarm to count
```

| Choice | Where you click | Alarm fires when |
|---|---|---|
| The function invocation failed | Lambda metric `Errors` | The sum for one minute is above 0. |
| The log text says `Failed to handle` | Metric filter on the log group | The sum of matching lines for one minute is above 0. |

## Summary

Create this alarm in the CloudWatch console. The screenshot shows the text `Failed to handle` in the log group for `light-digital-api-dev-confirm-e-signature`. A metric filter counts those lines. The alarm fires when the count for one minute is above 0. Use the built-in Lambda `Errors` metric when the function itself failed.

## Investigation

| What was on screen | What it tells you |
|---|---|
| Log group | `/aws/lambda/light-digital-api-dev-confirm-e-signature` |
| Other group in the same result | `/aws/lambda/jenkins-to-sharepoint-api-dev-transferFromS3ToSPS` |
| Account on the rows | `031682695384` |
| Error text | `Failed to handle` |
| Dynatrace field | `loglevel` was `ERROR` on those rows. CloudWatch matches the raw line. |

The region is the region of that Lambda. The log group appears only in that region's CloudWatch console. The account must be `031682695384`.

## Result

### Log text alarm

1. Open the CloudWatch console in the Lambda's region.
2. Open **Logs**, then **Log groups**.
3. Open `/aws/lambda/light-digital-api-dev-confirm-e-signature`.
4. Open **Metric filters**.
5. Select **Create metric filter**.
6. Set the filter pattern to `"Failed to handle"`.
7. Select **Test pattern** and pick a log stream from today. A matching line shows a metric value.
8. Select **Next**.
9. Set the filter name to `failed-to-handle`.
10. Set the metric namespace to `LambdaAppLogs`.
11. Set the metric name to `FailedToHandleCount`.
12. Set the metric value to `1`.
13. Set the default value to `0`.
14. Add a dimension named `LogGroup` with the value of the log group name.
15. Select **Next**, then **Create metric filter**.
16. Select the new filter, then **Create alarm**.
17. Set the statistic to **Sum**.
18. Set the period to **1 minute**.
19. Set the condition to **Greater than** `0`.
20. Set missing data to **Treat missing data as not breaching**.
21. Choose an SNS topic. For a first test, create a topic and subscribe your email. Confirm the email before you trust the alarm.
22. Name the alarm `light-digital-api-dev-confirm-e-signature Failed to handle`.
23. Select **Create alarm**.

| Setting | Value |
|---|---|
| Filter pattern | `"Failed to handle"` |
| Metric value | `1` for each matching line |
| Default value | `0` when a line does not match |
| Statistic | Sum |
| Period | 1 minute |
| Threshold | Greater than 0 |
| Missing data | Not breaching |

CloudWatch pattern matching is case-sensitive. The pattern `"Failed to handle"` matches the words visible on the error row. The word `ERROR` is a different pattern from `error`.

A minute with logs and no matching line publishes 0 because the default value is 0. A minute with no logs at all publishes nothing. Missing data set to not breaching keeps that quiet minute out of alarm.

### Function-failure alarm

Use this when the Lambda invocation failed, timed out, or ran out of memory.

1. Open **CloudWatch**, then **All alarms**, then **Create alarm**.
2. Select **Select metric**.
3. Open **Lambda**, then **By Function Name**.
4. Select the metric `Errors` for `light-digital-api-dev-confirm-e-signature`.
5. Set the statistic to **Sum**, the period to **1 minute**, and the threshold to **Greater than** `0`.
6. Set missing data to **Treat missing data as not breaching**.
7. Send the notification to the same SNS topic.
8. Name the alarm `light-digital-api-dev-confirm-e-signature invocation errors`.
9. Select **Create alarm**.

The `Errors` metric does not count a line that says `Failed to handle` when the invocation still succeeds. That line needs the metric filter above.

## Data flow map

```
Lambda writes a log line
        |
        v
log group /aws/lambda/light-digital-api-dev-confirm-e-signature
        |
        v
metric filter pattern "Failed to handle"
  match → metric value 1
  other line → metric value 0
        |
        v
CloudWatch alarm
  Sum over 1 minute greater than 0
        |
        v
SNS topic
  email for the first test
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Which alarm matches which failure. |
| `1-investigation.md` | The log group and the error text. |
| `2-result.md` | The console values. |
| `3-glossary.md` | The words. |
| `2-cloudwatch-lambda-log-alarm-follow.txt` | The same steps for a phone. |
| `2.sh` | Copy commands. |

Commands: [2.sh](2.sh)
