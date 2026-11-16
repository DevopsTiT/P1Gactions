# Glossary

| Word | What it means |
|---|---|
| `LD` | Reads text until the next marker. It stops at 4,096 characters. It also stops at a newline. |
| `DATA` | Reads text until the next marker, and it can cross a newline. |
| `{0,16000000}` | How many characters that reader may consume. 16,000,000 is the documented ceiling. |
| 4,096 | The default stop. The API name on these lines is usually past that point. |
| Last 60 minutes | The Splunk panel window. |
| Last 24 hours | The picker used on this run. It scanned 97.78 GiB. |
