# Glossary

| Term | What it means |
| --- | --- |
| PagerDuty | On-call alerting platform |
| Service | PD object that receives alerts for an app/team |
| routing_key | Integration key used in Events API calls |
| dedup_key | Id that ties trigger and resolve to the same alert |
| Trigger | Open/update an alert (start paging) |
| Acknowledge | Responder claims the alert; stops further escalation for now |
| Resolve | Clear the alert; stop paging |
| Escalation policy | Ordered list of who to page next if no ack |
| Events API | `POST /v2/enqueue` for machine trigger/ack/resolve |
| REST API | `api.pagerduty.com` for admin and incident management |
