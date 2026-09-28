# Result

| Step | What to do |
|---|---|
| 1 | Run 32.sh lines 2 and 3 to confirm the real field names (especially the environment field). |
| 2 | Run lines 18–21 to see counts per environment and per service. They are quick and show whether you have access. |
| 3 | Use lines 5–14 for single lookups, and lines 22–24 for full exports. |
| 4 | Use lines 15–16 if `svc_ci_assoc` is empty. The CMDB Instance API shows every relationship of a host. |
| 5 | Lines 29–30 create and resolve a real test incident. Only run them on purpose, and resolve the test ticket afterwards. |
| 6 | Any 403 response: ask the SILVA admin for read access for `Tech_DynatraceJP_WS`. |
