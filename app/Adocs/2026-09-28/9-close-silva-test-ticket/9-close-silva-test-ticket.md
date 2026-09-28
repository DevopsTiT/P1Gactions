# Close SILVA Test Ticket

```
Want to close the "test" ticket (testing 3122, P-260915195)
 Not saved yet? (no INC number, never clicked Submit)
   → just leave the form / click Back — nothing to close
 Saved, has an INC number?
   → UI: Incident State = Resolved → fill Resolution code + Resolution notes → Update
   → Resolved grays out / blocked?
       → set In Progress first, save, then Resolved
       → still blocked → assignment group member or SILVA admin must do it
   → API (same as CLOSE workflow): find sys_id → PATCH state 6
 Want the Dynatrace CLOSE workflow to close it?
   → only works if correlation_id on the INC == the problem ID
   → manual tickets have no correlation_id → close by hand or by API
 Expect "Closed", not "Resolved"?
   → SNOW moves Resolved → Closed on its own after the auto-close timer
```

## Short takeaway

| Question | Answer |
|---|---|
| Fastest way to close it | In the form, set Incident State to Resolved, fill in the resolution fields, then click Update. |
| Why not "Closed" directly? | In most ServiceNow setups, only the system moves Resolved to Closed, after a waiting period. |
| Will the Dynatrace CLOSE workflow close it? | No. That workflow finds tickets by correlation_id, and a hand-made ticket has none. |
| Can I close it by API? | Yes. Find the sys_id, then send a PATCH with state 6. The commands are in `9.sh`. |

## Summary

This looks like a hand-made test incident (Contact type Phone, short description "test"). Close it the normal ServiceNow way: move it to Resolved with a resolution code and notes. The system then closes it later.

## Option 1: Close in the form (recommended)

| Step | What to do | Why |
|---|---|---|
| 1 | Check the ticket has an INC number at the top of the form. | If there is no number, it was never saved. Just leave the page. |
| 2 | Set **Incident State** to **Resolved**. | Resolved is the "work is done" state. |
| 3 | Open the **Resolution Information** tab (lower in the form). | The Resolved state needs resolution fields. |
| 4 | Set **Resolution code** to "Solved (Permanently)" or the closest option. | This is the same value the CLOSE workflow sends. |
| 5 | Write **Resolution notes**, for example "Test ticket for Dynatrace integration. No action needed." | Resolution notes are usually mandatory. |
| 6 | Click **Update** (or **Resolve** if that button is shown). | This saves the new state. |

## If the form blocks you

| What you see | Likely cause | What to do |
|---|---|---|
| Resolved is not in the list | The state flow needs In Progress first. | Set In Progress, save, then set Resolved. |
| Red "mandatory" message | A resolution field or Assigned to is empty. | Fill it in. Some setups need Assigned to before Resolved. |
| Fields are read-only | You are not in the assignment group. | Ask a member of testing 3122 or a SILVA admin. |

## Option 2: Close by API

The CLOSE workflow does the same thing: it finds the incident and PATCHes it to state 6 (Resolved).

| Step | Command in `9.sh` | What it does |
|---|---|---|
| 1 | Find recent tickets in testing 3122 | Shows number, sys_id, state and short description, so you pick the right one. |
| 2 | PATCH by sys_id | Sets state 6, resolution code, close notes and a customer comment. |
| 3 | GET by sys_id | Confirms state is now Resolved. |

Replace `__SNOW_PASSWORD__` and `__SYS_ID__` before running.

## Data flow map

```
You (form) ──► Incident State = Resolved + resolution code + notes ──► Update
                                                                        │
API (curl) ──► GET incident?query=... → sys_id ──► PATCH state=6 ───────┤
                                                                        ▼
                                                     SILVA INC = Resolved
                                                                        │
                                                   auto-close timer (days)
                                                                        ▼
                                                     SILVA INC = Closed
```

## Related files

| File | Purpose |
|---|---|
| `9.sh` | API one-liners to find, resolve and verify the ticket |
| `../8-open-close-with-credentials/2-close-silva-http-and-pagerduty.workflow.yaml` | CLOSE workflow that sends the same PATCH |

Commands: see `9.sh` in this folder.
