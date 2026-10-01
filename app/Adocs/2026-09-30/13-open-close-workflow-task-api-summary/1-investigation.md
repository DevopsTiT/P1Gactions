# Investigation

| What was checked | Evidence |
|---|---|
| Every API call in OPEN | `getProblem` line 173; `getRows` lines 377–615; `fetch` lines 357, 913, 931, 1003 |
| Every API call in CLOSE | `getProblem` line 122; `getJson` lines 241 and 246; PATCH line 272; PagerDuty line 333 |
| SILVA search queries | Searches 1–5 on lines 508–516; first-answer queries on lines 544–547 |
| Offering queries | Lines 561–566, 603–604, 614–616 |
| Host and record queries | Lines 401–410; link tables on lines 420 and 423 |
| CLOSE lookup queries | Lines 238–245 use `ORDERBYDESCsys_created_on` and `sysparm_limit=1` |

## Notes

| Observation | What it means |
|---|---|
| Task 2 never writes to SILVA | Safe to run many times |
| Task 2 `getRows` never throws | A SILVA outage shows up as empty answers and defaults, not a red task. Check `steps`. |
| CLOSE `getJson` does throw | A SILVA outage on close shows as a failed task, so you notice it |
| CLOSE tasks 2 and 3 run in parallel | PagerDuty still resolves even if SILVA fails |
| `app/Adocs` folder does not exist | Not recreated; mirror written only to Work/AIProjects/Files |
