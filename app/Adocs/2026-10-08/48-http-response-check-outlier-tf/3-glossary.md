# Outlier Glossary

| Term | What it means | Why you care |
|---|---|---|
| Median | The middle value | Not pulled around by a few spikes |
| MAD | Median absolute deviation, the typical distance from the median | Measures normal spread robustly |
| median ± 20 × MAD | Very wide bounds | Only extreme response times count as outliers |
| timechart | Splunk time buckets, oldest first | So `head 1` picks the oldest bucket |
| Synthetic monitor | Dynatrace calls a URL on a schedule | A cleaner way to watch response time |
