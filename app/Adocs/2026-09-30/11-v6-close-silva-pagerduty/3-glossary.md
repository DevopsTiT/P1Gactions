# Glossary

| Term | What it means | Why you care |
|---|---|---|
| CLOSED / RESOLVED | Dynatrace problem states when the issue is gone | Start the CLOSE workflow |
| state 6 | SNOW stored value for Resolved | Sent in the PATCH |
| close_code | SNOW resolution code | Often mandatory when resolving |
| close_notes | Resolution text | Explains why the ticket closed |
| work_notes | Internal notes | Full detail for the support team |
| comments | Customer-visible comment | Short message |
| PATCH | HTTP method that updates part of a record | Changes only the fields sent |
| resolve event | PagerDuty event that closes an alert | Matched by dedup_key |
| Idempotent | Safe to run more than once | Repeated CLOSE runs do no harm |
