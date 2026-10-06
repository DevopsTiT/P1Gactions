# Investigation

| Checked | Finding |
|---|---|
| User request | Remove makeTimeseries and the %ASA-2-113022 filter |
| Detector | Needs a time series, so it can't drop makeTimeseries |
| Log event resource | `dynatrace_log_events`: matcher plus event template, one event per matching line |
| Splunk search | Text match only, with no message code |
