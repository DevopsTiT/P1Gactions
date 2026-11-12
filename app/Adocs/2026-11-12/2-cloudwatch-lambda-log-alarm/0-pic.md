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
