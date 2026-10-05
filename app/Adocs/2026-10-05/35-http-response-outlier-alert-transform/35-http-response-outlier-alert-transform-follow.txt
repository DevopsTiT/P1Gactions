# HTTP Response Outlier Alert Transform

## Decision tree

```
9 screenshots from the jenkins_console alert list
 URL, URL for MyAXA, function          → already done in seq 34 (screenshots confirm the logic)
 HTTP Response Check Outlier (new)
   hand-made median +/- 20 x MAD outlier test on AGGW LB response time
   → Dynatrace auto-adaptive detector (learns baseline and fluctuation itself)
   subject 【TEST】, one person          → it is a test alert; migrate only if the owner wants it
   lower bound (too fast)              → dropped: analyzer is ABOVE or BELOW, fast is not an incident
```

## Short takeaway

| Question | Answer |
|---|---|
| What is new? | Only "HTTP Response Check Outlier". The other three are the seq 34 alerts |
| What does it do? | Flags the latest 10-minute max response time of HTTP Monitor - AGGW LB when it is more than 20 median absolute deviations from the median |
| Dynatrace replacement | One auto-adaptive anomaly detector on the same response time |
| Is it production? | Probably not: subject starts with 【TEST】 and it emails one person |
| What needs tuning | `numberOfSignalFluctuations` (start at 5) using the detector preview |

## Summary

The new alert is a statistics exercise in SPL: it builds a median and median absolute deviation over the last 200 ten-minute points and flags the newest point if it is far outside. Dynatrace's auto-adaptive analyzer does the same job natively, so one detector replaces about fifteen lines of streamstats. It is marked as a test in Splunk, so confirm with the owner before turning it on.

## The Splunk logic in plain words

| Step | Splunk | Meaning |
|---|---|---|
| 1 | `job_name="HTTP Monitor - AGGW LB"` | Only the AGGW load balancer check |
| 2 | `replace(duration,"s","")` | Turn "0.532s" into 0.532 |
| 3 | `timechart span=10m max(duration)` | Worst response time per 10 minutes |
| 4 | `streamstats window=200 median(...)` | Median of the last 200 points (about 33 hours) |
| 5 | `median(abs(responsetime - median))` | Median absolute deviation (MAD): typical distance from normal |
| 6 | `median +/- MAD * exact(20)` | Very wide band, 20 MAD each side |
| 7 | `head 1 \| search isOutlier=1` | Alert only if the newest point is outside the band |

## Dynatrace detector

| Setting | Value | Why |
|---|---|---|
| Analyzer | AutoAdaptiveAnomalyDetectionAnalyzer | Learns baseline and normal fluctuation, like median and MAD |
| Query | Max response time per minute for AGGW LB | Same signal |
| `numberOfSignalFluctuations` | 5 | How far above baseline counts as abnormal. Splunk's 20 MAD is very wide; tune with preview |
| Alert condition | ABOVE | Only slowdowns; the analyzer does not support "outside both ways" |
| Violating samples | 5 of 10 | Similar to one bad 10-minute bucket |
| Dealerting | 10 | Closes after 10 normal minutes |
| Severity | medium | Was a test email, not a page |

```
fetch logs
| filter matchesValue(log.source, "*jenkins*console*")                    // CONFIRM
| filter contains(content, "[HTTP Monitor]")
| filter contains(log.source, "HTTP%20Monitor%20-%20AGGW%20LB") or contains(content, "HTTP Monitor - AGGW LB")
| parse content, "LD 'duration' LD DOUBLE:responsetime 's'"               // CONFIRM format
| makeTimeseries responsetime = max(responsetime), interval:1m
```

Full file: `35-http-response-outlier-alert-transform.tf`.

## Issues found in the Splunk alert

| Issue | What it means |
|---|---|
| Subject 【TEST】 and one recipient | A test that was never promoted, or forgotten |
| Last 24 hours every 10 minutes | Re-reads a day of Jenkins logs 144 times a day |
| `head 1000` before streamstats | Caps the history silently |
| Alerts on "too fast" as well | A faster response is not an incident |
| 20 x MAD | So wide it may almost never fire; check query 3 |

## What the screenshots confirmed for seq 34

| Alert | Confirmed |
|---|---|
| URL | name = source with `job/` and `/<number>/console` removed, `%20` turned into space. `status` renamed to responsecode. PagerDuty disabled, debug recipient application services list |
| URL for MyAXA | Same base search; NG only if no OK in last 2 results; `event=2`; PagerDuty enabled |
| function | Old `json:jenkins:old` source, `pager_duty="0"` apps, last 120 minutes, PagerDuty disabled |

No change to the seq 34 Terraform is needed.

## Data flow

```
Jenkins "HTTP Monitor - AGGW LB" job → console log (duration) → Grail
   → auto-adaptive detector (every minute, learns baseline)
   → far above baseline 5 of 10 minutes → problem (medium)
   → standard flow (decide whether a test alert should page at all)
```

## Investigation

| Screenshots | Alert | Finding |
|---|---|---|
| 1 and 2 | Application Monitoring Alert - URL | Same as seq 34 |
| 3 and 4 | Application Monitoring Alert - URL for MyAXA | Same as seq 34; PagerDuty key not copied |
| 5 to 7 | Application Monitoring Alert - function | Same as seq 34 |
| 8 and 9 | HTTP Response Check Outlier | New; median and MAD outlier on AGGW LB; Last 24 hours, every 10 minutes; email masayuki.yasuda, subject 【TEST】 |

## Result

| Step | Action |
|---|---|
| 1 | Ask the owner whether this test alert should move to Dynatrace at all |
| 2 | Run `check.dql` queries 1 and 2 to fix the source and the duration parse |
| 3 | Run queries 3 and 4 to see the normal range |
| 4 | Open the detector in the Anomaly Detection app, use the preview, and tune `numberOfSignalFluctuations` |
| 5 | `terraform plan` should show 1 detector |

## Related files

| File | Purpose |
|---|---|
| `35-http-response-outlier-alert-transform.tf` | Auto-adaptive detector |
| `35-http-response-outlier-alert-transform-check.dql` | Source, format and range checks |
| `35.sh` | Commands |

## Commands

See `35.sh`. Not run.

```
terraform init
terraform validate
terraform plan
```
