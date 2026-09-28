# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Data map | A lookup table in the workflow code from system name to SILVA values | Changes in SILVA need only one edit. |
| System | The application the problem belongs to, such as EIP or COMPASSPROXY | It is the key of the data map. |
| L1 group | First-line support team | It handles simple triage. |
| L2 group | Second-line support team, sent by default here | It owns the fix for the application. |
| Business service | The application as SILVA knows it | It drives reporting and routing in SILVA. |
| Service offering | Environment-specific variant of a business service | It must belong to the same business service. |
| Whole-word match | The key must equal one full piece of the value after splitting on symbols | It stops EIP from matching RECEIPT. |
| Fallback | The default value used when the map has nothing | It keeps unknown systems working. |
