# 3 Glossary

| Term | Plain meaning | Why you care |
|------|---------------|--------------|
| PII | Data that identifies a person | Must minimize and protect |
| Grail | Dynatrace storage for logs and more | Unmasked PII here needs cleanup |
| OpenPipeline | Ingest processors before storage | Central mask/drop policy |
| OneAgent | Host/agent log collection | Can mask before data leaves the host |
| DQL | Dynatrace Query Language | Search/notebooks; query mask ≠ delete |
| DPL | Dynatrace Pattern Language | Patterns inside parse/replacePattern |
| Sensitive Data Center | Privacy scan/cleanup workflows | Find and remove stored PII |
| Mask at capture | Redact on host before send | Strong control for OneAgent paths |
| Mask at ingest | Redact in OpenPipeline | Works across many ingest channels |
| Drop record | Discard whole log line | Use when line cannot be salvaged |
