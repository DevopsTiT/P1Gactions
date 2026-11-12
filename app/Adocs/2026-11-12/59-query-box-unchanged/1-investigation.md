# Investigation

The Edit alert screenshot still shows the CloudWatch query.

```
timeseries errors = sum(log.lambda_errors),
  filter: {aws.log_group == "/aws/lambda/gov-inquiry-system-dev-logFailure"},
  by: {aws.log_group}
| fieldsAdd dt.entity.host = "HOST-00026D8D201D203A"
```

Data type is Timeseries. Actor is shuge kui. Source is Alert management. Define alert condition is marked completed.

That query returned 0 records on Last 2 hours. The host CPU query returned 1 record and the line stayed under 20.
