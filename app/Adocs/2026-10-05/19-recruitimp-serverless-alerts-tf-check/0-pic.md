# RecruitImp Serverless Alerts Check Pic

```
recruitimp-serverless.tf (2 × dynatrace_log_alert → plan fails)
  log group recrutimp vs recruitimp → one is wrong → check.dql 1
  alert 1 daily 08:00, LD LD WORD   → scheduled workflow, robust ERROR filter
  alert 2 WORD WORD WORD (no SPACE) → never matches → NSPACE SPACE WORD SPACE NSPACE
  alert 2 every 5 min               → detector + email
  $name$, "Optional"                → real subject, descriptions
```
