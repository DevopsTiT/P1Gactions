# Investigation

| Checked | Finding |
|---|---|
| User request | Detector query without makeTimeseries |
| Timeseries analyzers | Need makeTimeseries or timeseries |
| Records analyzer | Accepts any DQL; each row is a violation |
| Default lookback | 2 hours when the query has no from: |
| Deduplication | alertIdentityFields[0] = host.name |
