# Glossary

| Term | What it means |
|---|---|
| HTTP 201 | "Created": the request succeeded and made a new record |
| Success monitoring | Emailing when good things happen, so people see real activity |
| `lower()` | DQL function that makes text lower case, so one comparison ignores case |
| OR chain | Several conditions where any one is enough to match |
| Ingest delay | The time between a log being written and it being searchable |
| `from:now()-6m, to:now()-1m` | A 5-minute window that ends 1 minute ago to allow for ingest delay |
| `{% for %}` | Template loop in a workflow expression, used to list records in an email |
