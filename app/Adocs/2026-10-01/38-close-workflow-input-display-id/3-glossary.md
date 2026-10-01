# Glossary

| Term | What it means |
|---|---|
| display_id | The short problem number shown in Dynatrace, like P-261090. |
| event.id | The long internal problem id, used by the Problems API. |
| correlation_id | SILVA incident field holding the display id. |
| dedup_key | PagerDuty key, `dt-problem-<display id>`. |
| SAMPLE_EVENT | Fake event used only when the workflow is started with Run. |
