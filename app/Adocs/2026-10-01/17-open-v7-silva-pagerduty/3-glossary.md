# Glossary

| Term | What it means | Why you care |
|---|---|---|
| DRY_RUN | Build and log, never send | Safe test on a real problem |
| ALLOW_SAMPLE_POST | Allow the manual Run sample to create a ticket | Keep false to avoid fake tickets |
| correlation_id | Problem display ID on the incident | Prevents duplicate incidents; CLOSE finds it |
| dedup_key | PagerDuty key `dt-problem-<id>` | CLOSE resolves the same alert |
| decision | create_incident true or false with a reason | Tells you why task 4 skipped |
