# Why The CloudWatch Alert Does Not Open A Problem

```
CloudWatch alarm changes to ALARM
  its action list
    SNS email only
      the mail can arrive
      Dynatrace is not a target
      Problems stays empty
    no action
      AWS records the state
      nobody is called
  EventBridge receives the state change
    no rule with Dynatrace as the target
      the event stays in AWS
  Dynatrace metric poll
    reads metric numbers
    does not read the alarm's ALARM state
    a metric event is a second rule
    that rule is what can open a problem
```

| Step that happens | Step that does not happen |
|---|---|
| The alarm state becomes ALARM. | Dynatrace is not called. |
| EventBridge stores a state-change event. | No rule forwards that event to Dynatrace. |
| Dynatrace polls CloudWatch metric numbers. | The poll does not read alarm state. |

## Summary

The CloudWatch alert triggers its own actions. An email or an SNS topic is an action. A Dynatrace problem is not. EventBridge hears the state change inside AWS, and nothing in the path you tested forwards that event to Dynatrace. Davis never receives an event, so Problems stays empty.

## Investigation

| Source | What it shows |
|---|---|
| CloudWatch alarm behavior | A state change can notify the alarm actions and is also sent to EventBridge. |
| Dynatrace EventBridge docs | A rule and an API destination are required before Dynatrace stores the event. |
| Dynatrace AWS metric docs | The integration polls metrics with GetMetricData, GetMetricStatistics, and ListMetrics. |
| Same permission list | DescribeAlarms is not in that list, so the poll does not read the alarm object. |
| Your preview | CW test logs found. That is a log query. It is not an alarm-state event. |

## Result

Open the alarm in the CloudWatch console and read **Actions**.

| What the action list contains | Why Problems is empty |
|---|---|
| An email SNS topic | The message goes to the inbox. Dynatrace is not on the list. |
| No action | AWS only stores the new state. |
| An SNS topic with no Dynatrace subscription | The topic has nowhere to send a Dynatrace event. |

Then open **EventBridge**, **Rules**, on the default bus in that region. A rule that can open this path has source `aws.cloudwatch` and detail type CloudWatch Alarm State Change, and its target is a Dynatrace API destination.

| What you find | Meaning |
|---|---|
| No such rule | The state change never leaves AWS. |
| A rule exists and the target failed | Dynatrace did not accept the event. Read the EventBridge delivery error. |
| The event is in Dynatrace as a log or an event | Davis still needs a saved alert on that event before Problems gets a row. |

The metric poll cannot replace that rule. It reads numbers such as Lambda `Errors`. It does not read "this alarm is now ALARM." A custom metric from a log filter, such as `LambdaAppLogs` / `FailedToHandleCount`, is also outside the default metric list unless that metric was added to the AWS connection.

## Data flow map

```
Alarm state becomes ALARM
        |
        +--> alarm actions (SNS)
        |      email
        |      Dynatrace is not in this list
        |
        +--> EventBridge
        |      rule with Dynatrace target?
        |        no → event stays in AWS
        |
        +--> Dynatrace metric poll
               reads numbers
               does not read alarm state
               Problems stays empty
```

## Related files

| File | Purpose |
|---|---|
| `0-pic.md` | Where the alarm trigger stops. |
| `1-investigation.md` | Which product step is missing. |
| `2-result.md` | What to read on the alarm. |
| `3-glossary.md` | The words. |
| `9-cw-alarm-does-not-open-problem-follow.txt` | The same answer for a phone. |
| `9.sh` | Copy commands. |

Commands: [9.sh](9.sh)
