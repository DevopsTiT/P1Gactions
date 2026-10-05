# HTTP Response Outlier Glossary

| Term | What it means | Why you care |
|---|---|---|
| Outlier | A value far away from the usual values | What the Splunk alert hunts for |
| Median | Middle value when sorted | Robust "normal" level, not pulled by spikes |
| MAD (median absolute deviation) | Median distance of points from the median | Robust measure of normal wobble |
| Auto-adaptive threshold | Dynatrace model that learns a baseline and its fluctuation | Replaces the hand-written median and MAD |
| `numberOfSignalFluctuations` | How many fluctuations above baseline count as abnormal | Higher means fewer alerts |
| AGGW LB | The API gateway load balancer checked by the Jenkins HTTP Monitor | The thing being watched |
