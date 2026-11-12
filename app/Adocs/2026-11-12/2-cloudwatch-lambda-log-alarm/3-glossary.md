# Glossary

| Term | What it means |
|---|---|
| Log group | The CloudWatch folder for one Lambda function's log lines. |
| Metric filter | A rule that turns matching log lines into a number. |
| Metric value | The number published for one matching line. Here it is 1. |
| Default value | The number published for a line that does not match. Here it is 0. |
| Alarm | The rule that compares that number with 0 and sends a notification. |
| SNS topic | The address list that receives the alarm message. |
| Lambda Errors | The built-in count of failed invocations. A successful invocation that logs Failed to handle is not in this count. |
