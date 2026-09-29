# Investigation

| What was checked | Finding |
|---|---|
| Task order in the YAML | extract-event-tags, then lookup-silva, then display-result. Each waits for the previous task to be OK. |
| Error handling in task 1 | A Problems API failure is caught and recorded. The event data is still used. |
| Error handling in task 2 | Every GET is wrapped. A failure gives status 0 or the HTTP status in `steps`, never an exception. |
| Lookup order in task 2 | Service by name (tag or SERVICE_MAP), then CI to svc_ci_assoc to service, then the group check |
| Writes | None |
| Commands run | None |
