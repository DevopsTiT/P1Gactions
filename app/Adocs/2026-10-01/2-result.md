# Result

| Step | Action |
|---|---|
| 1 | Preview is OK for both SILVA and PagerDuty. |
| 2 | Open post-silva-incident result: expect `action: created` with an INC number. |
| 3 | Open trigger-pagerduty result: expect `triggered: true`. |
| 4 | If either says skipped because of dry run, set DRY_RUN false and rerun. |
| 5 | Run `35.sh` line 1 to confirm the incident in SILVA stg. |
| 6 | Run `35.sh` line 3 to confirm AXA XL is the usual company on ts12 tickets. |
