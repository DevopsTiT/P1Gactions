# Result

Paste these in a Notebook. Set the time picker to Last 2 hours.

1. Newest logs: `fetch logs | sort timestamp desc | limit 20`
2. One file: filter `log.source` with `contains(..., caseSensitive:false)`.
3. A phrase: filter `content` the same way.
4. Lines per host: `summarize lines = count(), by: { host.name }`.
5. Host group id: `instance_of[dt.entity.host_group]` for the hostname.
6. Group members: filter `dt.entity.host_group` by the `HOST_GROUP-` id.
7. Distinct names: `countDistinct` on the pod name or the host name.
8. Open problems: `fetch dt.davis.problems` where status is `ACTIVE`.
9. Host CPU: `timeseries avg(dt.host.cpu.usage)`.
10. Slow spans: `fetch spans` where `duration` is over one second.
