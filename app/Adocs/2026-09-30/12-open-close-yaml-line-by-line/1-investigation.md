# Investigation

| File read | Lines | Task line ranges |
|---|---|---|
| OPEN v6 | 1021 | 72 task 1, 298 task 2, 687 task 3, 865 task 4, 958 task 5 |
| CLOSE v6 | 343 | 57 task 1, 189 task 2, 293 task 3 |

| Observation | Note |
|---|---|
| Secrets | OPEN lines 318, 885, 976; CLOSE lines 209, 311 |
| OPEN task 2 reads `a` (alert) but does not use it | Harmless |
| OPEN task 4 duplicate check does not fail on a SILVA GET error | It then tries the POST, which will show the real error |
| The `app/Adocs` folder no longer exists | Not recreated; this answer is in Daily Files and Work/AIProjects/Files |
