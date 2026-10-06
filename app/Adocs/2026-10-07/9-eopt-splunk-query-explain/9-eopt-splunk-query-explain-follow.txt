# eopt Splunk Query Explain

## Decision Tree

```
Which eopt alert?
 Frontend: index | spath | eval level=upper(level) | search level="ERROR"
   → treat each event as JSON → read "level" → make it capitals → keep ERROR
 Backend:  index | rex "^(timestamp)\s+(level)" | eval level=upper(level) | search level="ERROR"
   → read the word after the timestamp → make it capitals → keep ERROR
 Then the alert: any result in the last hour → email
```

## Short Takeaway

| Question | Answer |
|---|---|
| What the Frontend query does | Finds eopt log events whose JSON `level` field is error (any case) |
| What the Backend query does | Finds eopt log lines whose level word after the timestamp is ERROR |
| Why `eval upper()` | So "error", "Error" and "ERROR" all count as ERROR |
| Why two alerts | Frontend writes JSON logs, Backend writes plain-text logs, so the level is in a different place |
| When it alerts | Hourly; if 1 or more events match, it sends an email |

## Summary

Both searches look in the same Splunk index, `eopt-prod-axa-li-jp`, for error-level logs. They differ only in how they find the level. The Frontend search parses each event as JSON and reads its `level` field. The Backend search uses a regular expression to take the word right after the timestamp. Both then turn the level into capitals and keep only ERROR.

## Frontend Query, Step By Step

```
index="eopt-prod-axa-li-jp"
| spath
| eval level=upper(level)
| search level="ERROR"
```

| Step | What it does | Example |
|---|---|---|
| `index="eopt-prod-axa-li-jp"` | Takes all events from the eopt production index | Frontend and backend pod logs |
| `spath` | Reads each event as JSON and turns its keys into fields | `{"level":"error","msg":"Login failed"}` becomes level=error, msg=Login failed |
| `eval level=upper(level)` | Replaces `level` with the same text in capitals | error becomes ERROR |
| `search level="ERROR"` | Keeps only events where level is ERROR | The Login failed event stays; info and warn events are dropped |

Plain-text backend lines aren't JSON, so `spath` creates no `level` field for them, and the last step drops them.

## Backend Query, Step By Step

```
index="eopt-prod-axa-li-jp"
| rex "^(?<timestamp>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z)\s+(?<level>[A-Z]+)"
| eval level=upper(level)
| search level="ERROR"
```

| Step | What it does | Example |
|---|---|---|
| `index=...` | Same eopt production index | |
| `rex "^(?<timestamp>...)\s+(?<level>[A-Z]+)"` | Regular expression: from the line start, takes the timestamp and the next capital-letter word | `2026-10-06T00:30:06.693Z ERROR 1 --- ...` gives timestamp=2026-10-06T00:30:06.693Z and level=ERROR |
| `eval level=upper(level)` | Makes the level capitals (no effect here, because `[A-Z]+` only captures capitals) | ERROR stays ERROR |
| `search level="ERROR"` | Keeps only ERROR lines | Your 11 PropertyDetailImportServiceImpl lines |

## The Rex Pattern

| Piece | What it means |
|---|---|
| `^` | Start of the line |
| `(?<timestamp> ... )` | Save what matches into a field called timestamp |
| `\d{4}-\d{2}-\d{2}` | Date, such as 2026-10-06 |
| `T` | The letter T between date and time |
| `\d{2}:\d{2}:\d{2}\.\d{3}` | Time with milliseconds, such as 00:30:06.693 |
| `Z` | UTC time zone marker |
| `\s+` | One or more spaces |
| `(?<level>[A-Z]+)` | Save the next capital-letter word into a field called level |

## Alert Settings Around The Query

| Setting | What it means |
|---|---|
| Run every hour, at 0 minutes past | Runs at 01:00, 02:00, 03:00 and so on |
| Trigger: number of results > 0 | Alerts if at least one ERROR event is found |
| Trigger: For each result | Sends one email per matching event (11 events means 11 emails) |
| Expires 24 hours | The triggered-alert record is kept for 24 hours |
| Send email, priority Normal | Email to the eopt maintenance team |

## Data Flow

```
eopt pods → S3 log forwarder → Splunk index eopt-prod-axa-li-jp
  Frontend: spath (JSON) → level → upper → ERROR? → email
  Backend:  rex (text)   → level → upper → ERROR? → email
```

## Investigation

| Checked | Finding |
|---|---|
| Frontend alert screenshot | spath, eval level=upper(level), search level="ERROR" |
| Backend alert screenshot | rex timestamp and level, eval upper, search level="ERROR" |
| Sample events | 11 backend plain-text ERROR lines; no frontend JSON lines shown |

## Result

| Item | Outcome |
|---|---|
| Frontend query | Finds JSON events with level error, any case |
| Backend query | Finds text lines with ERROR right after the timestamp |
| Dynatrace versions | Frontend: 2026-10-07 seq 8. Backend: 2026-10-07 seq 7 |

## Related Files

| File | Purpose |
|---|---|
| `9-eopt-splunk-query-explain.md` | This explanation |
| `9-eopt-splunk-query-explain-follow.txt` | Chat copy |
