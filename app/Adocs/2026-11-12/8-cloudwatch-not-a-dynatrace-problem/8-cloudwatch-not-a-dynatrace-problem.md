# CloudWatch Not A Dynatrace Problem

```
CloudWatch alarm is ALARM in AWS
  Dynatrace Notebook shows the log lines
    logs are records
    a record is not a problem
  the custom alert is still a preview
    Save was still on the screen
    fetch logs has no threshold
    Davis opens nothing
  AWS connection polls CloudWatch metrics
    it does not import the alarm you created in the CloudWatch console
    a Dynatrace problem needs a metric event or a saved timeseries alert
```

| What you already have | What it does not do |
|---|---|
| Log lines in the Notebook | Open a problem. |
| A CloudWatch alarm in AWS | Appear in Dynatrace Problems by itself. |
| A preview that says CW test logs found | Send a notification or open a problem. |

## Summary

CloudWatch and Dynatrace keep separate problem lists. The Notebook proved the Lambda log lines arrived. An alarm you create in the CloudWatch console stays in AWS and notifies its own SNS topic. Dynatrace opens a problem only from a saved metric event or a saved timeseries alert.

## Investigation

| Source | Finding |
|---|---|
| Notebook | 144 lines from `/aws/lambda/light-digital-api-dev-confirm-e-signature`, including Failed to handle. |
| Chat preview | Status Pending. Text: CW test logs found. |
| Edit alert | Save was still visible. Data type had been Records. The query was `fetch logs`. |
| Dynatrace AWS docs | The integration polls CloudWatch metrics. Alerting is a separate page, Metric events for alerting. |
| IAM permissions on that integration | `cloudwatch:GetMetricData`, `GetMetricStatistics`, and `ListMetrics`. DescribeAlarms is not in that list. |

The metric poll does not read the alarm object you created in the CloudWatch console.

## Result

Check these three places. The first one that is missing is the reason Problems is empty.

1. Open **Problems** and set **Last 2 hours**. Clear the filter bar.
2. Open **Settings**, **Cloud and virtualization**, **AWS**, **Metric events for alerting**.

| What you find | What it means |
|---|---|
| No enabled rule for this Lambda | Dynatrace is not turning that CloudWatch metric into a problem. |
| A rule exists and it is disabled | Create the rule, then enable it. |
| A rule is enabled | Wait for the next metric poll, then look in Problems again. |

3. For the log text `Failed to handle`, keep the custom alert and press **Save** with this query.

```
fetch logs
| filter contains(aws.log.group, "/aws/lambda/light-digital-api-dev-confirm-e-signature", caseSensitive:false)
| filter loglevel == "ERROR"
| makeTimeseries error_count = count(), interval:1m
```

| Field | Value |
|---|---|
| Data type | Timeseries |
| Threshold | Above 0 |
| Title | `Lambda log ERROR` |

A CloudWatch alarm can still be ALARM in AWS while this page stays empty. Its notification is the SNS topic on that alarm. That message does not create the Dynatrace problem.

## Data flow map

```
Lambda writes a log line
        |
        +--> CloudWatch Logs
        |      Dynatrace Notebook can read it
        |      a log line is not a problem
        |
        +--> CloudWatch alarm in AWS
        |      SNS email or topic
        |      Dynatrace does not import that alarm object
        |
        +--> CloudWatch metric polled by Dynatrace
               Metric events for alerting enabled?
                 no  → Problems stays empty
                 yes → Davis can open a problem
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Why the CloudWatch alarm stays out of Problems. |
| `1-investigation.md` | What the screens already showed. |
| `2-result.md` | The three checks. |
| `3-glossary.md` | The words. |
| `8-cloudwatch-not-a-dynatrace-problem-follow.txt` | The same answer for a phone. |
| `8.sh` | Copy commands. |

Commands: [8.sh](8.sh)
