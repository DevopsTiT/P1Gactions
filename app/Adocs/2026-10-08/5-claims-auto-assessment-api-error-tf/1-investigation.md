# Investigation

| What was checked | Finding |
|---|---|
| Alert name | Auto-Assessment API Error - !PRODUCTION! |
| Search | `index=claimsda*`, host `claims-auto-assessment-api*`, `"*] ERROR *"`, not the stacktrace notice |
| Schedule | `*/10 * * * *`, Last 10 minutes |
| Trigger | Number of Results > 0, Once, no throttle |
| Action | Email to claims incident lists, priority High |
| Search result | 2 events; host looks like a Kubernetes pod name |
