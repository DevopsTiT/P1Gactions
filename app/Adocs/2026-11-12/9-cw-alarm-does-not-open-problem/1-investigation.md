# Investigation

A CloudWatch alarm state change notifies its actions and EventBridge. Dynatrace stores an EventBridge event only when a rule targets a Dynatrace API destination. The AWS metric poll uses GetMetricData, GetMetricStatistics, and ListMetrics. It does not read alarm state.
