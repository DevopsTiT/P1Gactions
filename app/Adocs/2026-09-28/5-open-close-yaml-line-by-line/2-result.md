# Result

| Outcome | Detail |
|---|---|
| Both files explained line by line | See the main md, Part A (OPEN) and Part B (CLOSE), with real line numbers. |
| The YAML frame | Trigger, task boxes, order and run conditions. |
| The JavaScript | Inside `script: \|`. It does the API calls and returns data for later tasks. |
| The most important lines | OPEN 286–287 and CLOSE 129–130 (the sync keys). Keep them identical. |
| Safest things to edit | The maps in OPEN 77–130, `RESOLVE_MODE` in CLOSE line 164, and `NOTES_FIELD`. |

## What to do next

| Step | Why |
|---|---|
| Confirm the SILVA column names in `FIELD` | Wrong names are silently ignored. |
| Replace the placeholders | Otherwise the calls fail with 401. |
| Test OPEN on a staging Problem, then close it | Proves the sync keys work end to end. |
