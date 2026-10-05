# Investigation

| What was checked | Finding |
|---|---|
| Alert 1 resource | `dynatrace_log_alert` "csddm_claims_api_fails" |
| Alert 1 logic | "claims api call failed", daily at 10:00, last 24 hours, more than 0, 4 email recipients |
| Alert 2 resource | `dynatrace_log_alert` "cs_digital_document_management_error" |
| Alert 2 logic | "error" minus "elivery not possible", every 5 minutes, last 5 minutes, throttle 1 hour, 1 recipient |
| Provider docs | `dynatrace_automation_workflow` supports schedule (cron, time zone), davis_problem trigger, task conditions |
| Secrets | None in this file |
