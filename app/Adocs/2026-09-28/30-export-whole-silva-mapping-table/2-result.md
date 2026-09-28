# Result

| Step | What to do |
|---|---|
| 1 | Run 30.sh line 1 to see how many host-service rows exist. |
| 2 | Run lines 2–4 (add more offset lines if the count is above 20,000). |
| 3 | Run line 5 for offerings, and line 7 for groups if you want them too. |
| 4 | If line 2 gives an empty file, run line 6 and rename `silva_ci_service_rel.csv` to `silva_ci_service.csv`. |
| 5 | Run line 9 to build `silva_whole_table.csv`. |
| 6 | Open it in Excel and filter by host or business service to fill `SYSTEM_MAP` rows. |

Browser alternative: `svc_ci_assoc.list`, then personalize the columns with Configuration item and Service sub-fields, then right-click the header and choose Export → CSV.
