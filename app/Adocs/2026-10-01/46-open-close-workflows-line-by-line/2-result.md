# Result

| If you want to... | Change this |
|---|---|
| Test OPEN without sending | `DRY_RUN = true` in OPEN lines 1101 and 1201. |
| Test CLOSE without sending | `DRY_RUN = true` in CLOSE lines 187 and 385. |
| Force a business service | `SERVICE_MAP` in OPEN line 333. |
| Force an assignment group | `GROUP_MAP` in OPEN line 336. |
| Close a test problem by hand | CLOSE line 81 `display_id`, plus `ALLOW_SAMPLE_POST = true` in lines 188 and 386. |
| Make notes visible to the caller | CLOSE line 184 `NOTES_FIELD = "comments"`. |
