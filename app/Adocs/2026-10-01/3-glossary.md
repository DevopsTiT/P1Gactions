# Glossary

| Term | What it means |
|---|---|
| ready | The preview found every required field filled. |
| problems | List of blocking issues. Empty means nothing blocks the send. |
| duplicate_check | GET for an open SILVA incident with the same correlation_id. |
| dedup_key | PagerDuty key that groups trigger and resolve events for one problem. |
| used_sample_event | true would mean test data was used. false means real problem data. |
| DRY_RUN | When true, the send tasks build everything but do not send. |
