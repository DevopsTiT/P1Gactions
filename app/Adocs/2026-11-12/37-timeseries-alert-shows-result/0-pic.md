# Timeseries Alert Shows Result

```
blank chart
  drop isNotNull(dt.entity.custom_device)
  sum the metric for the log group only
  line shows -> attach CUSTOM_DEVICE in the event template
  still blank -> check dev path, field name, metric name
```
