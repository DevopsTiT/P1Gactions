# Result

| Step | What to do | Expected |
|---|---|---|
| 1 | Run QA | All `icontains_pic2` false for this Windows host group |
| 2 | Run QB | All 23 pic2 paths MISSING |
| 3 | Run QC | Loose match on HULFT trace, maybe `default.log` or `server.log` if present |
| 4 | Change the host group ID to the Linux group (from the earlier Q3) and rerun QA and QB | Real FOUND and MISSING list |
| 5 | If the notebook rejects `iAny` or `iCollectArray` | Ask for the fallback version without iterative functions |
