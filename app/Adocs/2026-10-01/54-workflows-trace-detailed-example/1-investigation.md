# Investigation

| Checked | Finding |
|---|---|
| Known real values | P-261090, ts12.hk.intraxa, INC30341416, offering cfbf255f, business service 37273dbc, AXA XL, caller 8ddef691. |
| Made-up values | Internal ids, team names, times, choice numbers, tag values. Marked `<...>` or "example". |
| Code detail found | In OPEN task 2 the assignment group is picked (line 616) before the history step replaces the business service (line 676). So the team can come from the technical service while company comes from the final business service. |
