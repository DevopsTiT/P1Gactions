# Glossary

| Term | What it means | Why you care |
|---|---|---|
| RETURN_CD | Return code a job reports when it ends | 0 usually means OK; 2 here means an error |
| データ取得ジョブ | Data collection job | The job this health check watches |
| CEAA204C | Control-M server | The only host the alert reads |
| index=main | Splunk default index | Currently holds no CEAA204C data |
| Dead alert | An alert whose search can never match | Migrating it adds nothing until the data is fixed |
| `matchesValue` | DQL wildcard match, case-insensitive | Matches CEAA204C and its full domain name |
