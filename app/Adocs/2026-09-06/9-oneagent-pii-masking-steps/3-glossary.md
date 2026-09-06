# Glossary

| Term | Meaning |
| --- | --- |
| Sensitive data masking | OneAgent redacts log text before upload |
| Search expression | Regex that finds PII in the log line |
| Capture group | The `(.*?)` part Dynatrace treats as the value to mask |
| Matcher | Limits rule to process group / log.source / tags |
| STRING masking | Replace with fixed text such as `***` |
| SHA-256 masking | Replace with hash (same input → same hash) |
