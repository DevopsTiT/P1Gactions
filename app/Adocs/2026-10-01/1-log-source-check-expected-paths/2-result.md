# Result

| Step | What to do |
|---|---|
| 1 | Run Q2 with timeframe 24 h. Expect all 23 rows MISSING for this Windows host group. |
| 2 | Run Q3 with timeframe 30 min to 2 h. Note the host group IDs that send the pic2 paths. |
| 3 | Re-run Q2 with the host group ID from step 2. MISSING rows there are real gaps. |
| 4 | For real gaps: confirm the file exists on the host, then check the log ingest rule and OneAgent log module settings. |
| 5 | If line 461 and above hold more paths, add them to the arrays in Q1, Q2 and Q3. |
