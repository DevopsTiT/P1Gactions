# Glossary

| Term | Plain English |
| --- | --- |
| PII | Personal data that can identify someone (name, DOB, phone, bank account) |
| Blocklist / keyword list | JSON field **names** that must not keep raw values in logs |
| Grail | Dynatrace storage where ingested logs are kept |
| OneAgent Sensitive data masking | Host-side rule that replaces matched log text before send |
| OpenPipeline | Dynatrace ingest pipeline that can drop fields or mask content |
| fieldsRemove | Pipeline step that deletes named attributes |
| Fake traffic | Test logs with dummy values only — never real customers |
| Host group | Label grouping hosts (e.g. `C_ALJ_BU_…_PRD`) for scoped settings |
| First-wave keys | High-risk personal fields; excludes product/contract metadata for now |
