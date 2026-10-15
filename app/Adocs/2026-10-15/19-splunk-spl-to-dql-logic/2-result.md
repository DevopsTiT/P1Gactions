# Splunk To DQL Result

| Step | Do |
|---|---|
| 1 | Label each Splunk part: time, where, text, extract, shape, join. |
| 2 | Write `fetch logs, from:` for the time. |
| 3 | Find the real source field with a check query, then filter on it. |
| 4 | Translate text terms with the case rules. |
| 5 | Add `parse` for every auto-extracted, `rex` or `spath` field. |
| 6 | Translate `stats`, `table`, `sort` and similar. |
| 7 | Turn subsearches into `lookup` with the key parsed on both sides. |
| 8 | Test with `data record(...)`, then compare counts with Splunk. |
