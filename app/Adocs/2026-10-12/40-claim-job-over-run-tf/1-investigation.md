# Claim Job Over Run Investigation

| What was checked | Finding |
|---|---|
| Alert | Claim Job Over Run Alert |
| Description | Empty ("Optional") |
| Search | `index="controlm*"` plus `inputlookup claims_jobs`, elapsed since start_time, no end_time, elapsed >= 15 |
| Schedule | Cron every 5 minutes, last 24 hours |
| Trigger | More than 0 results, once |
| Throttle | Off |
| Action | Email to claims incident group. Recipients not copied. |
| Log seen | controlm_agent_log, /opt/ctmhlx/ctm/dailylog/daily_ctmag_20261012.log |
| Hosts seen | CEAA2090, CEAA204F, CEAA20CB, CEAA204E (8 hosts in total) |
| Start line | `JOB <name> (ORDERID n, RUNNO r) STARTED (pid), OWNER ...` |
| End lines | `EXECUTION ENDED`, `ENDED OK elapsed - x Sec` |
| Unknown | The claims_jobs lookup contents |
