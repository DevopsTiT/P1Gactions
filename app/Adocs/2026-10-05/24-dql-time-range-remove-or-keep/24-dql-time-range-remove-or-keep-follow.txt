# DQL Time Range Remove Or Keep

## Decision tree

```
Where is this query running?
 Notebook (testing by hand)           → REMOVE from:...  → the timeframe picker controls it (from: in the query overrides the picker)
 Detector query (anomaly detector)    → NO from: at all  → the detector sets the window itself (already the case)
 Workflow email task (recent_failures) → KEEP a time range → without it the query uses the default (about the last 2 hours)
   want lines only from this incident? → from:now()-10m (simple)  or  from problem start (precise)
```

## Short takeaway

| Where | Time range in the query? | Why |
|---|---|---|
| Notebook | Remove it | Use the timeframe picker instead; `from:` in the query would override the picker |
| Detector query | Never | The detector decides the window on every run |
| Email workflow task | Keep it | Without it you get the default window, which can include old failures from an earlier incident |

## Summary

Removing `from:now()-10m` is fine when you test in a Notebook, because the picker at the top sets the time. But in the email workflow task, keep a time range. Without one, the query falls back to the default window (typically the last 2 hours), so the email can list failures from an earlier outage that already recovered, and the 50-line limit may be filled with old lines instead of the current ones.

## What changes if you remove it in the workflow

| Situation | With `from:now()-10m` | Without a time range |
|---|---|---|
| One outage right now | Lines from this outage | Same lines, plus anything older in the default window |
| Outage at 08:30, recovered, new outage at 10:00 | Only the 10:00 lines | Both outages mixed in one email |
| More than 50 matching lines | Newest 50 from the last 10 minutes | Newest 50 from up to 2 hours |
| Query cost | Small scan | Larger scan every time the workflow runs |

## Options for the email task

Simple, what main.tf uses:

```dql
fetch logs, from:now()-10m
| filter matchesValue(dt.system.bucket, "network*")
| filter contains(content, "Windows_LDAP as FAILED", caseSensitive: false)
| dedup timestamp, content
| fields timestamp, log.source, content
| sort timestamp desc
| limit 50
```

Precise, starting 5 minutes before the problem opened (test in a workflow run first, because the expression must render a valid timestamp):

```dql
fetch logs, from:toTimestamp("{{ event()['event.start'] }}") - 5m
| filter matchesValue(dt.system.bucket, "network*")
| filter contains(content, "Windows_LDAP as FAILED", caseSensitive: false)
| dedup timestamp, content
| fields timestamp, log.source, content
| sort timestamp desc
| limit 50
```

| Option | Good | Watch out |
|---|---|---|
| `from:now()-10m` | Simple, always works | If the workflow runs late, the earliest lines may be cut off |
| From problem start | Exactly this incident's lines | Depends on the `event.start` field rendering correctly; fall back to the simple version if it doesn't |

## Testing in a Notebook

Paste your version (no `from:`) and set the picker to "Last 30 days" or "Last 24 hours". That's the right way to explore. Just put a time range back before the query goes into the workflow.

## Data flow

```
Notebook: picker sets time → query without from: → explore freely
Detector: detector sets window → query without from: → count per minute
Workflow: problem opens → query with from:now()-10m (or problem start) → only this incident's lines → email
```

## Investigation

| Checked | Finding |
|---|---|
| Your query | Same as the seq 21 email query, with `from:now()-10m` removed |
| Detector query in seq 21 | Has no `from:` (correct) |
| Email task in seq 21 | Uses `from:now()-10m` |
| Default timeframe | When a query has no `from:`, Dynatrace uses its default window (typically the last 2 hours) |

## Result

Remove the time range only in a Notebook. Keep it in the email workflow task, either `from:now()-10m` or from the problem start time.

## Related files

| File | Purpose |
|---|---|
| `2026-10-05/21-cisco-vpn-ldap-two-alerts-transform/21-cisco-vpn-ldap-two-alerts-transform-main.tf` | Email task with `from:now()-10m` |
| `2026-10-05/22-terraform-variables-inside-resource/22-terraform-variables-inside-resource-inline.tf` | Inline version, same email query |
| `24.sh` | Mirror and git one-liners |

## Commands

See `24.sh` (not run).
