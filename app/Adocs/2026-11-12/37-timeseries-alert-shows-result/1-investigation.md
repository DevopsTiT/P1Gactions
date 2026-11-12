# Investigation

The query sums log.lambda_errors for /aws/lambda/gov-inquiry-system-dev-logFailure. It groups by aws.log_group and dt.entity.custom_device, then keeps only rows where the custom device is not null.

That custom device field is empty on this Lambda log metric. The last filter removes every point. The chart has no series, so the alert condition cannot open a problem.

The path contains dev. The earlier gov-inquiry alerts used prod log groups. The screen uses aws.log_group. The earlier log queries used aws.log.group.
