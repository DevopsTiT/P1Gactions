# Why The CloudWatch Alert Does Not Open A Problem

```
CloudWatch alarm changes to ALARM
  action list is email or empty
    Dynatrace is not called
  EventBridge hears the change
    no rule targeting Dynatrace
      the event stays in AWS
  metric poll reads numbers
    it does not read alarm state
    Problems stays empty
```
