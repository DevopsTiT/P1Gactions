# Glossary

| Term | What it means |
|---|---|
| BRE | Business Rules Engine; InnoRules is the product |
| Cron fields | minute, hour, day of month, month, day of week |
| `parse` (DQL) | Splits a log line into fields using a pattern |
| `LD` | Matcher for "any characters" up to the next pattern part |
| Routing key | PagerDuty Events v2 key that picks the service; it is a secret |
| `dedup_key` | PagerDuty groups events with the same key into one incident |
| Sensitive variable | Terraform variable hidden from plan output; value comes from CI |
